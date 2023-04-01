//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITrendToken{

    function balanceOf(address account) external view returns (uint256);
    function mint(uint256 _amount) external payable;
    function transfer(address to, uint256 amount) external returns (bool);
    function setInterest (uint256) external;

    
}