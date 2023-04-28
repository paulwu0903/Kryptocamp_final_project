//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "erc721a/contracts/IERC721A.sol";

interface ITrendMasterNFT is IERC721A{
    //設定控制者
    function setController(address _controllerAddress) external;
    function transferBalanceToTreasury(address _treasuryAddress) external;
    function totalSupply() external view override returns (uint256);
    function getTokenURI (uint256 _tokenId) external returns (string memory);
    function getController() external returns (address);
    function setWhitelistMerkleTree(bytes32 _root) external;
}