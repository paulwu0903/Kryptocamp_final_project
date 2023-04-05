// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SetUp.sol";
import "../src/ERC20/ITrendToken.sol";
import "../src/Governance/IProposal.sol";

contract ProposalTest is Test {
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
    IProposal public proposal;
    ITrendToken public trendToken; 
    ICouncil public council;

    address[] public owners = [
            0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed,
            0xaB084bCF2a30B457D71bDE1894de8014619A221A,
            0x6337c10F0DfcE4f813306f577A04c42132F7dCb2 
            ];
    
    address[] public holders = [
        0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d,
        0x0555187CccE757Aa48259dF9433342B02aF16b6f,
        0xaB084bCF2a30B457D71bDE1894de8014619A221A,
        0x6337c10F0DfcE4f813306f577A04c42132F7dCb2,
        0x5E56672df2929E9EA6427186d1F8dD7c282e61C1,
        0xD7C20d7178AA5c47C890dF272f449c902731b411,
        0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9,
        0x54d3b43B7c8482d44b5788C9094c319028e6ee2e,
        0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF,
        0x3093E7b4E269d68Db272399754c06abA62a4F97c,
        0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5
    ];

    address[] public addrArr;
    uint256[] public uintArr;

    function setUp() public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        setUpInstance = new SetUp(owners);
        setUpInstance.tokenDistribute();
        vm.stopPrank();

        proposal = IProposal(setUpInstance.getProposal());
        trendToken = ITrendToken(setUpInstance.getTrendToken());
        council = ICouncil(setUpInstance.getCouncil());

    }

    function testProposeCouncilCampaign() public {
        //新增理事會提案
        proposeExample();
    }

    function testPrpopsalVoting() public {

        //新增理事會提案
        proposeExample();
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote();
        //投票
        proposalVoting();
        //項目方更改提案狀態為CONFIRMING
        changeProposalPhaseToConfirming();
        //結案
        propsalConfirming();
        //檢查是否觸發理事會選舉
        //assertEq();
        
    }
    function proposeExample() public {
        IProposal proposal = IProposal(setUpInstance.getProposal());
        uintArr.push(2);
        uintArr.push(5);

        //持有10000顆Trend Token才可投票
        vm.expectRevert("trendTokens not enough to propose.");
        vm.prank(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5);
        proposal.propose(
            0,
            "No.1 Council Campaign",
            "The first council campaign.",
            uintArr,
            addrArr,
            block.timestamp);

        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        proposal.propose(
            0,
            "No.1 Council Campaign",
            "The first council campaign.",
            uintArr,
            addrArr,
            block.timestamp);
    }

    function dealHoldersAndMintTrendToken() public {
        
        for (uint256 i=0; i < holders.length; i++){
            vm.deal(holders[i], 100 ether);
        }
        
        //購買Trend Token並投票
        vm.startPrank(0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d);
        trendToken.publicMint{value: 100 ether}(1000000);
        assertEq(trendToken.balanceOf(0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d), 1000000);
        trendToken.stakeToken(1000000);
        assertEq(trendToken.stakedBalanceOf(0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d), 1000000);
        vm.stopPrank();
        
        vm.startPrank(0x0555187CccE757Aa48259dF9433342B02aF16b6f);
        trendToken.publicMint{value: 100 ether}(1000000);
        assertEq(trendToken.balanceOf(0x0555187CccE757Aa48259dF9433342B02aF16b6f), 1000000);
        trendToken.stakeToken(1000000);
        assertEq(trendToken.stakedBalanceOf(0x0555187CccE757Aa48259dF9433342B02aF16b6f), 1000000);
        vm.stopPrank();

        vm.startPrank(0xaB084bCF2a30B457D71bDE1894de8014619A221A);
        trendToken.publicMint{value: 1 ether}(100000);
        assertEq(trendToken.balanceOf(0xaB084bCF2a30B457D71bDE1894de8014619A221A), 100000);
        trendToken.stakeToken(100000);
        assertEq(trendToken.stakedBalanceOf(0xaB084bCF2a30B457D71bDE1894de8014619A221A), 100000);
        vm.stopPrank();

        vm.startPrank(0x6337c10F0DfcE4f813306f577A04c42132F7dCb2);
        trendToken.publicMint{value: 1 ether}(5000);
        assertEq(trendToken.balanceOf(0x6337c10F0DfcE4f813306f577A04c42132F7dCb2), 5000);
        trendToken.stakeToken(5000);
        assertEq(trendToken.stakedBalanceOf(0x6337c10F0DfcE4f813306f577A04c42132F7dCb2), 5000);
        vm.stopPrank();

        vm.startPrank(0x5E56672df2929E9EA6427186d1F8dD7c282e61C1);
        trendToken.publicMint{value: 1 ether}(200);  
        assertEq(trendToken.balanceOf(0x5E56672df2929E9EA6427186d1F8dD7c282e61C1), 200);
        trendToken.stakeToken(200);   
        assertEq(trendToken.stakedBalanceOf(0x5E56672df2929E9EA6427186d1F8dD7c282e61C1), 200);
        vm.stopPrank();

        vm.startPrank(0xD7C20d7178AA5c47C890dF272f449c902731b411);
        trendToken.publicMint{value: 1 ether}(10);
        assertEq(trendToken.balanceOf(0xD7C20d7178AA5c47C890dF272f449c902731b411), 10);
        trendToken.stakeToken(10);
        assertEq(trendToken.stakedBalanceOf(0xD7C20d7178AA5c47C890dF272f449c902731b411), 10);
        vm.stopPrank();

        vm.startPrank(0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9);
        trendToken.publicMint{value: 100 ether}(1000000);
        assertEq(trendToken.balanceOf(0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9), 1000000);
        trendToken.stakeToken(1000000);
        assertEq(trendToken.stakedBalanceOf(0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9), 1000000);
        vm.stopPrank();

        vm.startPrank(0x54d3b43B7c8482d44b5788C9094c319028e6ee2e);
        trendToken.publicMint{value: 100 ether}(1000000);
        assertEq(trendToken.balanceOf(0x54d3b43B7c8482d44b5788C9094c319028e6ee2e), 1000000);
        trendToken.stakeToken(1000000);
        assertEq(trendToken.stakedBalanceOf(0x54d3b43B7c8482d44b5788C9094c319028e6ee2e), 1000000);
        vm.stopPrank();

        vm.startPrank(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF);
        trendToken.publicMint{value: 1 ether}(400);
        assertEq(trendToken.balanceOf(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF), 400);
        trendToken.stakeToken(400);
        assertEq(trendToken.stakedBalanceOf(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF), 400);
        vm.stopPrank();

        vm.startPrank(0x3093E7b4E269d68Db272399754c06abA62a4F97c);
        trendToken.publicMint{value: 1 ether}(4000);
        assertEq(trendToken.balanceOf(0x3093E7b4E269d68Db272399754c06abA62a4F97c), 4000);
        trendToken.stakeToken(4000);
        assertEq(trendToken.stakedBalanceOf(0x3093E7b4E269d68Db272399754c06abA62a4F97c), 4000);
        vm.stopPrank();

        vm.expectRevert("ETH not enough!!");
        vm.startPrank(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5);
        trendToken.publicMint{value: 1 ether}(5000000000);
    
        trendToken.publicMint{value: 1 ether}(50);
        assertEq(trendToken.balanceOf(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5), 50);
        trendToken.stakeToken(50);
        assertEq(trendToken.stakedBalanceOf(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5), 50);
        vm.stopPrank();
    }

    function changeProposalPhaseToVote() public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        vm.warp(block.timestamp + 86400 *7);
        setUpInstance.changeProposalPhaseToVoting(0);
        vm.stopPrank();
        assertEq(proposal.getProposalPhaseIndex(0), 1);
    }
    
    function proposalVoting() public {
        for(uint256 i=0; i< holders.length; i++){
            vm.startPrank(holders[i]);
            proposal.proposalVote(0);
            vm.stopPrank();
        }
    }

    function changeProposalPhaseToConfirming() public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        vm.warp(block.timestamp + 86400 *7 *2);
        setUpInstance.changeProposalPhaseTocConfirming(0);
        vm.stopPrank();

        assertEq(proposal.getProposalPhaseIndex(0), 2);
    }

    function propsalConfirming() public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        setUpInstance.proposalConfirm(0);
        vm.stopPrank();

        assertEq(proposal.getProposalPhaseIndex(0), 3);
    }

    



    

}
