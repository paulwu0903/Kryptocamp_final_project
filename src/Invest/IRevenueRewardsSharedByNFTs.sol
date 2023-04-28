// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../ERC20/ITrendToken.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../Stake/ITokenStakingRewards.sol";
import "../Stake/INFTStakingRewards.sol";

interface IRevenueRewardsSharedByNFTs{
    function getRewards() external;

}