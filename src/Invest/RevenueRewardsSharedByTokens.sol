// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../ERC20/ITrendToken.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../Stake/ITokenStakingRewards.sol";
import "../Stake/INFTStakingRewards.sol";

contract RevenueRewardsSharedByTokens is ReentrancyGuard{

    ITrendToken public trendToken;
    ITokenStakingRewards public tokenStakingRewards;
    INFTStakingRewards public nftStakingRewards;

    uint256 public snapshotId;

    mapping (address => bool) isReceiveRewards;

    event GetRewards(address _account, uint256 _value);

    constructor(address _token, address _tokenStaking, address _nftStaking, uint256 _snapshotId) payable{
        trendToken = ITrendToken(_token);
        tokenStakingRewards = ITokenStakingRewards(_tokenStaking);
        nftStakingRewards = INFTStakingRewards(_nftStaking);
        snapshotId = _snapshotId;
    }

    function getRewards() external nonReentrant {
        require(trendToken.balanceOfAt(msg.sender, snapshotId) != 0, "You don't have any tokens.");
        require(!isReceiveRewards[msg.sender], "already received!");
        uint256 rewards = (address(this).balance / trendToken.totalSupplyAt(snapshotId) - tokenStakingRewards.getRemainTokens() - nftStakingRewards.getRemainTokens()) * (trendToken.balanceOfAt(msg.sender, snapshotId)+tokenStakingRewards.getBalanceOf(msg.sender));
        isReceiveRewards[msg.sender] = true;
        payable(msg.sender).transfer(rewards);

        emit GetRewards(msg.sender, rewards);
    }

}