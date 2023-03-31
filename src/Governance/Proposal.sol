//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./ITreasury.sol";
import "./ICouncil.sol";
import "../ERC20/ITrendToken.sol";
import "../ERC721A/ITrendMasterNFT.sol";
import "./Council.sol";

contract Proposal is Council{

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
        ADJUST_PROPOSAL_VOTE_POWER_TOKEN_THRESHOLD, //設定罷免各階段間隔時間

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
        FINISHED
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

    ITrendMasterNFT trendMasterNFT;

    

    constructor(
        address _trendToken,
        address _trendMasterNFT,
        address _treasury
    ) Council(_trendToken, _treasury){
        //導入合約介面
        trendToken = ITrendToken(_trendToken);
        trendMasterNFT = ITrendMasterNFT(_trendMasterNFT);
        treasury = ITreasury(_treasury);

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

    //更改提案狀態至VOTING
    function changeProposalPhaseToVoting (uint256 _proposalIndex) external {
        require(proposals[_proposalIndex].startTime + proposalRule.proposalDurationFromCloseToVote < block.timestamp, "not arrive voting time.");
        proposals[_proposalIndex].proposalPhase = ProposalPhase.VOTING;
    }

    //更改提案狀態至VOTING
    function changeProposalPhaseToConfirming (uint256 _proposalIndex) external {
        require(proposals[_proposalIndex].startTime + proposalRule.proposalDurationFromCloseToVote + proposalRule.proposalDurationFromVoteToConfirm < block.timestamp, "not arrive confirming time.");
        proposals[_proposalIndex].proposalPhase = ProposalPhase.CONFIRMING;
    
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

    //提案投票
    function proposalVote(uint256 _proposalIndex) external isProposalVoting(_proposalIndex){
        uint256 votePower = getProposalVotePower();

        Template storage proposal = proposals[_proposalIndex];
        proposal.votePowers += votePower;
    }

    //提案結算並執行
    function proposalConfirm(uint256 _proposalIndex) external isProposalConfirming(_proposalIndex){
        
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
}