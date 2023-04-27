//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITrendToken is IERC20{
    function setController(address _controllerAddress) external;
    function tokenDistribute() external; 
    function publicMint(uint256 _amount) external payable;
    function transferBalanceToTreasury(address _treasuryAddress) external;
    function balanceOfAt(address account, uint256 snapshotId) external view returns (uint256);
    function snapshot() external returns(uint256 snapshotId);
    function totalSupplyAt(uint256 snapshotId) external view returns(uint256);
    function getBalance(address _account) external returns (uint256);
    function getBalanceOfAt(address _account, uint256 _snapshotId) external returns(uint256);
}