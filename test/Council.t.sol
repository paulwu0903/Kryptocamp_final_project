// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/SetUp.sol";
import "../src/ERC20/ITrendToken.sol";
import "../src/Governance/IProposal.sol";
import "../src/Governance/ITreasury.sol";

contract CouncilTest is Test {

     SetUp public setUpInstance;
    IProposal public proposal;
    ITrendToken public trendToken; 
    ICouncil public council;
    ITreasury public treasury;

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
        treasury = ITreasury(setUpInstance.getTreasury());

    }

    function testCreateCouncilCampaign() public {
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
        assertEq(council.getCampaignPhase(), 1);
        assertTrue(council.getCampaignStartTime() > 0);  
    }

    function testCandidateAttending() public {
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
        // 候選人參選
        candidateAttending();
    }

    function testCampaignVoting() public {
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
        // 候選人參選
        candidateAttending();
        // 項目方更改競選階段為投票階段
        changeCampaignPhaseToVoting();
        //理事會競選投票
        campaignVote(); 
    }

    function testCampaignConfirming() public {
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
        // 候選人參選
        candidateAttending();
        // 項目方更改競選階段為投票階段
        changeCampaignPhaseToVoting();
        //理事會競選投票
        campaignVote();
        // 項目方更改競選階段為結算階段
        changeCampaignPhaseToConfirming();
        //結算
        campaignConfirm();

        assertEq(treasury.getOwner().length, 5);
    }

    function campaignConfirm() public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        setUpInstance.campaignConfirm();
        vm.stopPrank();

        //assertEq(council.getCampaignPhase(), 0);
    }

    function changeCampaignPhaseToConfirming() public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        vm.warp(block.timestamp + 86400 *7 *3);
        setUpInstance.changeCamgaignPhaseToConfirming();
        vm.stopPrank();
        //assertEq(council.getCampaignPhase(), 3);
    }

    function changeCampaignPhaseToVoting() public {

        vm.expectRevert("not arrive voting time.");
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        vm.warp(block.timestamp + 86400 *7 );
        setUpInstance.changeCamgaignPhaseToVoting();

        vm.warp(block.timestamp + 86400 *7 *2);
        setUpInstance.changeCamgaignPhaseToVoting();
        vm.stopPrank();
        assertEq(council.getCampaignPhase(), 2);

    }

    function candidateAttending() public {
        vm.startPrank(0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d);
        council.participate("Paul", "Vote Paul.");
        vm.stopPrank();
        assertEq(council.getCandidateNum(), 1);

        vm.startPrank(0x0555187CccE757Aa48259dF9433342B02aF16b6f);
        council.participate("Jeff", "Vote Jeff.");
        vm.stopPrank();
        assertEq(council.getCandidateNum(), 2);

        vm.startPrank(0xaB084bCF2a30B457D71bDE1894de8014619A221A);
        council.participate("Steve", "Vote Steve.");
        vm.stopPrank();
        assertEq(council.getCandidateNum(), 3);

        vm.startPrank(0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9);
        council.participate("Andrew", "Vote Andrew.");
        vm.stopPrank();
        assertEq(council.getCandidateNum(), 4);

        vm.startPrank(0x54d3b43B7c8482d44b5788C9094c319028e6ee2e);
        council.participate("Cliff", "Vote Cliff.");
        vm.stopPrank();
        assertEq(council.getCandidateNum(), 5);
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
        trendToken.publicMint{value: 1 ether}(1000);
        assertEq(trendToken.balanceOf(0xD7C20d7178AA5c47C890dF272f449c902731b411), 1000);
        trendToken.stakeToken(1000);
        assertEq(trendToken.stakedBalanceOf(0xD7C20d7178AA5c47C890dF272f449c902731b411), 1000);
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
    
        trendToken.publicMint{value: 1 ether}(5000);
        assertEq(trendToken.balanceOf(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5), 5000);
        trendToken.stakeToken(5000);
        assertEq(trendToken.stakedBalanceOf(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5), 5000);
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

    function campaignVote() public {
        
        vm.startPrank(0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d);
        council.campaignVote(0, council.getRemainVotePower(0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d));
        console.log("0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d: ",council.getRemainVotePower(0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d) );
        vm.stopPrank();

        vm.startPrank(0x0555187CccE757Aa48259dF9433342B02aF16b6f);
        council.campaignVote(1, council.getRemainVotePower(0x0555187CccE757Aa48259dF9433342B02aF16b6f));
        console.log("0x0555187CccE757Aa48259dF9433342B02aF16b6f: ",council.getRemainVotePower(0x0555187CccE757Aa48259dF9433342B02aF16b6f) );       
        vm.stopPrank();

        vm.startPrank(0xaB084bCF2a30B457D71bDE1894de8014619A221A);
        council.campaignVote(2, council.getRemainVotePower(0xaB084bCF2a30B457D71bDE1894de8014619A221A));
        console.log("0xaB084bCF2a30B457D71bDE1894de8014619A221A: ",council.getRemainVotePower(0xaB084bCF2a30B457D71bDE1894de8014619A221A) );
        vm.stopPrank();

        vm.startPrank(0x6337c10F0DfcE4f813306f577A04c42132F7dCb2);
        council.campaignVote(3, council.getRemainVotePower(0x6337c10F0DfcE4f813306f577A04c42132F7dCb2));
        console.log("0x6337c10F0DfcE4f813306f577A04c42132F7dCb2: ",council.getRemainVotePower(0x6337c10F0DfcE4f813306f577A04c42132F7dCb2) );
        vm.stopPrank();

        vm.startPrank(0x5E56672df2929E9EA6427186d1F8dD7c282e61C1);
        council.campaignVote(4, council.getRemainVotePower(0x5E56672df2929E9EA6427186d1F8dD7c282e61C1));
        console.log("0x5E56672df2929E9EA6427186d1F8dD7c282e61C1: ",council.getRemainVotePower(0x5E56672df2929E9EA6427186d1F8dD7c282e61C1) );
        vm.stopPrank();

        vm.startPrank(0xD7C20d7178AA5c47C890dF272f449c902731b411);
        council.campaignVote(0, council.getRemainVotePower(0xD7C20d7178AA5c47C890dF272f449c902731b411));
        console.log("0xD7C20d7178AA5c47C890dF272f449c902731b411: ",council.getRemainVotePower(0xD7C20d7178AA5c47C890dF272f449c902731b411) );
        vm.stopPrank();


        vm.startPrank(0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9);
        council.campaignVote(1, council.getRemainVotePower(0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9));
        console.log("0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9: ",council.getRemainVotePower(0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9) );
        vm.stopPrank();

        vm.startPrank(0x54d3b43B7c8482d44b5788C9094c319028e6ee2e);
        council.campaignVote(2, council.getRemainVotePower(0x54d3b43B7c8482d44b5788C9094c319028e6ee2e));
        console.log("0x54d3b43B7c8482d44b5788C9094c319028e6ee2e: ",council.getRemainVotePower(0x54d3b43B7c8482d44b5788C9094c319028e6ee2e) );
        vm.stopPrank();

        vm.startPrank(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF);
        council.campaignVote(3, council.getRemainVotePower(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF));
        console.log("0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF: ",council.getRemainVotePower(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF) );
        vm.stopPrank();

        vm.startPrank(0x3093E7b4E269d68Db272399754c06abA62a4F97c);
        council.campaignVote(4, council.getRemainVotePower(0x3093E7b4E269d68Db272399754c06abA62a4F97c));
        console.log("0x3093E7b4E269d68Db272399754c06abA62a4F97c: ",council.getRemainVotePower(0x3093E7b4E269d68Db272399754c06abA62a4F97c) );
        vm.stopPrank();

        vm.startPrank(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5);
        council.campaignVote(0, council.getRemainVotePower(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5));
        console.log("0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5: ",council.getRemainVotePower(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5) );
        vm.stopPrank();
    }
}