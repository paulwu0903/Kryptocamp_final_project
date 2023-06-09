//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "erc721a/contracts/IERC721A.sol";
import "erc721a/contracts/extensions/IERC721AQueryable.sol";

interface ITrendMasterNFT is IERC721AQueryable{
    //設定控制者
    function setController(address _controllerAddress) external;
    function transferBalanceToTreasury(address _treasuryAddress) external;
    function totalSupply() external view override returns (uint256);
    function getTokenURI (uint256 _tokenId) external view returns (string memory);
    function getController() external view returns (address);
    function setWhitelistMerkleTree(bytes32 _root) external;
    function setAuction(
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _priceStep,
        uint256 _startTime,
        uint256 _timeStep,
        uint256 _timeStepNum
    ) external;
    function getAuctionInfo() 
        external
        view 
        returns(uint256, uint256, uint256, uint256, uint256, uint256);
    function whitelistMint(bytes32[] calldata _proof, uint256 _quantity) external payable;
    function publicAuctionMint(uint256 _quantity)  external payable;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable override;
    function approve(address to, uint256 tokenId) external payable override;
    function getWhitelistMintPrice() external view returns(uint256);
    function balanceOf(address owner) external view override returns (uint256);
    function getAuctionPrice() external view returns(uint256);
    function openBlindbox() external;
    function openWhitelistMint() external;
    function openAuctionMint() external;


}