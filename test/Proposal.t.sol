// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../src/ERC20/TrendToken.sol";
import "../src/Governance/Proposal.sol";
import "../src/Governance/IProposal.sol";
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

contract ProposalTest is Test {
    IProposal public proposal;
    ITrendToken public trendToken; 
    ICouncil public council;
    ITreasury public treasury;
    IMasterTreasury public masterTreasury;
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
        TrendToken trendTokenInstance = new TrendToken(18);
        UniswapV2Invest uniswapV2InvestInstance = new UniswapV2Invest(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, address(trendToken));
        
        TrendMasterNFT trendMasterNFTInstance = new TrendMasterNFT();
        NFTStakingRewards nftStakingRewardsInstance = new NFTStakingRewards(address(trendMasterNFTInstance), address(trendTokenInstance));
        tokenStakingRewardsInstance = new TokenStakingRewards(address(trendTokenInstance));

        Treasury treasuryInstance = new Treasury(owners, address(uniswapV2InvestInstance), address(trendTokenInstance), address(nftStakingRewardsInstance), address(tokenStakingRewardsInstance));
        MasterTreasury masterTreasuryInstance = new MasterTreasury(owners, address(uniswapV2InvestInstance), address(trendMasterNFTInstance));
        //TokenAirdrop tokenAirdropInstance = new TokenAirdrop(address(trendTokenInstance));
        Council councilInstance = new Council(address(tokenStakingRewardsInstance), address(treasuryInstance), address(masterTreasuryInstance));
        Proposal proposalInstance = new Proposal(address(tokenStakingRewardsInstance), address(trendMasterNFTInstance), address(treasuryInstance), address(masterTreasuryInstance), address(councilInstance));
        

        councilInstance.setController(address(proposalInstance));
        trendTokenInstance.setController(address(proposalInstance));
        trendMasterNFTInstance.setController(address(proposalInstance));
        uniswapV2InvestInstance.addController(address(treasuryInstance));
        uniswapV2InvestInstance.addController(address(masterTreasuryInstance));
        
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
        masterTreasury = IMasterTreasury(address(masterTreasuryInstance));

         trendToken.tokenDistribute();

         tokenStakingRewardsInstance.setRewardsDuration(86400 * 365);
         tokenStakingRewardsInstance.notifyRewardAmount(250000000 ether);

        vm.stopPrank();
    }

    function testSetVotePowerThreshold() public {

        assertEq(proposal.getVotePowerThreshold(), 10);
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //提案更改提案的結算時最低參與投票的門檻
        proposeSetProposalVotePowerThreshold();
         //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);
        //查看結果
        assertEq(proposal.getVotePowerThreshold(), 30);
    }
    function testSetTokenNumThreshold() public {

        assertEq(proposal.getTokenNumThreshold(), 10000 ether);

        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //提案更改提案的結算時最低參與投票的門檻
        proposeSetProposalTokenNumThreshold();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);
        //查看結果
        assertEq(proposal.getTokenNumThreshold(), 30000 ether);
    }

    function testSetProposalPhaseDuration() public {
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //提案更改提案的結算時最低參與投票的門檻
        proposeSetProposalPhaseDuration();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);
    }

    function testSetProposalVotePowerTokenThreshold() public {
        assertEq(proposal.getVotePowerTokenThreshold(0), 100 ether);
        assertEq(proposal.getVotePowerTokenThreshold(1), 3000 ether);
        assertEq(proposal.getVotePowerTokenThreshold(2), 10000 ether);
        assertEq(proposal.getVotePowerTokenThreshold(3), 100000 ether);
        assertEq(proposal.getVotePowerTokenThreshold(4), 1000000 ether);
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //提案更改提案的結算時最低參與投票的門檻
        proposeSetProposalVotePowerTokenThreshold();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);
        //查看結果
        assertEq(proposal.getVotePowerTokenThreshold(0), 10 ether);
        assertEq(proposal.getVotePowerTokenThreshold(1), 20 ether);
        assertEq(proposal.getVotePowerTokenThreshold(2), 30 ether);
        assertEq(proposal.getVotePowerTokenThreshold(3), 40 ether);
        assertEq(proposal.getVotePowerTokenThreshold(4), 50 ether);
    }

    function testSetTreasuryComfirmNum() public {
        assertEq(treasury.getTxRequireConfirmedNum(), 2);
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //提案更改提案的結算時最低參與投票的門檻
        proposeSetTreasuryConfirmNum();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);
        //查看結果
        assertEq(treasury.getTxRequireConfirmedNum(), 1);
    }

    function testSetMasterTreasuryComfirmNum() public {
        assertEq(masterTreasury.getTxRequireConfirmedNum(), 2);
        // 初始化資金&質押
        dealHoldersAndMintTrendToken();
        //提案更改提案的結算時最低參與投票的門檻
        proposeSetMasterTreasuryConfirmNum();
        //項目方更改提案階段為投票階段
        changeProposalPhaseToVote(0);
        //提案投票
        proposalVoting(0);
        //項目方更改提案狀態為結算階段
        changeProposalPhaseToConfirming(0);
        //提案結算
        propsalConfirming(0);
        //查看結果
        assertEq(masterTreasury.getTxRequireConfirmedNum(), 1);
    }

    function proposeSetMasterTreasuryConfirmNum() public {
        clearArray();
        uintArr.push(1);

        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);

        proposal.propose(
             14,
            "No.1 Update Proposal Master Treasury Confirm Number.",
            "The first modification of master treasury confirm number.",
            uintArr,
            addrArr,
            block.timestamp
        );

        assertEq(proposal.getProposalsAmount(), 1);
    }

    function proposeSetTreasuryConfirmNum() public {
        clearArray();
        uintArr.push(1);

        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);

        proposal.propose(
             13,
            "No.1 Update Proposal Treasury Confirm Number.",
            "The first modification of treasury confirm number.",
            uintArr,
            addrArr,
            block.timestamp
        );

        assertEq(proposal.getProposalsAmount(), 1);
    }

    function proposeSetProposalVotePowerTokenThreshold() public {

        clearArray();
        uintArr.push(10 ether);
        uintArr.push(20 ether);
        uintArr.push(30 ether);
        uintArr.push(40 ether);
        uintArr.push(50 ether);

        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);

        proposal.propose(
             12,
            "No.1 Update Proposal Vote Power token threshold.",
            "The first modification of proposal Vote Power token threshold.",
            uintArr,
            addrArr,
            block.timestamp
        );

        assertEq(proposal.getProposalsAmount(), 1);
    }

    function proposeSetProposalPhaseDuration() public {
        clearArray();
        uintArr.push(block.timestamp);
        uintArr.push(block.timestamp);

        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);

        proposal.propose(
             11,
            "No.1 Update Proposal Phase Duration.",
            "The first modification of proposal phase duration.",
            uintArr,
            addrArr,
            block.timestamp
        );

        assertEq(proposal.getProposalsAmount(), 1);

    }

    function proposeSetProposalTokenNumThreshold() public {
        clearArray();
        uintArr.push(30000 ether);

        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);

        proposal.propose(
             10,
            "No.1 Update Proposal Token numbers Threshold.",
            "The first modification of proposal token number threshold.",
            uintArr,
            addrArr,
            block.timestamp
        );

        assertEq(proposal.getProposalsAmount(), 1);
    }

    //提案結算
    function propsalConfirming(uint256 _index) public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        proposal.proposalConfirm(_index);
        vm.stopPrank();

        assertEq(proposal.getProposalPhaseIndex(0), 3);
    }

    //項目方更改提案狀態為結算階段
    function changeProposalPhaseToConfirming(uint256 _index) public {
        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        vm.warp(block.timestamp + 86400 *7 *2);
        proposal.changeProposalPhaseToConfirming(_index);
        vm.stopPrank();

        assertEq(proposal.getProposalPhaseIndex(_index), 2);
    }

    function proposeSetProposalVotePowerThreshold() public {
        clearArray();
        uintArr.push(30);

        vm.prank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);

        proposal.propose(
             9,
            "No.1 Update Proposal Vote Power Threshold.",
            "The first modification of proposal vote power threshold.",
            uintArr,
            addrArr,
            block.timestamp
        );

        assertEq(proposal.getProposalsAmount(), 1);
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


}