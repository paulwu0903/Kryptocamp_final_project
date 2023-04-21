//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITrendToken is IERC20{
    function setController(address _controllerAddress) external;
    function tokenDistribute() external; 
    function publicMint(uint256 _amount) external payable;
}