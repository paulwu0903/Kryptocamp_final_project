// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "../ERC721A/ITrendMasterNFT.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract RevenueRewardsSharedByNFTs is ReentrancyGuard{

    ITrendMasterNFT public trendMasterNFT;

    mapping (address => bool) isReceiveRewards;

    event GetRewards(address _account, uint256 _value);

    constructor(address _nft) payable {
        trendMasterNFT = ITrendMasterNFT(_nft);
    }

    function getRewards() external nonReentrant {
        require(trendMasterNFT.balanceOf(msg.sender) != 0, "You don't have any NFTs.");
        require(!isReceiveRewards[msg.sender], "already received!");
        uint256 rewards = (address(this).balance / trendMasterNFT.totalSupply()) * trendMasterNFT.balanceOf(msg.sender);
        isReceiveRewards[msg.sender] = true;
        payable(msg.sender).transfer(rewards);

        emit GetRewards(msg.sender, rewards);
    }

}