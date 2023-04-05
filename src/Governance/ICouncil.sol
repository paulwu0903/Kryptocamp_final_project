//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

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
    function getController() external view returns (address);
    function getCampaignPhase() external view returns(uint256 phase);
    
}