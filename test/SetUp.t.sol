// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SetUp.sol";
import "../src/ERC20/ITrendToken.sol";
import "../src/Governance/IProposal.sol";

contract SetUpTest is Test {
    /*
    * Token&NFT白名單：
    [
        "0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed",
        "0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d",
        "0x0555187CccE757Aa48259dF9433342B02aF16b6f"
    ]
    * Token&NFT持幣者
    [
        "0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed",
        "0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d",
        "0x0555187CccE757Aa48259dF9433342B02aF16b6f",
        "0xaB084bCF2a30B457D71bDE1894de8014619A221A",
        "0x6337c10F0DfcE4f813306f577A04c42132F7dCb2",
        "0x5E56672df2929E9EA6427186d1F8dD7c282e61C1",
        "0xD7C20d7178AA5c47C890dF272f449c902731b411",
        "0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9",
        "0x54d3b43B7c8482d44b5788C9094c319028e6ee2e",
        "0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF",
        "0x3093E7b4E269d68Db272399754c06abA62a4F97c",
        "0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5"
    ]
    * 理事會初始成員：
    [
        "0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed",
        "0xaB084bCF2a30B457D71bDE1894de8014619A221A",
        "0x6337c10F0DfcE4f813306f577A04c42132F7dCb2"
    ]
    * Merkle Root: 0x2a065c8996e5b1d0d2eb049481ca88b0a5d3d0726ccfbbddeee360ef3b2d9a9d
    * Proof:
        "0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed": ["0xd9511d4191d23da76e36c962411c0ce0a78b6ea027015b2f62547b08bd8cc670","0x18a86edcdaf4f46c46087ca54b2dd19abadfe267e062f7d6f7d4863f2b4d1543"]
        "0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d": ["0x47e7798a0359a8c1ce48528fbcd5cc6c61b7103e1ab439bc0fe4681dbd893fb5","0x18a86edcdaf4f46c46087ca54b2dd19abadfe267e062f7d6f7d4863f2b4d1543"]
        "0x0555187CccE757Aa48259dF9433342B02aF16b6f": ["0x943b0514edc0ffde1a18fd06c81a419d5e0cde9d7511f0bc06a981b60356598c"]
     */
    SetUp public setUpInstance;
    

    address[] owners = [
            0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed,
            0xaB084bCF2a30B457D71bDE1894de8014619A221A,
            0x6337c10F0DfcE4f813306f577A04c42132F7dCb2 
            ];

//["0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed","0xaB084bCF2a30B457D71bDE1894de8014619A221A","0x6337c10F0DfcE4f813306f577A04c42132F7dCb2"]

    function setUp() public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        setUpInstance = new SetUp(owners);
        vm.stopPrank();

    }

    function testContractSetUp() public{
        address treasuryContrat = setUpInstance.getTreasury();
        address trendTokenContrat = setUpInstance.getTrendToken();
        address trendMasterNFTContrat = setUpInstance.getTrendMasterNFT();
        address councilContrat = setUpInstance.getCouncil();
        address proposalContrat = setUpInstance.getProposal();

        assertFalse(treasuryContrat == address(0));
        assertFalse(trendTokenContrat == address(0));
        assertFalse(trendMasterNFTContrat == address(0));
        assertFalse(councilContrat == address(0));
        assertFalse(proposalContrat == address(0));
        
    }

    function testController() public {
        ITrendToken trendToken = ITrendToken(setUpInstance.getTrendToken());
        ITrendMasterNFT trendMasterNFT = ITrendMasterNFT(setUpInstance.getTrendMasterNFT());
        ICouncil council = ICouncil(setUpInstance.getCouncil());
        

        assertEq(trendToken.getController(), setUpInstance.getProposal());
        assertEq(trendMasterNFT.getController(),  setUpInstance.getProposal());
        assertEq(council.getController() ,setUpInstance.getProposal());
    }

    function testSetTrendTokenWhitelistNum() public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        setUpInstance.setWhitelistNum(3);
        ITrendToken trendToken = ITrendToken(setUpInstance.getTrendToken());
        assertEq(trendToken.getWhitelistNum(), 3);

        vm.stopPrank();
    }

    function testTokenDistribute()public{
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        setUpInstance.tokenDistribute();
        vm.stopPrank();

        ITrendToken trendToken = ITrendToken(setUpInstance.getTrendToken());
        assertEq(trendToken.balanceOf(setUpInstance.getTrendToken()), 470000000 );
        assertEq(trendToken.balanceOf(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed), 30000000 );
        assertEq(trendToken.balanceOf(setUpInstance.getTrendMasterNFT()), 300000000 );
        assertEq(trendToken.balanceOf(setUpInstance.getTreasury()), 200000000 );
    }



    

}
