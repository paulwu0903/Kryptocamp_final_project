//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "../ERC20/ITrendToken.sol";
import "./ITreasury.sol";

contract Council{

    //競選活動狀態
    enum CampaignPhase{
        CLOSED,
        CANDIDATE_ATTENDING,
        VOTING,
        CONFIRMING
    }

     //罷免活動狀態
    enum RecallPhase{
        CLOSED,
        VOTING,
        CONFIRMING
    }

    //競選活動資訊
    struct Campaign{
        CampaignPhase campaignPhase; //競選階段
        uint256 electedNum; //本次競選限制多少人黨選
        uint256 candidateNum; //本次競選限制多少候選人
        uint256 votePowers; //本次競選共有多少投票力
        uint256 startTime; //競選開始時間
    }

    struct RecallActivity{
        RecallPhase recallPhase; //罷免階段
        address recallAddress; //罷免對象
        uint256 votePowers; //本次罷免共有多少投票力
        uint256 startTime; //罷免開始時間
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
        //競選開始到開放參選時間差距
        uint256 CampaignDurationFromCloseToAttend;
        //開放參選到投票時間差距
        uint256 CampaignDurationFromAttendToVote;
        //投票到結算時間差距
        uint256 CampaignDurationFromVoteToConfirm;
        //罷免開始到投票時間差距
        uint256 RecallDurationFromCloseToVote;
        //罷免投票到確認時間差距
        uint256 RecallDurationFromVoteToConfirm;
    }

    //vote power 門檻
    struct VotePowerTokenThreshold{
        uint256 level1;
        uint256 level2;
        uint256 level3;
        uint256 level4;
        uint256 level5;
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
    RecallActivity public recallActivity;
    VotePowerTokenThreshold public votePowerTokenThreshold;

    Rule public rule;

    //address => vote power
    mapping (address=> uint256) public votePowerMap;

    // address => 是否投票
    mapping (address => bool) public isVote;
    //voter地址
    address[] public voters;


    //判斷競選活動是否為CLOSED狀態
    modifier isCampaignClosed{
        require(campaign.campaignPhase == CampaignPhase.CLOSED, "not at CLOSED phase.");
        _;
    }

    //判斷競選活動是否為CANDIDATE_ATTENDING狀態
    modifier isCampaignCandidateAttending{
        require(campaign.campaignPhase == CampaignPhase.CANDIDATE_ATTENDING, "not at CANDIDATE_ATTENDING phase.");
        _;
    }

    //判斷競選活動是否為VOTING狀態
    modifier isCampaignVoting{
        require(campaign.campaignPhase == CampaignPhase.VOTING, "not at VOTING phase.");
        _;
    }
    //判斷競選活動是否為CONFIRMING狀態
    modifier isCampaignConfirming{
        require(campaign.campaignPhase == CampaignPhase.CONFIRMING, "not at CONFIRMING phase.");
        _;
    }

    //判斷罷免活動是否為CLOSED狀態
    modifier isRecallClosed{
        require(recallActivity.recallPhase == RecallPhase.CLOSED, "not at CLOSED phase.");
        _;
    }

    //判斷罷免活動是否為VOTING狀態
    modifier isRecallVoting{
        require(recallActivity.recallPhase == RecallPhase.VOTING, "not at VOTING phase.");
        _;
    }
    //判斷罷免活動是否為CONFIRMING狀態
    modifier isRecallConfirming{
        require(recallActivity.recallPhase == RecallPhase.CONFIRMING, "not at CONFIRMING phase.");
        _;
    }

    constructor (address _trendTokenAddress, address _treasuryAddress){
        //載入國庫合約
        trendToken = ITrendToken(_trendTokenAddress);
        treasury = ITreasury(_treasuryAddress);

        //初始化競選參數
        initCampaign();

        //初始化罷免參數
        initRecallActivity();

        //初始化理事會規範
        rule.memberNumLimit = 10;
        rule.tokenNumThreshold= 1000000 ether;
        rule.passVoteNumThreshold= 200;
        rule.votePowerThreshold= 800;

        //初始化取得vote power的token門檻
        votePowerTokenThreshold.level1 = 100 ether;
        votePowerTokenThreshold.level2 = 3000 ether;
        votePowerTokenThreshold.level3 = 10000 ether;
        votePowerTokenThreshold.level4 = 100000 ether;
        votePowerTokenThreshold.level5 = 1000000 ether;
    }

    //設定競選時間差

    //初始競選活動參數
    function initCampaign() private{
        campaign.campaignPhase = CampaignPhase.CLOSED;
        campaign.electedNum = 0;
        campaign.candidateNum = 10;
        campaign.votePowers = 0;
        campaign.startTime = type(uint256).max;

        //清除candidates
        for (uint256 i=candidates.length-1; i >=0 ; i--){
            delete candidates[i];
            candidates.pop();
        }

        //清除confirms
        for (uint256 i=confirms.length-1; i >=0 ; i--){
            delete confirms[i];
            confirms.pop();
        }
    }

    //初始罷免活斷參數
    function initRecallActivity() private {
        recallActivity.recallAddress = address(0);
        recallActivity.recallPhase = RecallPhase.CLOSED;
        recallActivity.votePowers = 0;
        recallActivity.startTime = type(uint256).max;
    }

    //設定競選相關時間
    function CampaignDuration(
        uint256 _closeToAttend,
        uint256 _attendToVote,
        uint256 _voteToConfirm
    ) internal {
        rule.CampaignDurationFromCloseToAttend = _closeToAttend;
        rule.CampaignDurationFromAttendToVote = _attendToVote;
        rule.CampaignDurationFromVoteToConfirm = _voteToConfirm;
        
    }

    //設定罷免相關時間
    function RecallDuration(
        uint256 _closeToVote,
        uint256 _voteToConfirm
    ) internal {
        rule.RecallDurationFromCloseToVote = _closeToVote;
        rule.RecallDurationFromVoteToConfirm = _voteToConfirm;
    }

    //設定理事會成員數量上限
    function setMemberNumLimit(uint256 _memberNumLimit) internal{
        rule.memberNumLimit = _memberNumLimit;
    }
    //設定參與理事會競選持幣門檻
    function setTokenNumThreshold(uint256 _tokenNumThreshold) internal{
        rule.tokenNumThreshold = _tokenNumThreshold;
    }
    //設定通過票數上限
    function setPassLimit( uint256 _passThreshold) internal {
        rule.passVoteNumThreshold = _passThreshold;
    }

    //設定選民數量門檻
    function setVoterNumThreshold(uint256 _voterNumThreshold) internal {
        rule.votePowerThreshold = _voterNumThreshold;
    }

    //設定取得vote power token門檻
    function setVotePowerTokenThreshold(
        uint256 _level1,
        uint256 _level2,
        uint256 _level3,
        uint256 _level4,
        uint256 _level5 
    ) internal {
        votePowerTokenThreshold.level1 = _level1;
        votePowerTokenThreshold.level2 = _level2;
        votePowerTokenThreshold.level3 = _level3;
        votePowerTokenThreshold.level4 = _level4;
        votePowerTokenThreshold.level5 = _level5;
    }

    //建立罷免活動
    function createRecall(address _recallCandidate) internal isRecallClosed{
        require(campaign.campaignPhase == CampaignPhase.CLOSED, "Campaign is active.");
        require(recallActivity.recallAddress != address(0), "address can not be zero-address.");
        recallActivity.recallPhase = RecallPhase.VOTING;
        recallActivity.recallAddress = _recallCandidate;
        recallActivity.votePowers = 0;
    }

    //建立競選活動，由提案合約觸發
    function createCampaign(uint256 _electedNum, uint256 _candidateNum, uint256 _startTime) internal isCampaignClosed{
        require((_electedNum + members.length) < rule.memberNumLimit, "it will over members limit.");
        require(recallActivity.recallPhase == RecallPhase.CLOSED, "Recall is active.");
        require(_startTime >= block.timestamp, "start time is over.");
        campaign.campaignPhase = CampaignPhase.CANDIDATE_ATTENDING;
        campaign.candidateNum = _candidateNum;
        campaign.electedNum= _electedNum;
        campaign.votePowers = 0;
    }

    //更改競選階段為CANDIDATE_ATTENDING
    function changeCampaignToCandidateAttending() external isCampaignClosed{
        require(campaign.startTime + rule.CampaignDurationFromCloseToAttend < block.timestamp, "not arrive candidate attending time.");
        campaign.campaignPhase = CampaignPhase.CANDIDATE_ATTENDING;
    }

    //更改競選階段為VOTING
    function changeCampaignToVoting() external isCampaignCandidateAttending{
        require(campaign.startTime + rule.CampaignDurationFromCloseToAttend + rule.CampaignDurationFromAttendToVote< block.timestamp, "not arrive voting time.");
        campaign.campaignPhase = CampaignPhase.VOTING;
    }

    //更改競選階段為CONFIRMING
    function changeCampaignToConforming() external isCampaignVoting{
        require(campaign.startTime + rule.CampaignDurationFromCloseToAttend + rule.CampaignDurationFromAttendToVote + rule.CampaignDurationFromVoteToConfirm< block.timestamp, "not arrive confirming time.");
        campaign.campaignPhase = CampaignPhase.CONFIRMING;

        //清掉投票暫存
        for (uint256 i=voters.length-1; i >= 0; i--){
            delete isVote[voters[i]];
            delete votePowerMap[voters[i]];
            delete voters[i];
            voters.pop();
        }
    }

    //更改罷免階段為VOTING
    function changeRecallToVoting() external isRecallClosed{
        require(recallActivity.startTime + rule.RecallDurationFromCloseToVote< block.timestamp, "not arrive voting time.");
        recallActivity.recallPhase = RecallPhase.VOTING;
    }

    //更改罷免階段為CONFIRMING
    function changeRecallToConforming() external isRecallVoting{
        require(recallActivity.startTime + rule.RecallDurationFromCloseToVote + rule.RecallDurationFromVoteToConfirm< block.timestamp, "not arrive confirming time.");        
        recallActivity.recallPhase = RecallPhase.CONFIRMING;

        //清掉投票暫存
        for (uint256 i=voters.length-1; i >= 0; i--){
            delete isVote[voters[i]];
            delete votePowerMap[voters[i]];
            delete voters[i];
            voters.pop();
        }
    }

    //參加競選
    function participate(string memory _name, string memory _politicalBriefing) external isCampaignCandidateAttending{
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

    //競選投票
    function campaignVote(uint8 _candidateindex, uint256 _votePower) external isCampaignVoting{
        uint256 remainVotePower = getRemainVotePower();
        require(remainVotePower != 0 , "vote power is 0.");
        require(_votePower <= remainVotePower, "vote power not enough.");
        Candidate storage candidate = candidates[_candidateindex];
        
        campaign.votePowers += _votePower;
        candidate.receivedVotePowers += _votePower;
        votePowerMap[msg.sender] -= _votePower;

        if (!isVote[msg.sender]){
            isVote[msg.sender] = true;
            voters.push(msg.sender);
        }
    }


    //罷免投票
    function recallVote(uint256 _votePower) external isRecallVoting{
        uint256 remainVotePower = getRemainVotePower();
        require(remainVotePower != 0 , "vote power is 0.");
        require(_votePower <= remainVotePower, "vote power not enough.");

        recallActivity.votePowers += _votePower;
        votePowerMap[msg.sender] -= _votePower;

        if (!isVote[msg.sender]){
            isVote[msg.sender] = true;
            voters.push(msg.sender);
        }

    }

    //取得剩餘多少票
    function getRemainVotePower() public returns(uint256){

        if (votePowerMap[msg.sender] == 0){
            uint256 balance = trendToken.balanceOf(msg.sender);
            uint256 votePower = 0;

            if (balance < votePowerTokenThreshold.level1){
                votePower = 0;
            }else if (balance >= votePowerTokenThreshold.level1 && balance < votePowerTokenThreshold.level2){
                votePower = 1;
            }else if(balance >= votePowerTokenThreshold.level2 && balance < votePowerTokenThreshold.level3 ){
                votePower = 4;
            }else if (balance >= votePowerTokenThreshold.level3 && balance < votePowerTokenThreshold.level4){
                votePower = 9;
            }else if (balance >= votePowerTokenThreshold.level4 && balance < votePowerTokenThreshold.level5){
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

    //罷免結算
    function recallConfirm() external isRecallConfirming{
        //總投票力未達標，罷免無效
        if (recallActivity.votePowers < rule.votePowerThreshold){
            initRecallActivity();
        }else{
            //從理事會中剔除，並移除國庫owner名單
            treasury.removeOwner(recallActivity.recallAddress);

            for (uint256 i =0; i < members.length; i++){
                if (members[i].memberAddress == recallActivity.recallAddress){
                    for (uint256 j = i; j < members.length - 1; i++){
                        members[i] = members[i + 1];
                    }
                    delete members[i];
                    members.pop();

                    break;
                }
            }
            initRecallActivity();
        }



    }


    //競選結算
    function campaignComfirm() external isCampaignConfirming{
        //總投票力未達標，競選無效
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
        for(uint256 i=confirms.length-1; i >=0 ; i--){
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