//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface ITrendMasterNFT{
    function setInterest (uint256) external;
    function setWhitelistMerkleTree(bytes32 _root) external;
    function setWhielistlimit(uint8 _amount) external;
    function setAuction(uint256 _startPrice, uint256 _endPrice, uint256 _priceStep, uint256 _startTime, uint256 _timeStep, uint256 _timeStepNum) external;
    function openBlindbox() external;
    function setController(address _controllerAddress) external;
    function getController() external view returns (address);

}