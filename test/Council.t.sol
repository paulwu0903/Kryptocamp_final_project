// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../src/SetUp.sol";
import "../src/ERC20/TrendToken.sol";
import "../src/Governance/Proposal.sol";
import "../src/Governance/Treasury.sol";
import "../src/Governance/MasterTreasury.sol";
import "../src/ERC721A/TrendMasterNFT.sol";
import "../src/Governance/Council.sol";
import "../src/Stake/TokenStakingRewards.sol";
import "../src/Stake/NFTStakingRewards.sol";
import "../src/Airdrop/TokenAirdrop.sol";
import "../src/Airdrop/ITokenAirdrop.sol";
import "../src/Invest/IUniswapV2Invest.sol";
import "../src/Invest/UniswapV2Invest.sol";

contract CouncilTest is Test {

    IProposal public proposal;
    ITrendToken public trendToken; 
    ICouncil public council;
    ITreasury public treasury;
    ITokenStakingRewards public tokenStakingRewards;
    ITokenAirdrop public tokenAirdrop;
    IUniswapV2Invest public uniswapV2Invest;
    TokenStakingRewards tokenStakingRewardsInstance;

    address[] public owners = [
            0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed,
            0xaB084bCF2a30B457D71bDE1894de8014619A221A,
            0x6337c10F0DfcE4f813306f577A04c42132F7dCb2 
            ];
    
    address[] public holders = [
        0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed,
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
        UniswapV2Invest uniswapV2Invest = new UniswapV2Invest(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        TrendToken trendTokenInstance = new TrendToken(18);
        TrendMasterNFT trendMasterNFTInstance = new TrendMasterNFT();
        NFTStakingRewards nftStakingRewardsInstance = new NFTStakingRewards(address(trendMasterNFTInstance), address(trendTokenInstance));
        tokenStakingRewardsInstance = new TokenStakingRewards(address(trendTokenInstance));

        Treasury treasuryInstance = new Treasury(owners, address(uniswapV2Invest), address(trendTokenInstance), address(nftStakingRewardsInstance), address(tokenStakingRewardsInstance));
        MasterTreasury masterTreasuryInstance = new MasterTreasury(owners, address(uniswapV2Invest), address(trendMasterNFTInstance));
        //TokenAirdrop tokenAirdropInstance = new TokenAirdrop(address(trendTokenInstance));
        Council councilInstance = new Council(address(tokenStakingRewardsInstance), address(treasuryInstance), address(masterTreasuryInstance));
        Proposal proposalInstance = new Proposal(address(tokenStakingRewardsInstance), address(trendMasterNFTInstance), address(treasuryInstance), address(councilInstance));
        

        councilInstance.setController(address(proposalInstance));
        trendTokenInstance.setController(address(proposalInstance));
        trendMasterNFTInstance.setController(address(proposalInstance));
        
        trendTokenInstance.setDistribution(
            {
                _treasuryAddress: address(treasuryInstance),
                _treasuryAmount: 200000000 ether, 
                _tokenStakeInterestAddress: address(tokenStakingRewardsInstance),
                _tokenStakeInterestAmount: 250000000 ether, 
                _consultantAddress: address(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed), 
                _consultantAmount: 30000000 ether, 
                _airdropAddress: address(new TokenAirdrop(address(trendTokenInstance))),
                _airdropAmount: 20000000 ether, 
                _nftStakeInterestAddress: address(trendMasterNFTInstance), 
                _nftStakeInterestAmount: 300000000 ether, 
                _publicMintAmount: 200000000 ether
            });
        
        
        council = ICouncil(address(councilInstance));
        proposal = IProposal(address(proposalInstance));
        trendToken = ITrendToken(address(trendTokenInstance));
        treasury = ITreasury(address(treasuryInstance));

        trendToken.tokenDistribute();

        tokenStakingRewardsInstance.setRewardsDuration(86400 * 365);
        tokenStakingRewardsInstance.notifyRewardAmount(250000000 ether);

        vm.stopPrank();

    }

    //測試理事會競選
    function testCampaign() public {
        
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //新增理事會提案
        proposeCampaign();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);
        // 候選人參選
        candidateAttending();
        // 項目方更改競選階段為投票階段
        changeCampaignPhaseToVoting();
        //理事會競選投票
        campaignVote();
        // 項目方更改競選階段為結算階段
        changeCampaignPhaseToConfirming();
        //理事會競選結算
        campaignConfirm(5);
        
    }
    //測試理事會罷免
    function testRecall() public {
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //提案罷免
        proposeRecall(1);
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);
        // 項目方更改罷免階段為投票階段
        changeRecallPhaseToVoting();
        //罷免投票
        recallVote();
        //項目方更改罷免階段為結算階段
        changeRecallPhaseToConfirming();
        //罷免理事會結案
        recallConfirm(2); 
    }
    
     //測試理事會競選完，接著罷免
    function testCampaignAndRecall() public {
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //新增理事會提案
        proposeCampaign();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);
        // 候選人參選
        candidateAttending();
        // 項目方更改競選階段為投票階段
        changeCampaignPhaseToVoting();
        //理事會競選投票
        campaignVote();
        // 項目方更改競選階段為結算階段
        changeCampaignPhaseToConfirming();
        //理事會競選結算
        campaignConfirm(5);

        //--------------------------------

        //提案罷免
        proposeRecall(2);
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(1);
        //提案投票
        proposalVoting(1);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(1);
        //提案結算
        propsalConfirming(1);
        // 項目方更改罷免階段為投票階段
        changeRecallPhaseToVoting();
        //罷免投票
        recallVote();
        //項目方更改罷免階段為結算階段
        changeRecallPhaseToConfirming();
        //罷免理事會結案
        recallConfirm(4); 
    }

    //測試提案修改候選人持幣門檻
    function testSetCandidateTokenThreshold() public {
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //提案更改參與理事會競選持幣門檻
        proposeModifyCandidateThreshold();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);

        //檢查理事會持幣門檻是否更動
        assertEq(council.getTokenNumThreshold(), 100 ether);
    }

    //測試提案修改競選參與票數門檻
    function testSetVotePoswerThreshold() public {
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //提案更改參與票數門檻
        proposeModifyCouncilVotePowerThreshold();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);

        //檢查參選票數門檻
        assertEq(council.getVotePowerThreshold(), 10);
    }
    function testSetCouncilNumLimit () public {

        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //提案更改理事會人數上限
        proposeModifyCouncilNumLimit();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);
        //檢查理事會上限值
        assertEq(council.getCouncilMemberNumLimit(), 30);
    }

    function testLevelVotePowerThresholds() public{
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //提案更改Council取得Vote Power門檻規範
        proposeLevelVotePowerThresholds();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);
        //檢查理各Level值有無正確
        assertEq(council.getLevelOfVotePower(0), 10 ether);
        assertEq(council.getLevelOfVotePower(1), 50 ether);
        assertEq(council.getLevelOfVotePower(2), 100 ether);
        assertEq(council.getLevelOfVotePower(3), 1000 ether);
        assertEq(council.getLevelOfVotePower(4), 10000 ether);
    }

    function testSetCampaignPassVoteThreshold() public {
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //提案更改Council競選通過的門檻
        proposeSetPassThreshold();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);
        //檢查理事會競選Pass門檻
        assertEq(council.getVotePassThreshold(), 30);
    }

    function testSetCampaignDuration() public {
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //提案更改Council競選各階段的期間
        proposeModifyCampaignDuration();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);
    }

    function testSetRecallDuration() public {
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //提案更改Council罷免各階段時間點
        proposeModifyRecallDuration();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);
    }

    function proposeModifyRecallDuration() public {
        clearArray();
        uintArr.push(block.timestamp);
        uintArr.push(block.timestamp);

        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        proposal.propose(
            8,
            "No.1 Update Council recall duration",
            "The first modification of council recall duration.",
            uintArr,
            addrArr,
            block.timestamp
        );
    }

    function proposeModifyCampaignDuration() public {
        clearArray();
        uintArr.push(block.timestamp);
        uintArr.push(block.timestamp);
        uintArr.push(block.timestamp);

        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        proposal.propose(
            7,
            "No.1 Update Council campaign duration",
            "The first modification of council campaign duration.",
            uintArr,
            addrArr,
            block.timestamp
        );

        assertEq(proposal.getProposalsAmount(), 1);
    }

    function proposeSetPassThreshold() public {
        clearArray();
        uintArr.push(30);

        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        proposal.propose(
            6,
            "No.1 Update Council Pass Vote Power Thresholds",
            "The first modification of pass Vote Power Thresholds.",
            uintArr,
            addrArr,
            block.timestamp
        );
        assertEq(proposal.getProposalsAmount(), 1);
    }

    function proposeLevelVotePowerThresholds()  public {
        clearArray();
        uintArr.push(10 ether);
        uintArr.push(50 ether);
        uintArr.push(100 ether);
        uintArr.push(1000 ether);
        uintArr.push(10000 ether);

        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        proposal.propose(
            5,
            "No.1 Update Council Level Vote Power Thresholds",
            "The first modification of Level Vote Power Thresholds.",
            uintArr,
            addrArr,
            block.timestamp
        );
        assertEq(proposal.getProposalsAmount(), 1);
    }

    function proposeModifyCouncilNumLimit() public {
        clearArray();
        uintArr.push(30);

        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        proposal.propose(
            4,
            "No.1 Update Council Num Limit.",
            "The first modification of Council num limit.",
            uintArr,
            addrArr,
            block.timestamp
        );

        assertEq(proposal.getProposalsAmount(), 1);
    }
        

    function proposeModifyCouncilVotePowerThreshold() public {
        clearArray();
        uintArr.push(10);

        //持有10000顆Trend Token才可以提案
        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        proposal.propose(
            3,
            "No.1 Update Council Vote Power Threshold.",
            "The first modification of Council vote power threshold.",
            uintArr,
            addrArr,
            block.timestamp
        );

        assertEq(proposal.getProposalsAmount(), 1);
    }

    function proposeModifyCandidateThreshold() public {
        clearArray();
        uintArr.push(100 ether);

        //持有10000顆Trend Token才可以提案
        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        proposal.propose(
            2,
            "No.1 Update Candidate Token",
            "The first modification of Candidate token threshold.",
            uintArr,
            addrArr,
            block.timestamp
        );

        assertEq(proposal.getProposalsAmount(), 1);
    }

    //罷免提案
    function proposeRecall( uint256 _proposalAmount) public {
        clearArray();
        addrArr.push(0xaB084bCF2a30B457D71bDE1894de8014619A221A);

        //持有10000顆Trend Token才可提案
        vm.prank(0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9);
        proposal.propose(
            1,
            "No.1 Council Recall",
            "The first council recall.",
            uintArr,
            addrArr,
            block.timestamp
        );
        assertEq(proposal.getProposalsAmount(), _proposalAmount);
    }

    //理事會罷免結算
    function recallConfirm(uint256 _ownerNum) public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        council.recallConfirm();
        vm.stopPrank();
        assertEq(council.getRecallPhase(), 0);
        assertEq(treasury.getOwner().length, _ownerNum);
    }

    //理事會競選結算
    function campaignConfirm(uint256 _ownerNum) public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        council.campaignConfirm();
        vm.stopPrank();

        assertEq(council.getCampaignPhase(), 0);
        assertEq(treasury.getOwner().length, _ownerNum);
    }

    // 項目方更改競選階段為結算階段
    function changeCampaignPhaseToConfirming() public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        vm.warp(block.timestamp + 86400 *7 *3);
        council.changeCampaignToConforming();
        vm.stopPrank();
        //assertEq(council.getCampaignPhase(), 3);
    }
    // 項目方更改競選階段為投票階段
    function changeCampaignPhaseToVoting() public {

        vm.expectRevert("not arrive voting time.");
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        vm.warp(block.timestamp + 86400 *7 );
        council.changeCampaignToVoting();

        vm.warp(block.timestamp + 86400 *7 *2);
        council.changeCampaignToVoting();
        vm.stopPrank();
        assertEq(council.getCampaignPhase(), 2);

    }
    // 項目方更改罷免階段為投票階段 
    function changeRecallPhaseToVoting() public {

        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        vm.warp(block.timestamp + 86400 *7 );
        council.changeRecallToVoting();
        vm.stopPrank();
        assertEq(council.getRecallPhase(), 1);

    }

    // 項目方更改罷免階段為結算階段
    function changeRecallPhaseToConfirming() public {

        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        vm.warp(block.timestamp + 86400 *7 * 2 );
        council.changeRecallToConfirming();
        vm.stopPrank();
        assertEq(council.getRecallPhase(), 2);

    }

    // 候選人參選
    function candidateAttending() public {
        vm.startPrank(0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d);
        council.participate("Paul", "Vote Paul.");
        vm.stopPrank();
        assertEq(council.getCandidateNum(), 1);

        vm.startPrank(0x0555187CccE757Aa48259dF9433342B02aF16b6f);
        council.participate("Jeff", "Vote Jeff.");
        vm.stopPrank();
        assertEq(council.getCandidateNum(), 2);

        vm.startPrank(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5);
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


    //新增理事會提案
    function proposeCampaign() public {
        clearArray();
        uintArr.push(2);
        uintArr.push(5);

        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        proposal.propose(
            0,
            "No.1 Council Campaign",
            "The first council campaign.",
            uintArr,
            addrArr,
            block.timestamp);
    }
    //初始化資金&質押
    function dealHoldersAndMintTrendToken() public {
        
        for (uint256 i=0; i < holders.length; i++){
            vm.deal(holders[i], 100 ether);
        }
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        trendToken.approve(address(tokenStakingRewardsInstance), 1000000 ether);
        tokenStakingRewardsInstance.stake(1000000 ether);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed), 1000000 ether);
        vm.stopPrank();
        
        //購買Trend Token並投票
        vm.startPrank(0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d);
        trendToken.publicMint{value: 100 ether}(1000000 ether);
        assertEq(trendToken.balanceOf(0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d), 1000000 ether);
        trendToken.approve(address(tokenStakingRewardsInstance), 1000000 ether);
        tokenStakingRewardsInstance.stake(1000000 ether);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d), 1000000 ether);
        vm.stopPrank();
        
        vm.startPrank(0x0555187CccE757Aa48259dF9433342B02aF16b6f);
        trendToken.publicMint{value: 100 ether}(1000000 ether);
        assertEq(trendToken.balanceOf(0x0555187CccE757Aa48259dF9433342B02aF16b6f), 1000000 ether);
        trendToken.approve(address(tokenStakingRewardsInstance), 1000000 ether);
        tokenStakingRewardsInstance.stake(1000000 ether);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0x0555187CccE757Aa48259dF9433342B02aF16b6f), 1000000 ether);
        vm.stopPrank();

        vm.startPrank(0xaB084bCF2a30B457D71bDE1894de8014619A221A);
        trendToken.publicMint{value: 1 ether}(100000 ether);
        assertEq(trendToken.balanceOf(0xaB084bCF2a30B457D71bDE1894de8014619A221A), 100000 ether);
        trendToken.approve(address(tokenStakingRewardsInstance), 100000 ether);
        tokenStakingRewardsInstance.stake(100000 ether);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0xaB084bCF2a30B457D71bDE1894de8014619A221A), 100000 ether);
        vm.stopPrank();

        vm.startPrank(0x6337c10F0DfcE4f813306f577A04c42132F7dCb2);
        trendToken.publicMint{value: 1 ether}(5000 ether);
        assertEq(trendToken.balanceOf(0x6337c10F0DfcE4f813306f577A04c42132F7dCb2), 5000 ether);
        trendToken.approve(address(tokenStakingRewardsInstance), 5000 ether);
        tokenStakingRewardsInstance.stake(5000 ether);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0x6337c10F0DfcE4f813306f577A04c42132F7dCb2), 5000 ether);
        vm.stopPrank();

        vm.startPrank(0x5E56672df2929E9EA6427186d1F8dD7c282e61C1);
        trendToken.publicMint{value: 1 ether}(200 ether);  
        assertEq(trendToken.balanceOf(0x5E56672df2929E9EA6427186d1F8dD7c282e61C1), 200 ether);
        trendToken.approve(address(tokenStakingRewardsInstance), 200 ether);
        tokenStakingRewardsInstance.stake(200 ether);  
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0x5E56672df2929E9EA6427186d1F8dD7c282e61C1), 200 ether);
        vm.stopPrank();

        vm.startPrank(0xD7C20d7178AA5c47C890dF272f449c902731b411);
        trendToken.publicMint{value: 1 ether}(1000 ether);
        assertEq(trendToken.balanceOf(0xD7C20d7178AA5c47C890dF272f449c902731b411), 1000 ether);
        trendToken.approve(address(tokenStakingRewardsInstance), 1000 ether);
        tokenStakingRewardsInstance.stake(1000 ether);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0xD7C20d7178AA5c47C890dF272f449c902731b411), 1000 ether);
        vm.stopPrank();

        vm.startPrank(0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9);
        trendToken.publicMint{value: 100 ether}(1000000 ether);
        assertEq(trendToken.balanceOf(0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9), 1000000 ether);
        trendToken.approve(address(tokenStakingRewardsInstance), 1000000 ether);
        tokenStakingRewardsInstance.stake(1000000 ether);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9), 1000000 ether);
        vm.stopPrank();

        vm.startPrank(0x54d3b43B7c8482d44b5788C9094c319028e6ee2e);
        trendToken.publicMint{value: 100 ether}(1000000 ether);
        assertEq(trendToken.balanceOf(0x54d3b43B7c8482d44b5788C9094c319028e6ee2e), 1000000 ether);
        trendToken.approve(address(tokenStakingRewardsInstance), 1000000 ether);
        tokenStakingRewardsInstance.stake(1000000 ether);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0x54d3b43B7c8482d44b5788C9094c319028e6ee2e), 1000000 ether);
        vm.stopPrank();

        vm.startPrank(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF);
        trendToken.publicMint{value: 1 ether}(400 ether);
        assertEq(trendToken.balanceOf(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF), 400 ether);
        trendToken.approve(address(tokenStakingRewardsInstance), 400 ether);
        tokenStakingRewardsInstance.stake(400 ether);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF), 400 ether);
        vm.stopPrank();

        vm.startPrank(0x3093E7b4E269d68Db272399754c06abA62a4F97c);
        trendToken.publicMint{value: 1 ether}(4000 ether);
        assertEq(trendToken.balanceOf(0x3093E7b4E269d68Db272399754c06abA62a4F97c), 4000 ether);
        trendToken.approve(address(tokenStakingRewardsInstance), 4000 ether);
        tokenStakingRewardsInstance.stake(4000 ether);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0x3093E7b4E269d68Db272399754c06abA62a4F97c), 4000 ether);
        vm.stopPrank();

        vm.expectRevert("ETH not enough!!");
        vm.startPrank(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5);
        trendToken.publicMint{value: 1 ether}(5000000000 ether);
    
        trendToken.publicMint{value: 10 ether}(100000 ether);
        assertEq(trendToken.balanceOf(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5), 100000 ether);
        trendToken.approve(address(tokenStakingRewardsInstance), 100000 ether);
        tokenStakingRewardsInstance.stake(100000 ether);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5), 100000 ether);
        vm.stopPrank();
        
    }
    //項目方更改提案階段為投票階段
    function changeProposalPhaseToVote(uint256 _index) public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        vm.warp(block.timestamp + 86400 *7);
        proposal.changeProposalPhaseToVoting(_index);
        vm.stopPrank();
        assertEq(proposal.getProposalPhaseIndex(_index), 1);
    }
    //提案投票
    function proposalVoting(uint256 _index) public {
        for(uint256 i=0; i< holders.length; i++){
            vm.startPrank(holders[i]);
            proposal.proposalVote(_index);
            vm.stopPrank();
        }
    }
    //項目方更改提案狀態為結算階段
    function changeProposalPhaseToConfirming(uint256 _index) public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        vm.warp(block.timestamp + 86400 *7 *2);
        proposal.changeProposalPhaseToConfirming(_index);
        vm.stopPrank();

        assertEq(proposal.getProposalPhaseIndex(_index), 2);
    }
    //提案結算
    function propsalConfirming(uint256 _index) public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        proposal.proposalConfirm(_index);
        vm.stopPrank();

        assertEq(proposal.getProposalPhaseIndex(0), 3);
    }

    //理事會競選投票
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
    //理事會罷免投票
    function recallVote() public {
        
        vm.startPrank(0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d);
        council.recallVote(council.getRemainVotePower(0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d));
        console.log("0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d: ",council.getRemainVotePower(0xC0ACE560563cc90b6f4E8CEd54f44d1348f7706d) );
        vm.stopPrank();

        vm.startPrank(0x0555187CccE757Aa48259dF9433342B02aF16b6f);
        council.recallVote( council.getRemainVotePower(0x0555187CccE757Aa48259dF9433342B02aF16b6f));
        console.log("0x0555187CccE757Aa48259dF9433342B02aF16b6f: ",council.getRemainVotePower(0x0555187CccE757Aa48259dF9433342B02aF16b6f) );       
        vm.stopPrank();

        vm.startPrank(0xaB084bCF2a30B457D71bDE1894de8014619A221A);
        council.recallVote(council.getRemainVotePower(0xaB084bCF2a30B457D71bDE1894de8014619A221A));
        console.log("0xaB084bCF2a30B457D71bDE1894de8014619A221A: ",council.getRemainVotePower(0xaB084bCF2a30B457D71bDE1894de8014619A221A) );
        vm.stopPrank();

        vm.startPrank(0x6337c10F0DfcE4f813306f577A04c42132F7dCb2);
        council.recallVote(council.getRemainVotePower(0x6337c10F0DfcE4f813306f577A04c42132F7dCb2));
        console.log("0x6337c10F0DfcE4f813306f577A04c42132F7dCb2: ",council.getRemainVotePower(0x6337c10F0DfcE4f813306f577A04c42132F7dCb2) );
        vm.stopPrank();

        vm.startPrank(0x5E56672df2929E9EA6427186d1F8dD7c282e61C1);
        council.recallVote(council.getRemainVotePower(0x5E56672df2929E9EA6427186d1F8dD7c282e61C1));
        console.log("0x5E56672df2929E9EA6427186d1F8dD7c282e61C1: ",council.getRemainVotePower(0x5E56672df2929E9EA6427186d1F8dD7c282e61C1) );
        vm.stopPrank();

        vm.startPrank(0xD7C20d7178AA5c47C890dF272f449c902731b411);
        council.recallVote(council.getRemainVotePower(0xD7C20d7178AA5c47C890dF272f449c902731b411));
        console.log("0xD7C20d7178AA5c47C890dF272f449c902731b411: ",council.getRemainVotePower(0xD7C20d7178AA5c47C890dF272f449c902731b411) );
        vm.stopPrank();


        vm.startPrank(0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9);
        council.recallVote(council.getRemainVotePower(0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9));
        console.log("0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9: ",council.getRemainVotePower(0x60d3A1B09a4b26E109c209cd5350c40E11cf22D9) );
        vm.stopPrank();

        vm.startPrank(0x54d3b43B7c8482d44b5788C9094c319028e6ee2e);
        council.recallVote(council.getRemainVotePower(0x54d3b43B7c8482d44b5788C9094c319028e6ee2e));
        console.log("0x54d3b43B7c8482d44b5788C9094c319028e6ee2e: ",council.getRemainVotePower(0x54d3b43B7c8482d44b5788C9094c319028e6ee2e) );
        vm.stopPrank();

        vm.startPrank(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF);
        council.recallVote(council.getRemainVotePower(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF));
        console.log("0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF: ",council.getRemainVotePower(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF) );
        vm.stopPrank();

        vm.startPrank(0x3093E7b4E269d68Db272399754c06abA62a4F97c);
        council.recallVote(council.getRemainVotePower(0x3093E7b4E269d68Db272399754c06abA62a4F97c));
        console.log("0x3093E7b4E269d68Db272399754c06abA62a4F97c: ",council.getRemainVotePower(0x3093E7b4E269d68Db272399754c06abA62a4F97c) );
        vm.stopPrank();

        vm.startPrank(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5);
        council.recallVote( council.getRemainVotePower(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5));
        console.log("0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5: ",council.getRemainVotePower(0xf80b09E4c6c8248313137101E62B5723Dd6C5ce5) );
        vm.stopPrank();
    }

    function clearArray() private {

        if (uintArr.length > 0){
            uint256 i = uintArr.length-1;
            while(i >= 0){
                delete uintArr[i];
                uintArr.pop();
                if (i == 0 ){
                    break;
                }
                i--;
            }
        }
        
        if (addrArr.length >0){
            uint256 j = addrArr.length-1;
            while(j >= 0){
                delete addrArr[j];
                addrArr.pop();
                if (j == 0 ){
                    break;
                }
                j--;
            }
        }

        console.log("uintArr length: ", uintArr.length);
        console.log("addrArr length: ", addrArr.length);

        
    }
}