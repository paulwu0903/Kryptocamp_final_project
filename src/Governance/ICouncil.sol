//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface ICouncil{

    function createRecall(address _recallCandidate) external;
    function createCampaign(uint256 _electedNum, uint256 _candidateNum) external;
    function setMemberNumLimit(uint256 _memberNumLimit) external;
    function setTokenNumThreshold(uint256 _tokenNumThreshold) external;
    function setPassLimit( uint256 _passThreshold) external;
    function setVoterNumThreshold(uint256 _voterNumThreshold) external;
    function setVotePowerTokenThreshold(uint256 _level1,uint256 _level2,uint256 _level3,uint256 _level4,uint256 _level5 ) external;
    
}