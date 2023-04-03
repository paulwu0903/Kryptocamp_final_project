// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SetUp.sol";

contract SetUpTest is Test {
    SetUp public setUpInstance;

    address[] owners = [
            0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed,
            0xaB084bCF2a30B457D71bDE1894de8014619A221A,
            0x6337c10F0DfcE4f813306f577A04c42132F7dCb2 
            ];

//["0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed","0xaB084bCF2a30B457D71bDE1894de8014619A221A","0x6337c10F0DfcE4f813306f577A04c42132F7dCb2"]

    function setUp() public {
        setUpInstance = new SetUp(owners);
    }

    function testTreasuryContract() public view{
        address treasuryContrat = setUpInstance.getTreasury();
        console.log("treasury contract: ", treasuryContrat);
        //assertEq(counter.number(), 1);
    }

    /*function testSetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }*/
}
