//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./ITreasury.sol";
import "./ICouncil.sol";
import "../ERC20/ITrendToken.sol";
import "../ERC721A/ITrendMasterNFT.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";


contract Proposal is Ownable{

    //提案種類
    enum ProposalType{

        //Council
        ADD_COUNCIL, //競選理事會
        REMOVE_COUNCIL, //罷免理事會
        ADJUST_COUNCIL_CANDIDATE_TOKEN_NUM_THRESHOLD, //設定成為候選人的門檻
        ADJUST_COUNCIL_CAMPAIGN_VOTE_POWER_THRESHOLD,//設定最低參與投票門檻
        ADJUST_COUNCIL_MEMBER_LIMIT, //設定理事會最高人數限制
        ADJUST_COUNCIL_VOTE_POWER_TOKEN_THRESHOLD, //設定TOKEN對應Vote Power各Level的值
        ADJUST_COUNCIL_CAMPAIGN_PASS_VOTE_POWER_THRESHOLD, //設定通過競選的基本票數
        ADJUST_COUNCIL_CAMPAIGN_DURATION, //設定競選各階段間格時間
        ADJUST_COUNCIL_RECALL_DURATION, //設定罷免各階段間隔時間

        //Proposal
        ADJUST_PROPOSAL_VOTE_POWER_THRESHOLD, //設定提案最低參與投票門檻
        ADJUST_PROPOSAL_TOKEN_NUM_THRESHOLD, //設定提案人最低持幣門檻
        ADJUST_PROPOSAL_DURATION, //設定提案各階段間格時間
        ADJUST_PROPOSAL_VOTE_POWER_TOKEN_THRESHOLD, //設定提案各階段間隔時間

        //Treasury
        ADJUST_TREASURY_CONFIRM_NUM_THRESHOLD, //設定國庫交易確認門檻
        
        //NFT
        ADJUST_TREND_MASTER_DAILY_INTEREST, //調整質押Trend Master每日利息
        
        //Token
        ADJUST_TREND_TOKEN_DAILY_INTEREST //調整質押Trend Token每日利息
    }

    //提案狀態
    enum ProposalPhase{
        CLOSED,
        VOTING,
        CONFIRMING,
        EXECUTED,
        REJECTED
    }
 
    //提案規範
    struct ProposalRule{
        //提案持幣門檻
        uint256 tokenNumThreshold;
        //提案最低參與門檻
        uint256 votePowerThreshold;
        //提案關閉到投票前間差距
        uint256 proposalDurationFromCloseToVote;
        //提案投票到確認時間差距
        uint256 proposalDurationFromVoteToConfirm;
    }


    //提案樣板
    struct Template{
        ProposalType proposalType;
        ProposalPhase proposalPhase;
        address proposer;
        string title;
        string desciption;
        uint256[] paramsUint;
        address[] paramsAddress;
        uint256 votePowers;
        uint256 startTime; 
    }

    //vote power 門檻
    struct ProposalVotePowerTokenThreshold{
        uint256 level1;
        uint256 level2;
        uint256 level3;
        uint256 level4;
        uint256 level5;
    }


    Template[] public proposals;

    ProposalRule public proposalRule;

    ProposalVotePowerTokenThreshold public proposalVotePowerThreshold;

    address private controller;

    ITrendMasterNFT trendMasterNFT;
    ITrendToken trendToken;
    ITreasury treasury;
    ICouncil council;

    // index => address => bool
    mapping (uint256 => mapping (address => bool)) isProposalVote;

    constructor(
        address _trendToken,
        address _trendMasterNFT,
        address _treasury,
        address _council)
        {
        //導入合約介面
        trendToken = ITrendToken(_trendToken);
        trendMasterNFT = ITrendMasterNFT(_trendMasterNFT);
        treasury = ITreasury(_treasury);
        council = ICouncil(_council);

        //提案規範初始化
        proposalRule.tokenNumThreshold = 10000 ether;
        proposalRule.votePowerThreshold = 800;
        proposalRule.proposalDurationFromCloseToVote = 86400 seconds;
        proposalRule.proposalDurationFromVoteToConfirm = 86400 * 7 seconds;


        //初始化取得vote power的token門檻
        proposalVotePowerThreshold.level1 = 100 ether;
        proposalVotePowerThreshold.level2 = 3000 ether;
        proposalVotePowerThreshold.level3 = 10000 ether;
        proposalVotePowerThreshold.level4 = 100000 ether;
        proposalVotePowerThreshold.level5 = 1000000 ether;

    }

    //判斷提案是否為CLOSED狀態
    modifier isProposalClosed(uint256 _proposalIndex){
        require(proposals[_proposalIndex].proposalPhase == ProposalPhase.CLOSED, "not at CLOSED phase.");
        _;
    }

    //判斷提案是否為VOTING狀態
    modifier isProposalVoting(uint256 _proposalIndex){
        require(proposals[_proposalIndex].proposalPhase == ProposalPhase.CLOSED, "not at VOTING phase.");
        _;
    }
    //判斷提案是否為CONFIRMING狀態
    modifier isProposalConfirming(uint256 _proposalIndex){
        require(proposals[_proposalIndex].proposalPhase == ProposalPhase.CLOSED, "not at CONFIRMING phase.");
        _;
    }

    //判斷提案是否為FINISHED狀態
    modifier isProposalFinished(uint256 _proposalIndex){
        require(proposals[_proposalIndex].proposalPhase == ProposalPhase.CLOSED, "not at FINISHED phase.");
        _;
    }

    //提案者資金達標
    modifier isTokenEnoughToPropose{
        require(address(msg.sender).balance >= proposalRule.tokenNumThreshold);
        _;
    }

    //是否為controller
    modifier onlyController {
        require(controller == msg.sender, "not controller.");
        _;
    }

    //提案格式檢查
    modifier rightProposalFormat(
        ProposalType _proposalType,
        string memory _title,
        string memory _description,
        uint256[] memory _paramsUint,
        address[] memory _paramsAddress,
        uint256 _startTime)
    {
        //keccak256(abi.encodePacked(_str1)) == keccak256(abi.encodePacked(_str2))
        require(keccak256(abi.encodePacked(_title)) == keccak256(abi.encodePacked("")), "title is empty.");
        require(_startTime >= block.timestamp, "time is over.");

        if(_proposalType ==  ProposalType.ADD_COUNCIL ||
           _proposalType ==  ProposalType.ADJUST_COUNCIL_RECALL_DURATION ||
           _proposalType ==  ProposalType.ADJUST_PROPOSAL_DURATION
           ){
            require(_paramsUint.length == 2, "uint array just needs 2 elements.");
            require(_paramsAddress.length == 0, "address array is not necessary.");
            _;
            
        }else if (_proposalType ==  ProposalType.REMOVE_COUNCIL){
            require(_paramsUint.length == 0, "uint array is not necessary.");
            require(_paramsAddress.length == 1, "address array just needs 1 element.");
            _;
        }else if (
            _proposalType ==  ProposalType.ADJUST_COUNCIL_CANDIDATE_TOKEN_NUM_THRESHOLD ||
            _proposalType ==  ProposalType.ADJUST_COUNCIL_CAMPAIGN_VOTE_POWER_THRESHOLD ||
            _proposalType ==  ProposalType.ADJUST_COUNCIL_MEMBER_LIMIT ||
            _proposalType ==  ProposalType.ADJUST_COUNCIL_CAMPAIGN_PASS_VOTE_POWER_THRESHOLD ||
            _proposalType ==  ProposalType.ADJUST_PROPOSAL_VOTE_POWER_THRESHOLD ||
            _proposalType ==  ProposalType.ADJUST_PROPOSAL_TOKEN_NUM_THRESHOLD ||
            _proposalType ==  ProposalType.ADJUST_TREASURY_CONFIRM_NUM_THRESHOLD ||
            _proposalType ==  ProposalType.ADJUST_TREND_MASTER_DAILY_INTEREST ||
            _proposalType ==  ProposalType.ADJUST_TREND_TOKEN_DAILY_INTEREST){
            require(_paramsUint.length == 1, "uint array just needs 1 element.");
            require(_paramsAddress.length == 0, "address array is not necessary.");
            _;
        }else if (
            _proposalType ==  ProposalType.ADJUST_COUNCIL_VOTE_POWER_TOKEN_THRESHOLD ||
            _proposalType ==  ProposalType.ADJUST_PROPOSAL_VOTE_POWER_TOKEN_THRESHOLD
        ){
            require(_paramsUint.length == 1, "uint array needs 5 element.");
            require(_paramsAddress.length == 0, "address array is not necessary.");
            require(_paramsUint[0] <= _paramsUint[1], "it needs to be low to high.");
            require(_paramsUint[1] <= _paramsUint[2], "it needs to be low to high.");
            require(_paramsUint[2] <= _paramsUint[3], "it needs to be low to high.");
            require(_paramsUint[3] <= _paramsUint[4], "it needs to be low to high.");
            _;
        }else if (_proposalType ==  ProposalType.ADJUST_COUNCIL_CAMPAIGN_DURATION){
            require(_paramsUint.length == 3, "uint array needs 3 element.");
            require(_paramsAddress.length == 0, "address array is not necessary.");
            _;
        }
    
    }

    //更改提案狀態至VOTING
    function changeProposalPhaseToVoting (uint256 _proposalIndex) external onlyController{
        require(proposals[_proposalIndex].startTime + proposalRule.proposalDurationFromCloseToVote < block.timestamp, "not arrive voting time.");
        proposals[_proposalIndex].proposalPhase = ProposalPhase.VOTING;
    }

    //更改提案狀態至VOTING
    function changeProposalPhaseToConfirming (uint256 _proposalIndex) external onlyController{
        require(proposals[_proposalIndex].startTime + proposalRule.proposalDurationFromCloseToVote + proposalRule.proposalDurationFromVoteToConfirm < block.timestamp, "not arrive confirming time.");
        proposals[_proposalIndex].proposalPhase = ProposalPhase.CONFIRMING;
    
    }

    //設定controller
    function setController(address _controller) external onlyOwner{
        controller = _controller;
    } 


    //提案
    function propose(
        ProposalType _proposalType,
        string memory _title,
        string memory _description,
        uint256[] memory _paramsUint,
        address[] memory _paramsAddress,
        uint256 _startTime)
    external 
    isTokenEnoughToPropose
    rightProposalFormat(
        _proposalType,
        _title,
        _description,
        _paramsUint,
        _paramsAddress,
        _startTime
    )
    {
        proposals.push(Template(
            {
                proposalType: _proposalType,
                proposalPhase: ProposalPhase.VOTING,
                proposer: msg.sender,
                title: _title,
                desciption: _description,
                paramsUint: _paramsUint,
                paramsAddress: _paramsAddress,
                votePowers: 0,
                startTime: _startTime
            }
            )
        );
    }

    //設定取得proposal vote power token門檻
    function setProposalVotePowerTokenThreshold(
        uint256 _level1,
        uint256 _level2,
        uint256 _level3,
        uint256 _level4,
        uint256 _level5 
    ) internal {
        proposalVotePowerThreshold.level1 = _level1;
        proposalVotePowerThreshold.level2 = _level2;
        proposalVotePowerThreshold.level3 = _level3;
        proposalVotePowerThreshold.level4 = _level4;
        proposalVotePowerThreshold.level5 = _level5;
    }

    //設定最低參與投票門檻
    function setVotePowerThreshold(uint256 _votePowerThreshold) private{
        proposalRule.votePowerThreshold = _votePowerThreshold;
    }

    //提案投票
    function proposalVote(uint256 _proposalIndex) external isProposalVoting(_proposalIndex){
        require(!isProposalVote[_proposalIndex][msg.sender], "already vote.");
        uint256 votePower = getProposalVotePower();

        Template storage proposal = proposals[_proposalIndex];
        proposal.votePowers += votePower;
        isProposalVote[_proposalIndex][msg.sender] = true;
    }

    //設定最低持幣門檻
    function setTokenNumThreshold(uint256 _tokenNumThreshold) private {
        proposalRule.tokenNumThreshold = _tokenNumThreshold;
    }

    //設定提案各階段間隔時間
    function setPhaseDuration(
        uint256 _closeToVote,
        uint256 _voteToConfirm)
    private
    {
        proposalRule.proposalDurationFromCloseToVote = _closeToVote;
        proposalRule.proposalDurationFromVoteToConfirm = _voteToConfirm;
    }

    //設定Proposal Duration 
    function setProposalDuration(
        uint256 _proposalDurationFromCloseToVote,
        uint256 _proposalDurationFromVoteToConfirm
    ) private{
        proposalRule.proposalDurationFromCloseToVote = _proposalDurationFromCloseToVote;
        proposalRule.proposalDurationFromVoteToConfirm = _proposalDurationFromVoteToConfirm;
    }

    //取得Proposal投票力
    function getProposalVotePower()public view returns(uint256){
        
        uint256 balance = trendToken.balanceOf(msg.sender);
        uint256 votePower = 0;

        if (balance < proposalVotePowerThreshold.level1){
            votePower = 0;
        }else if (balance >= proposalVotePowerThreshold.level1 && balance < proposalVotePowerThreshold.level2){
            votePower = 1;
        }else if(balance >= proposalVotePowerThreshold.level2 && balance < proposalVotePowerThreshold.level3 ){
            votePower = 4;
        }else if (balance >= proposalVotePowerThreshold.level3 && balance < proposalVotePowerThreshold.level4){
            votePower = 9;
        }else if (balance >= proposalVotePowerThreshold.level4 && balance < proposalVotePowerThreshold.level5){
            votePower = 16;
        }else{
            votePower = 25;
        }

        return votePower;

    }

    //提案結算並執行
    function proposalConfirm(uint256 _proposalIndex) external isProposalConfirming(_proposalIndex){
        Template storage proposal = proposals[_proposalIndex];

        if(proposal.votePowers < proposalRule.votePowerThreshold ){
            proposal.proposalPhase = ProposalPhase.REJECTED;
        }else{
            proposal.proposalPhase = ProposalPhase.EXECUTED;
            executeProposal(proposal);
        }
    } 

    //執行提案
    function executeProposal(Template storage _proposal) private {
        //提案執行
        if(_proposal.proposalType ==  ProposalType.ADD_COUNCIL){
            council.createCampaign(_proposal.paramsUint[0], _proposal.paramsUint[1]);
        }else if (_proposal.proposalType ==  ProposalType.REMOVE_COUNCIL){
            council.createRecall(_proposal.paramsAddress[0]);
        }else if (_proposal.proposalType ==  ProposalType.ADJUST_COUNCIL_CANDIDATE_TOKEN_NUM_THRESHOLD){
            council.setTokenNumThreshold(_proposal.paramsUint[0]);
        }else if (_proposal.proposalType ==  ProposalType.ADJUST_COUNCIL_CAMPAIGN_VOTE_POWER_THRESHOLD){
            council.setVoterNumThreshold(_proposal.paramsUint[0]);
        }else if (_proposal.proposalType ==  ProposalType.ADJUST_COUNCIL_MEMBER_LIMIT){
            council.setMemberNumLimit(_proposal.paramsUint[0]);
        }else if (_proposal.proposalType ==  ProposalType.ADJUST_COUNCIL_VOTE_POWER_TOKEN_THRESHOLD){
            council.setVotePowerTokenThreshold(
                _proposal.paramsUint[0],
                _proposal.paramsUint[1],
                _proposal.paramsUint[2],
                _proposal.paramsUint[3],
                _proposal.paramsUint[4]
            );
        }else if (_proposal.proposalType ==  ProposalType.ADJUST_COUNCIL_CAMPAIGN_PASS_VOTE_POWER_THRESHOLD){
            council.setPassThreshold(_proposal.paramsUint[0]);
        }else if (_proposal.proposalType ==  ProposalType.ADJUST_COUNCIL_CAMPAIGN_DURATION){
            council.setCampaignDuration(
                _proposal.paramsUint[0],
                _proposal.paramsUint[1],
                _proposal.paramsUint[2]
            );
        }else if (_proposal.proposalType ==  ProposalType.ADJUST_COUNCIL_RECALL_DURATION){
            council.setRecallDuration(
                _proposal.paramsUint[0],
                _proposal.paramsUint[1]
            );
        }else if (_proposal.proposalType ==  ProposalType.ADJUST_PROPOSAL_VOTE_POWER_THRESHOLD){
            setVotePowerThreshold(_proposal.paramsUint[0]);
        }else if (_proposal.proposalType ==  ProposalType.ADJUST_PROPOSAL_TOKEN_NUM_THRESHOLD){
            setTokenNumThreshold(_proposal.paramsUint[0]);
        }else if (_proposal.proposalType ==  ProposalType.ADJUST_PROPOSAL_DURATION){
            setPhaseDuration(
                _proposal.paramsUint[0],
                _proposal.paramsUint[1]
                );
        }else if (_proposal.proposalType ==  ProposalType.ADJUST_PROPOSAL_VOTE_POWER_TOKEN_THRESHOLD){
            setProposalVotePowerTokenThreshold(
                _proposal.paramsUint[0],
                _proposal.paramsUint[1],
                _proposal.paramsUint[2],
                _proposal.paramsUint[3],
                _proposal.paramsUint[4]
            );
        }else if (_proposal.proposalType ==  ProposalType.ADJUST_TREASURY_CONFIRM_NUM_THRESHOLD){
            treasury.setTxRequireConfirmedNum(_proposal.paramsUint[0]);
        }else if (_proposal.proposalType ==  ProposalType.ADJUST_TREND_MASTER_DAILY_INTEREST){
            trendMasterNFT.setInterest( _proposal.paramsUint[0]);
        }else if (_proposal.proposalType ==  ProposalType.ADJUST_TREND_TOKEN_DAILY_INTEREST){
            trendToken.setInterest( _proposal.paramsUint[0]);
        }
    }    
}