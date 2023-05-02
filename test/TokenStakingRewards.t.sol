// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../src/ERC20/TrendToken.sol";
import "../src/Governance/Proposal.sol";
import "../src/Governance/Treasury.sol";
import "../src/Governance/IProposal.sol";
import "../src/Governance/MasterTreasury.sol";
import "../src/ERC721A/TrendMasterNFT.sol";
import "../src/Governance/Council.sol";
import "../src/Stake/TokenStakingRewards.sol";
import "../src/Stake/NFTStakingRewards.sol";
import "../src/Airdrop/TokenAirdrop.sol";
import "../src/Airdrop/ITokenAirdrop.sol";
import "../src/Invest/IUniswapV2Invest.sol";
import "../src/Invest/UniswapV2Invest.sol";

contract TokenStakingRewardsTest is Test {

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
        UniswapV2Invest uniswapV2InvestInstance = new UniswapV2Invest(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        TrendToken trendTokenInstance = new TrendToken(18);
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

         trendToken.tokenDistribute();

         tokenStakingRewardsInstance.setRewardsDuration(86400 * 365);
         tokenStakingRewardsInstance.notifyRewardAmount(250000000 ether);

        vm.stopPrank();

    }

    function testStake() public {
        //發錢
        dealHoldersAndMintTrendToken();
        
        vm.startPrank(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF);
        vm.warp(block.timestamp);
        trendToken.publicMint{value: 100 ether}(10 ether);
        assertEq(trendToken.balanceOf(address(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF)), 10 ether);
        trendToken.approve(address(tokenStakingRewardsInstance), 10 ether);
        tokenStakingRewardsInstance.stake(10 ether);
        vm.warp(block.timestamp + 86400 * 30);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF), 10 ether);
        vm.stopPrank();
    }

    function testGetRewards() public {
        //發錢
        dealHoldersAndMintTrendToken();
        
        vm.startPrank(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF);
        vm.warp(block.timestamp);
        trendToken.publicMint{value: 100 ether}(10 ether);
        assertEq(trendToken.balanceOf(address(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF)), 10 ether);
        trendToken.approve(address(tokenStakingRewardsInstance), 10 ether);
        tokenStakingRewardsInstance.stake(10 ether);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF), 10 ether);
        vm.warp(block.timestamp + 86400 * 30);
        tokenStakingRewardsInstance.getReward();
        console.log("0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF: ", trendToken.balanceOf(address(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF)));
        assertTrue(trendToken.balanceOf(address(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF)) > 10 ether);
        vm.stopPrank();
    }


    function testWithdraw() public {
        //發錢
        dealHoldersAndMintTrendToken();
        
        vm.startPrank(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF);
        vm.warp(block.timestamp);
        trendToken.publicMint{value: 100 ether}(10 ether);
        assertEq(trendToken.balanceOf(address(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF)), 10 ether);
        trendToken.approve(address(tokenStakingRewardsInstance), 10 ether);
        tokenStakingRewardsInstance.stake(10 ether);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF), 10 ether);
        vm.warp(block.timestamp + 86400 * 30);
        tokenStakingRewardsInstance.getReward();
        console.log("0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF: ", trendToken.balanceOf(address(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF)));
        assertTrue(trendToken.balanceOf(address(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF)) > 10 ether);
        tokenStakingRewardsInstance.withdraw(10 ether);
        assertEq(tokenStakingRewardsInstance.getBalanceOf(address(0xE7918DBc151Bf711d7E2DFe8d19F686B2938A7AF)), 0);
        vm.stopPrank();

    }

    //初始化資金&質押
    function dealHoldersAndMintTrendToken() public {
        vm.deal(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed, 1000 ether);
        
        for (uint256 i=0; i < holders.length; i++){
            vm.deal(holders[i], 1000 ether);
        }
    }

}