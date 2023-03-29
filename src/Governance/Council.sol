//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "../ERC20/ITrendToken.sol";
import "./ITreasury.sol";

contract Council{

    //TODO：新增刪除理事會

    //競選活動狀態
    enum CampaignPhase{
        CLOSED,
        CANDIDATE_ATTENDING,
        VOTING,
        CONFIRMING
    }

    //競選活動資訊
    struct Campaign{
        CampaignPhase campaignPhase;
        uint256 electedNum;
        uint256 candidateNum;
        uint256 votePowers;
    }

    //規範
    struct Rule{
        //理事會成員數量上限
        uint256 memberNumLimit;
        //候選人門檻
        uint256 tokenNumThreshold;
        //當選門檻，參與投票人的50%贊同
        uint256 passVoteNumThreshold;
        //當選門檻，參與投票力門檻
        uint256 votePowerThreshold;
    }

    //理事會成員結構
    struct Member{
        address memberAddress;
        string name;
        string politicalBriefing;
        uint256 receivedVotePowers;
        uint256 timestamp;
    }

    //候選人結構
    struct Candidate{
        address candidateAddress;
        string name;
        string politicalBriefing;
        uint256 receivedVotePowers;
    }

    //理事會成員
    Member[] public members;

    //候選名單
    Candidate[] public candidates;

    //結算名單
    Candidate[] private confirms;
    //TrendToken interface
    ITrendToken trendToken;

    //Treasury interface
    ITreasury treasury;

    Campaign public campaign;

    Rule public rule;

    //address => vote power
    mapping (address=> uint256) votePowerMap;


    //判斷競選活動是否為CLOSED狀態
    modifier isClosed{
        require(campaign.campaignPhase == CampaignPhase.CLOSED, "not at CLOSED phase.");
        _;
    }

    //判斷競選活動是否為CANDIDATE_ATTENDING狀態
    modifier isCandidateAttending{
        require(campaign.campaignPhase == CampaignPhase.CANDIDATE_ATTENDING, "not at CANDIDATE_ATTENDING phase.");
        _;
    }

    //判斷競選活動是否為VOTING狀態
    modifier isVoting{
        require(campaign.campaignPhase == CampaignPhase.VOTING, "not at VOTING phase.");
        _;
    }
    //判斷競選活動是否為CONFIRMING狀態
    modifier isConfirming{
        require(campaign.campaignPhase == CampaignPhase.CONFIRMING, "not at CONFIRMING phase.");
        _;
    }

    constructor (address _trendTokenAddress, address _treasuryAddress){
        trendToken = ITrendToken(_trendTokenAddress);
        treasury = ITreasury(_treasuryAddress);
        initCampaign();
        rule.memberNumLimit = 10;
        rule.tokenNumThreshold= 1000000 ether;
        rule.passVoteNumThreshold= 200;
        rule.votePowerThreshold= 800;
    }

    //初始競選活動參數
    function initCampaign() private{
        campaign.campaignPhase = CampaignPhase.CLOSED;
        campaign.electedNum = 0;
        campaign.candidateNum = 10;
        campaign.votePowers = 0;
    }

    //設定理事會成員數量上限
    function setMemberNumLimit(uint256 _memberNumLimit) external{
        rule.memberNumLimit = _memberNumLimit;
    }
    //設定參與理事會競選持幣門檻
    function setTokenNumLimit(uint256 _tokenNumThreshold) external{
        rule.tokenNumThreshold = _tokenNumThreshold;
    }
    //設定通過票數上限
    function setPassLimit( uint256 _passThreshold) external {
        rule.passVoteNumThreshold = _passThreshold;
    }

    //設定選民數量門檻
    function setVoterNumThreshold(uint256 _voterNumThreshold) external {
        rule.votePowerThreshold = _voterNumThreshold;
    }

    //建立競選活動，由提案合約觸發
    function createCampaign(uint256 _electedNum, uint256 _candidateNum) external isClosed{
        require((_electedNum + members.length) < rule.memberNumLimit, "it will over members limit.");
        campaign.campaignPhase = CampaignPhase.CANDIDATE_ATTENDING;
        campaign.candidateNum = _candidateNum;
        campaign.electedNum= _electedNum;
        campaign.votePowers = 0;

    }
    //參加競選，
    function participate(string memory _name, string memory _politicalBriefing) external isCandidateAttending{
        //檢查參選者幣量是否大於規定數量
        require(trendToken.balanceOf(msg.sender) >= rule.tokenNumThreshold, "TrendToken not enough!");
        //是否超出候選人上限
        require((candidates.length +1) <= campaign.candidateNum, "Candidates arrives max number.");
        
        candidates.push( Candidate(
                {
                candidateAddress: msg.sender,
                name: _name,
                politicalBriefing: _politicalBriefing,
                receivedVotePowers: 0
                }
            )
        );
    }

    //投票
    function vote(uint8 _candidateindex, uint256 _votePower) external{
        uint256 remainVotePower = receiveRemainVotePower();
        require(remainVotePower != 0 , "vote power is 0.");
        require(_votePower <= remainVotePower, "vote power not enough.");
        Candidate storage candidate = candidates[_candidateindex];
        
        campaign.votePowers += _votePower;
        candidate.receivedVotePowers += _votePower;
        votePowerMap[msg.sender] -= _votePower;
    }

    //取得剩餘多少票
    function receiveRemainVotePower() public returns(uint256){

        if (votePowerMap[msg.sender] == 0){
            uint256 balance = trendToken.balanceOf(msg.sender);
            uint256 votePower = 0;

            if (balance < 100 ether){
                votePower = 0;
            }else if (balance >= 100 ether && balance < 3000 ether){
                votePower = 1;
            }else if(balance >= 3000 ether && balance < 10000 ether ){
                votePower = 4;
            }else if (balance >= 10000 ether && balance < 100000 ether){
                votePower = 9;
            }else if (balance >= 100000 ether && balance < 1000000 ether){
                votePower = 16;
            }else{
                votePower = 25;
            }

            votePowerMap[msg.sender] = votePower;

            return votePower;

        }else{
            return votePowerMap[msg.sender];
        }   
    }

    //結算
    function comfirm() external isConfirming{

        if (campaign.votePowers < rule.votePowerThreshold){
            initCampaign();
        }

        // copy candidates to confirms 
       copyCandidatesToConfirms(candidates);
        //按照得票由大到小排序candidates
        sortConfirms();

        //留下本次競選所需的當選量
        for (uint256 i= confirms.length-1; i >= campaign.electedNum; i--){
            delete confirms[i];
            confirms.pop();
        }
        
        //留下票數門檻達標的候選人
        for(uint256 i=confirms.length-1; i <=0 ; i--){
            if (confirms[i].receivedVotePowers < rule.passVoteNumThreshold){
                delete confirms[i];
                confirms.pop();
            }
        }
        //若confirms中不為空，則設定成為國庫owner
        if (confirms.length >0){
            for(uint256 i=0; i < confirms.length; i++){
                treasury.addOwner(confirms[i].candidateAddress);
                members.push(Member({
                    memberAddress: confirms[i].candidateAddress,
                    name: confirms[i].name,
                    politicalBriefing: confirms[i].politicalBriefing,
                    receivedVotePowers:  confirms[i].receivedVotePowers,
                    timestamp: block.timestamp
                }));
            }
        }
        initCampaign();
    }

    //由小到大排序 confirms
    function sortConfirms() private {

	    for(uint256 i=confirms.length-1; i> 0; i--){
		    for(uint256 j= confirms.length-1; j< confirms.length-1-i; j--){
			    if (confirms[j].receivedVotePowers > confirms[j-1].receivedVotePowers){
				    Candidate memory confirmTmp = candidates[j];
				    confirms[j] = confirms[j-1];
				    confirms[j-1] = confirmTmp;
			    }
		    }
	    }
    }   
    // copy candidates到comfirms
    //TODO:確認這種複製方式，會不會影響candidates
    function copyCandidatesToConfirms(Candidate[] storage _candidates) private{
        confirms = _candidates;
    } 

}