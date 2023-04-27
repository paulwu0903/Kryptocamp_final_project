//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ICouncil{

    function createRecall(address _recallCandidate) external;
    function createCampaign(uint256 _electedNum, uint256 _candidateNum) external;
    function setMemberNumLimit(uint256 _memberNumLimit) external;
    function setTokenNumThreshold(uint256 _tokenNumThreshold) external;
    function setPassThreshold( uint256 _passThreshold) external;
    function setVoterNumThreshold(uint256 _voterNumThreshold) external;
    function setVotePowerTokenThreshold(uint256 _level1,uint256 _level2,uint256 _level3,uint256 _level4,uint256 _level5 ) external;
    function changeCampaignToCandidateAttending() external;
    function changeCampaignToVoting() external;
    function changeCampaignToConforming() external;
    function changeRecallToVoting() external;
    function changeRecallToConfirming() external;
    function setCampaignDuration(uint256 _closeToAttend, uint256 _attendToVote, uint256 _voteToConfirm) external;
    function setRecallDuration(uint256 _closeToVote, uint256 _voteToConfirm) external;
    function getController() external returns (address);
    function getCampaignPhase() external returns(uint256 phase);
    function getCampaignStartTime() external returns(uint256 time);
    function participate(string memory _name, string memory _politicalBriefing) external;
    function getCandidateNum() external returns(uint256);
    function getRemainVotePower(address _addr) external returns(uint256);
    function campaignVote(uint8 _candidateindex, uint256 _votePower) external;
    function getVotersNum() external returns(uint256);
    function campaignConfirm() external;
    function getRecallPhase() external returns(uint256 phase);
    function recallVote(uint256 _votePower) external;
    function recallConfirm() external;
    function getMembersNum() external returns (uint256);
    function getTokenNumThreshold() external returns(uint256);
    function getVotePowerThreshold() external returns (uint256);
    function getCouncilMemberNumLimit() external returns(uint256);
    function getLevelOfVotePower(uint256 _index) external returns(uint256);
    function getVotePassThreshold() external returns(uint256);
    
}