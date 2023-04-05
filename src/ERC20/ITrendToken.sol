//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITrendToken{

    function balanceOf(address account) external view returns (uint256);
    function mint(uint256 _amount) external payable;
    function transfer(address to, uint256 amount) external returns (bool);
    function setInterest (uint256) external;
    function setWhitelistMerkleTree(bytes32 _root) external;
    function setWhitelistNum(uint256 _whitelistNum) external;
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function getController() external view returns (address);
    function getWhitelistNum() external view returns (uint256);
    function tokenDistribute() external;
    function stakedBalanceOf(address _addr) external view returns(uint256);
    function publicMint(uint256 _amount) external payable;
    function stakeToken(uint256 _stakeAmount) external;

    //給前端定期呼叫（天）
    function updateTotalStakedTokenHistory() external;


    
}