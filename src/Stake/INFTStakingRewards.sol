// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;



interface INFTStakingRewards{

    function lastTimeRewardApplicable() external view returns (uint);
    function rewardPerToken() external view returns (uint);

    function stake(uint _tokenId) external;

    function withdraw(uint _tokenId) external;

    function earned(address _account) external view returns (uint);

    function getReward() external;

    function setRewardsDuration(uint _duration) external;

    function notifyRewardAmount(uint _amount) external;

    function getBalanceOf(address _addr) external view returns (uint256);

    

}
