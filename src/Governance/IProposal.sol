//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IProposal{

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

    function changeProposalPhaseToVoting (uint256 _proposalIndex) external;
    function changeProposalPhaseToConfirming (uint256 _proposalIndex) external;
    function getController() external view returns (address);
    function propose(uint256 _typeIndex, string memory _title, string memory _description, uint256[] memory _paramsUint, address[] memory _paramsAddress, uint256 _startTime) external;
    function proposalVote(uint256 _proposalIndex) external;
    function getProposalPhaseIndex(uint256 _index) external view returns (uint256 phase);
    function proposalConfirm(uint256 _proposalIndex) external;
    function getProposalVotePower(uint256 _proposalIndex) external view returns(uint256);
    function getProposalVotePowerOfUser()external view returns(uint256);
    
    
}