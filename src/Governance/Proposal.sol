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
        ADJUST_VOTE_POWER_TOKEN_THRESHOLD, //設定TOKEN對應Vote Power各Level的值
        ADJUST_COUNCIL_CAMPAIGN_PASS_VOTE_POWER_THRESHOLD, //設定通過競選的基本票數
        ADJUST_COUNCIL_CAMPAIGN_DURATION, //設定競選各階段間格時間
        ADJUST_COUNCIL_RECALL_DURATION, //設定罷免各階段間隔時間

        //Proposal
        ADJUST_PROPOSAL_VOTE_POWER_THRESHOLD, //設定提案最低參與投票門檻
        ADJUST_PROPOSAL_TOKEN_NUM_THRESHOLD, //設定提案人最低持幣門檻

        //Treasury
        ADJUST_TREASURY_CONFIRM_NUM_THRESHOLD, //設定國庫交易確認門檻
        
        //NFT
        ADJUST_TREND_MASTER_DAILY_INTEREST, //調整質押Trend Master每日利息
        
        //Token
        ADJUST_TREND_TOKEN_DAILY_INTEREST //調整質押Trend Token每日利息
    }

    //提案狀態
    enum ProposalState{
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
    }


    //提案樣板
    struct Template{
        ProposalType proposalType;
        ProposalState proposalState;
        address proposer;
        string title;
        string desciption;
        uint256[] paramsUint;
        address[] paramsAddress;
        uint256 votePowers; 
    }

    Template[] public proposals;

    ProposalRule public proposalRule;

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

        //提案持幣門檻初始化
        proposalRule.tokenNumThreshold = 10000 ether;
        //通過提案門檻初始化
        proposalRule.votePowerThreshold = 800;

    }

    //判斷提案是否為CLOSED狀態
    modifier isProposalClosed(uint256 _proposalIndex){
        require(proposals[_proposalIndex].proposalState == ProposalState.CLOSED, "not at CLOSED phase.");
        _;
    }

    //判斷提案是否為VOTING狀態
    modifier isProposalVoting(uint256 _proposalIndex){
        require(proposals[_proposalIndex].proposalState == ProposalState.CLOSED, "not at VOTING phase.");
        _;
    }
    //判斷提案是否為CONFIRMING狀態
    modifier isProposalConfirming(uint256 _proposalIndex){
        require(proposals[_proposalIndex].proposalState == ProposalState.CLOSED, "not at CONFIRMING phase.");
        _;
    }

    //判斷提案是否為FINISHED狀態
    modifier isProposalFinished(uint256 _proposalIndex){
        require(proposals[_proposalIndex].proposalState == ProposalState.CLOSED, "not at FINISHED phase.");
        _;
    }

    //提案者資金達標
    modifier isTokenEnoughToPropose{
        require(address(msg.sender).balance >= proposalRule.tokenNumThreshold);
        _;
    }

    //提案
    function propose(
        ProposalType _proposalType,
        string memory _title,
        string memory _description,
        uint256[] memory _paramsUint,
        address[] memory _paramsAddress)
    external 
    isTokenEnoughToPropose
    {
        proposals.push(Template(
            {
                proposalType: _proposalType,
                proposalState: ProposalState.VOTING,
                proposer: msg.sender,
                title: _title,
                desciption: _description,
                paramsUint: _paramsUint,
                paramsAddress: _paramsAddress,
                votePowers: 0
            }
            )
        );
    }

    //投票
    

    
     



    
}