// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Script.sol";


interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}


contract SetUpScript is Script {
    function setUp() public {
        vm.createSelectFork("https://mainnet.infura.io/v3/172630547a8948448da3e3df4a5ef574");
        
    }

    function run() public {
        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        
    }


}