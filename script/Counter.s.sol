// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";

contract CounterScript is Script {
    function setUp() public {
        vm.createSelectFork("https://mainnet.infura.io/v3/172630547a8948448da3e3df4a5ef574");
    }

    function run() public {
        console.log(address(0x1).balance);
    }
}