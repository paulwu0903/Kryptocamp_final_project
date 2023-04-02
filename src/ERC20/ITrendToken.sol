//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITrendToken{

    function balanceOf(address account) external view returns (uint256);
    function mint(uint256 _amount) external payable;
    function transfer(address to, uint256 amount) external returns (bool);
    function setInterest (uint256) external;
    function sendAirdrop() external;
    function setWhitelistMerkleTree(bytes32 _root) external;
    function setWhitelistNum(uint256 _whitelistNum) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    //給前端定期呼叫（天）
    function updateTotalStakedTokenHistory() external;


    
}