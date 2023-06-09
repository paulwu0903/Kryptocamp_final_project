//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../Stake/ITokenStakingRewards.sol";
import "./ITreasury.sol";
import "./IMasterTreasury.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Council is Ownable{

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
        uint256 campaignDurationFromCloseToAttend;
        //開放參選到投票時間差距
        uint256 campaignDurationFromAttendToVote;
        //投票到結算時間差距
        uint256 campaignDurationFromVoteToConfirm;
        //罷免開始到投票時間差距
        uint256 recallDurationFromCloseToVote;
        //罷免投票到確認時間差距
        uint256 recallDurationFromVoteToConfirm;
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

    //是否為理事會map
    mapping (address => bool) public isMemberMap;

    //候選名單
    Candidate[] public candidates;

    //結算名單
    Candidate[] private confirms;
    

    //Treasury interface
    ITreasury treasury;
    ITokenStakingRewards tokenStakingRewards;
    IMasterTreasury masterTreasury;

    //控制合約
    address private controller;



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

    event ActivityInfo(uint256 _activity);
    event VotePassThreshold(uint256 _threshold);
    event LevelOfVotePower(uint256 _level, uint256 _threshold);
    event MemberNumLimit(uint256 _limit);
    event VotePowerThreshold(uint256 _threshold);
    event TokenNumThreshold(uint256 _threshold);
    event MemberNum(uint256 _amount);
    event VoterNum(uint256 _voterNum);
    event CandidateNum(uint256 _candidateNum);
    event CampaignStartTime(uint256 _startTime);
    event RecallCurrentPhase(uint256 _phase);
    event CampaignCurrentPhase(uint256 _phase);
    event Controller (address _controllerAddress);
    event CampaignConfirm(bool _success);
    event CampaignSuccessResult(bool _success, Candidate[] newMembers);
    event CandidateInfo(Candidate[] _candidates);
    event RecallConfirm(bool _success);
    event RecallSuccessResult(bool _success, address _recaller);
    event RemainVotePower(uint256 _votePower);
    event RecallVote(address _account, uint256 _votePower);
    event CampaignVote(address _account, uint256 _votePower );
    event Participate(address _candidate, string _name, string _politicalBriefing);
    event CreateCampaign(uint256 _electedNum, uint256 _cadiddateNum);
    event CreateRecall(address recaller);




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

    //是否為controller
    modifier onlyController {
        require(controller == msg.sender, "not controller.");
        _;
    }
    //是否已為理事會成員
    modifier notCouncilMember{
        require(!isMemberMap[msg.sender], "already in council.");
        _;
    }

    constructor (address _tokenStakingRewards, address _treasuryAddress, address _masterTreasuryAddress){
        //載入國庫合約
        treasury = ITreasury(_treasuryAddress);
        masterTreasury = IMasterTreasury(_masterTreasuryAddress);

        //載入質押合約
        tokenStakingRewards = ITokenStakingRewards(_tokenStakingRewards);

        //初始化競選參數
        initCampaign();

        //初始化罷免參數
        initRecallActivity();

        //初始化理事會規範
        rule.memberNumLimit = 10;
        rule.tokenNumThreshold= 10000 ether;
        rule.passVoteNumThreshold= 10 ; 
        rule.votePowerThreshold= 20 ; 
        rule.campaignDurationFromCloseToAttend = 86400 seconds;
        rule.campaignDurationFromAttendToVote = 86400 * 7 seconds;
        rule.campaignDurationFromVoteToConfirm = 86400 * 7 seconds;
        rule.recallDurationFromCloseToVote = 86400 seconds;
        rule.recallDurationFromVoteToConfirm = 86400 * 7 seconds;

        //初始化取得vote power的token門檻
        votePowerTokenThreshold.level1 = 100 ether;
        votePowerTokenThreshold.level2 = 3000 ether;
        votePowerTokenThreshold.level3 = 10000 ether;
        votePowerTokenThreshold.level4 = 100000 ether;
        votePowerTokenThreshold.level5 = 1000000 ether;

        //新增項目方至理事會
        address[] memory treasuryOwners = treasury.getOwner();
        for(uint256 i=0; i< treasuryOwners.length; i++){
            members.push(
                Member({
                    memberAddress: treasuryOwners[i],
                    name: "admin",
                    politicalBriefing: "",
                    receivedVotePowers: 0,
                    timestamp: block.timestamp
                })
            );
            isMemberMap[ treasuryOwners[i]] = true;
        }
        
    }

    //設定控制者
    function setController(address _controllerAddress) external onlyOwner{
        controller = _controllerAddress;
    } 

    //初始競選活動參數
    function initCampaign() private{
        campaign.campaignPhase = CampaignPhase.CLOSED;
        campaign.electedNum = 0;
        campaign.candidateNum = 10;
        campaign.votePowers = 0;
        campaign.startTime = 0;

        //清除candidates
        if (candidates.length > 0){   
            uint256 i = candidates.length-1;
            while(i >= 0){
                delete candidates[i];
                candidates.pop();
                if (i==0){
                    break;
                }
                i--;
            }
        }
        //清除confirms
        if (confirms.length > 0){
            uint256 i = confirms.length-1;
            while(i >= 0){
                delete confirms[i];
                confirms.pop();
                if (i==0){
                    break;
                }
                i--;
            }
        }
    }

    //初始罷免活斷參數
    function initRecallActivity() private {
        recallActivity.recallAddress = address(0);
        recallActivity.recallPhase = RecallPhase.CLOSED;
        recallActivity.votePowers = 0;
        recallActivity.startTime = 0;
    }

    //設定競選相關時間
    function setCampaignDuration(
        uint256 _closeToAttend,
        uint256 _attendToVote,
        uint256 _voteToConfirm) 
    external
    onlyController 
     {
        rule.campaignDurationFromCloseToAttend = _closeToAttend;
        rule.campaignDurationFromAttendToVote = _attendToVote;
        rule.campaignDurationFromVoteToConfirm = _voteToConfirm;
    }

    //設定罷免相關時間
    function setRecallDuration(
        uint256 _closeToVote,
        uint256 _voteToConfirm) 
    external 
    onlyController
        {
        rule.recallDurationFromCloseToVote = _closeToVote;
        rule.recallDurationFromVoteToConfirm = _voteToConfirm;
    }

    //設定理事會成員數量上限
    function setMemberNumLimit(uint256 _memberNumLimit) external onlyController{
        rule.memberNumLimit = _memberNumLimit;
    }
    //設定參與理事會競選持幣門檻
    function setTokenNumThreshold(uint256 _tokenNumThreshold) external onlyController{
        rule.tokenNumThreshold = _tokenNumThreshold;
    }
    //設定通過票數上限
    function setPassThreshold(uint256 _passThreshold) external onlyController {
        rule.passVoteNumThreshold = _passThreshold;
    }

    //設定選民數量門檻
    function setVoterNumThreshold(uint256 _voterNumThreshold) external onlyController {
        rule.votePowerThreshold = _voterNumThreshold;
    }

    //設定取得vote power token門檻
    function setVotePowerTokenThreshold(
        uint256 _level1,
        uint256 _level2,
        uint256 _level3,
        uint256 _level4,
        uint256 _level5 ) 
    external 
    onlyController
    {
        votePowerTokenThreshold.level1 = _level1;
        votePowerTokenThreshold.level2 = _level2;
        votePowerTokenThreshold.level3 = _level3;
        votePowerTokenThreshold.level4 = _level4;
        votePowerTokenThreshold.level5 = _level5;

    }

    //建立罷免活動
    function createRecall(address _recallCandidate) external onlyController isRecallClosed{
        require(campaign.campaignPhase == CampaignPhase.CLOSED, "Campaign is active.");
        require(_recallCandidate != address(0), "address can not be zero-address.");
        //recallActivity.recallPhase = RecallPhase.VOTING;
        recallActivity.startTime = block.timestamp;
        recallActivity.recallAddress = _recallCandidate;
        recallActivity.votePowers = 0;

        emit CreateRecall(_recallCandidate);
    }

    //建立競選活動，由提案合約觸發
    function createCampaign(uint256 _electedNum, uint256 _candidateNum) external onlyController isCampaignClosed{
        require((_electedNum + members.length) < rule.memberNumLimit, "it will over members limit.");
        require(recallActivity.recallPhase == RecallPhase.CLOSED, "Recall is active.");
        
        campaign.campaignPhase = CampaignPhase.CANDIDATE_ATTENDING;
        campaign.candidateNum = _candidateNum;
        campaign.electedNum= _electedNum;
        campaign.votePowers = 0;
        campaign.startTime = block.timestamp;

        emit CreateCampaign(_electedNum, _candidateNum);
    }

    //更改競選階段為CANDIDATE_ATTENDING
    function changeCampaignToCandidateAttending() external onlyOwner isCampaignClosed{
        require(campaign.startTime + rule.campaignDurationFromCloseToAttend < block.timestamp, "not arrive candidate attending time.");
        campaign.campaignPhase = CampaignPhase.CANDIDATE_ATTENDING;
    }

    //更改競選階段為VOTING
    function changeCampaignToVoting() external onlyOwner isCampaignCandidateAttending{
        require(campaign.startTime + rule.campaignDurationFromCloseToAttend + rule.campaignDurationFromAttendToVote< block.timestamp, "not arrive voting time.");
        campaign.campaignPhase = CampaignPhase.VOTING;
    }

    //更改競選階段為CONFIRMING
    function changeCampaignToConforming() external onlyOwner isCampaignVoting{
        require(campaign.startTime + rule.campaignDurationFromCloseToAttend + rule.campaignDurationFromAttendToVote + rule.campaignDurationFromVoteToConfirm< block.timestamp, "not arrive confirming time.");
        campaign.campaignPhase = CampaignPhase.CONFIRMING;

        //清掉投票暫存
        //TODO: 待優化
        uint256 i = voters.length-1;
        while(i <= voters.length-1){
            delete isVote[voters[i]];
            delete votePowerMap[voters[i]];
            delete voters[i];
            voters.pop();
            if (i == 0) {
                break;
            }
            i--;
        }
    }

    //更改罷免階段為VOTING
    function changeRecallToVoting() external onlyOwner isRecallClosed{
        require(recallActivity.startTime + rule.recallDurationFromCloseToVote< block.timestamp, "not arrive voting time.");
        recallActivity.recallPhase = RecallPhase.VOTING;
    }

    //更改罷免階段為CONFIRMING
    function changeRecallToConfirming() external onlyOwner isRecallVoting{
        require(recallActivity.startTime + rule.recallDurationFromCloseToVote + rule.recallDurationFromVoteToConfirm< block.timestamp, "not arrive confirming time.");        
        recallActivity.recallPhase = RecallPhase.CONFIRMING;

        //清掉投票暫存
        //TODO: 待優化
        uint256 i = voters.length-1;
        while(i <= voters.length-1){
            delete isVote[voters[i]];
            delete votePowerMap[voters[i]];
            delete voters[i];
            voters.pop();
            if (i == 0) {
                break;
            }
            i--;
        }
    }

    //參加競選
    function participate(string memory _name, string memory _politicalBriefing) external isCampaignCandidateAttending notCouncilMember{
        //檢查參選者幣量是否大於規定數量
        require(tokenStakingRewards.getBalanceOf(msg.sender) >= rule.tokenNumThreshold, "TrendToken not enough!");
        //是否超出候選人上限
        require((candidates.length +1) <= campaign.candidateNum, "Candidates arrives max number.");
        //是否已為理事會
        
        candidates.push( Candidate(
                {
                candidateAddress: msg.sender,
                name: _name,
                politicalBriefing: _politicalBriefing,
                receivedVotePowers: 0
                }
            )
        );
        emit Participate(msg.sender, _name, _politicalBriefing);
    }

    //競選投票
    function campaignVote(uint8 _candidateindex, uint256 _votePower) external isCampaignVoting{
        uint256 remainVotePower = getRemainVotePower(msg.sender);
        require((_votePower <= remainVotePower) && (remainVotePower != 0) , "vote power not enough.");
        Candidate storage candidate = candidates[_candidateindex];
        
        campaign.votePowers += _votePower;
        candidate.receivedVotePowers += _votePower;
        votePowerMap[msg.sender] -= _votePower;

        if (!isVote[msg.sender]){
            isVote[msg.sender] = true;
            voters.push(msg.sender);
        }
        emit CampaignVote(msg.sender, _votePower);
    }


    //罷免投票
    function recallVote(uint256 _votePower) external isRecallVoting{
        uint256 remainVotePower = getRemainVotePower(msg.sender);
        require((_votePower <= remainVotePower) && (remainVotePower != 0) , "vote power not enough.");

        recallActivity.votePowers += _votePower;
        votePowerMap[msg.sender] -= _votePower;

        if (!isVote[msg.sender]){
            isVote[msg.sender] = true;
            voters.push(msg.sender);
        }

        emit RecallVote(msg.sender, _votePower);

    }

    //取得剩餘多少票
    function getRemainVotePower(address _addr) public returns(uint256){
        uint256 votePower = 0;
        if (votePowerMap[_addr] == 0){
            uint256 balance = tokenStakingRewards.getBalanceOf(_addr);
            

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

            votePowerMap[_addr] = votePower;
        
        }else{
            votePower = votePowerMap[_addr];
            
        }   

        emit RemainVotePower(votePower);

        return votePower;
    }

    //罷免結算
    function recallConfirm() external isRecallConfirming{
        //總投票力未達標，罷免無效
        if (recallActivity.votePowers < rule.votePowerThreshold){
            initRecallActivity();
            emit RecallConfirm(false);
        }else{
            //從理事會中剔除，並移除國庫owner名單
            treasury.removeOwner(recallActivity.recallAddress);
            masterTreasury.removeOwner(recallActivity.recallAddress);

            emit RecallSuccessResult(true, recallActivity.recallAddress);

            //TODO: 待優化
            for (uint256 i =0; i < members.length; i++){
                if (members[i].memberAddress == recallActivity.recallAddress){
                    delete members[i];
                    isMemberMap[recallActivity.recallAddress] = false;
                    for (uint256 j = i; j < members.length - 1; j++){
                        members[j] = members[j + 1];
                    }
                    members.pop();
                    break;
                }
            }
            
            initRecallActivity();
        }
    }


    //競選結算
    function campaignConfirm() external onlyOwner isCampaignConfirming{
        //總投票力未達標，競選無效
        if (campaign.votePowers < rule.votePowerThreshold){
            initCampaign();
            emit CampaignConfirm(false);
        }

        // copy candidates to confirms 
        copyCandidatesToConfirms(candidates);
        //按照得票由大到小排序candidates
        sortConfirms();

        //留下本次競選所需的當選量
        uint256 i = confirms.length-1;
        while(i >= 0){
            delete confirms[i];
            confirms.pop();
            if (i==campaign.electedNum){
                break;
            }
            i--;
        }
        
        //留下票數門檻達標的候選人
        i = confirms.length-1;
        while(i >= 0){
            if (confirms[i].receivedVotePowers < rule.passVoteNumThreshold){
                delete confirms[i];
                confirms.pop();
            }
            if (i==0){
                break;
            }
            i--;
        }
        
        //若confirms中不為空，則設定成為國庫owner
        if (confirms.length >0){
            for(uint256 j=0; j < confirms.length; j++){
                isMemberMap[confirms[j].candidateAddress] = true;
                treasury.addOwner(confirms[j].candidateAddress);
                masterTreasury.addOwner(confirms[j].candidateAddress);
                members.push(Member({
                    memberAddress: confirms[j].candidateAddress,
                    name: confirms[j].name,
                    politicalBriefing: confirms[j].politicalBriefing,
                    receivedVotePowers:  confirms[j].receivedVotePowers,
                    timestamp: block.timestamp
                }));
            }
            emit CampaignSuccessResult(true, confirms);
        }else{
            emit CampaignConfirm(false);
        }
        initCampaign();
        
    }

    //由小到大排序 confirms
    function sortConfirms() private {
        uint256 i=confirms.length-1;

        while(i >= 0){
            for(uint256 j= confirms.length-1; j< confirms.length-1-i; j--){
                if (confirms[j].receivedVotePowers > confirms[j-1].receivedVotePowers){
				    Candidate memory confirmTmp = candidates[j];
				    confirms[j] = confirms[j-1];
				    confirms[j-1] = confirmTmp;
			    }
                if(j ==0){
                    break;
                }
            }
            if (i == 1 ){
                break;
            }
            i--;
        }
    }   
    // copy candidates到comfirms
    //TODO:確認這種複製方式，會不會影響candidates
    function copyCandidatesToConfirms(Candidate[] storage _candidates) private{
        confirms = _candidates;
    } 

    function getController() external view returns (address){
        return controller;
    }

    function getCampaignPhase() external view returns(uint256){
        uint256 phase = 0;
        if (campaign.campaignPhase == CampaignPhase.CLOSED){
            phase = 0;
        }else if (campaign.campaignPhase == CampaignPhase.CANDIDATE_ATTENDING){
            phase = 1;
        }else if (campaign.campaignPhase == CampaignPhase.VOTING){
            phase = 2;
        }else if (campaign.campaignPhase == CampaignPhase.CONFIRMING){
            phase = 3;
        }
        return phase;
    }

    function getRecallPhase() external view returns(uint256){
        uint256 phase = 0;
        if (recallActivity.recallPhase == RecallPhase.CLOSED){
            phase = 0;
        }else if (recallActivity.recallPhase == RecallPhase.VOTING){
            phase = 1;
        }else if (recallActivity.recallPhase == RecallPhase.CONFIRMING){
            phase = 2;
        }
        return phase;
    }

    function getCampaignStartTime() external view returns(uint256 time){
        uint256 startTime = campaign.startTime;
        return startTime;
    }

    function getCandidateNum() external view returns(uint256){
        uint256 candidateNum = candidates.length;
        return candidateNum;
    }

    function getVotersNum() external view returns(uint256){
        uint256 voterNum = voters.length;
        return voterNum;
    }

    function getMembersNum() external view returns (uint256){
        uint256 amount = members.length;
        return amount;
    }
    //取得參與理事會競選持幣門檻
    function getTokenNumThreshold() external view returns(uint256){
        uint256 threshold = rule.tokenNumThreshold;
        return threshold;
    }
    //取得參與投票力門檻
    function getVotePowerThreshold() external view returns (uint256){
        uint256 threshold = rule.votePowerThreshold;
        return threshold;
    }

    //取得理事會上限人數
    function getCouncilMemberNumLimit() external view returns(uint256){
        uint256 limit = rule.memberNumLimit;
        return limit;
    }

    //取得vote power規範所需質押之幣量
    function getLevelOfVotePower(uint256 _index) external view returns(uint256){
        uint256 res = 0;
        if (_index == 0){
            res = votePowerTokenThreshold.level1;
        }else if (_index == 1){
            res = votePowerTokenThreshold.level2;
        }else if (_index == 2){
            res = votePowerTokenThreshold.level3;
        }else if (_index == 3){
            res = votePowerTokenThreshold.level4;
        }else if (_index == 4 ){
            res = votePowerTokenThreshold.level5;
        }
        return res;
    }

    function getVotePassThreshold() external view returns(uint256){
        uint256 threshold = rule.passVoteNumThreshold;
        return threshold;
    }

    function getCurrentActiviry() external view returns(uint256){
        uint256 activity = 0;
        if (campaign.campaignPhase != CampaignPhase.CLOSED){
            activity = 1;
        }else if (recallActivity.recallPhase != RecallPhase.CLOSED){
            activity = 2;
        }
        return activity;
    }

    //取得候選人資訊 
    function getCandidate() external view returns(Candidate[] memory){
        return candidates;
    }

    function setTokenStakingRewardsAddress(address _tokenStakingRewardsAddress) external onlyOwner {
        tokenStakingRewards = ITokenStakingRewards(_tokenStakingRewardsAddress);
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        treasury = ITreasury(_treasuryAddress);
    }

    function setMasterTreasuryAddress(address _masterTreasuryAddress) external onlyOwner {
        masterTreasury = IMasterTreasury(_masterTreasuryAddress);
    }


}