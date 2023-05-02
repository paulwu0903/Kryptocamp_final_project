// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../src/ERC20/TrendToken.sol";
import "../src/Governance/IProposal.sol";
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

contract NFTStakingRewardsTest is Test {

    ITrendToken public trendToken; 
    ITrendMasterNFT public trendMasterNFT;
    ITreasury public treasury;
    ITokenStakingRewards public tokenStakingRewards;
    ITokenAirdrop public tokenAirdrop;
    IUniswapV2Invest public uniswapV2Invest;
    NFTStakingRewards nftStakingRewardsInstance;
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
        nftStakingRewardsInstance = new NFTStakingRewards(address(trendMasterNFTInstance), address(trendTokenInstance));
        tokenStakingRewardsInstance = new TokenStakingRewards(address(trendTokenInstance));

        Treasury treasuryInstance = new Treasury(owners, address(uniswapV2InvestInstance), address(trendTokenInstance), address(nftStakingRewardsInstance), address(tokenStakingRewardsInstance));
        
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
                _nftStakeInterestAddress: address(nftStakingRewardsInstance), 
                _nftStakeInterestAmount: 300000000 ether, 
                _publicMintAmount: 200000000 ether
            });
        
        
        trendToken = ITrendToken(address(trendTokenInstance));
        treasury = ITreasury(address(treasuryInstance));
        trendMasterNFT = ITrendMasterNFT(address(trendMasterNFTInstance));

        trendToken.tokenDistribute();

        nftStakingRewardsInstance.setRewardsDuration(86400 * 365);
        nftStakingRewardsInstance.notifyRewardAmount(300000000 ether);

        //設定merkle tree root
        trendMasterNFT.setWhitelistMerkleTree(0x1b98708867d02869531ce882687f672158fb8735d9ab0a7015f72a2e4ba58275);
        //設定荷蘭拍資訊
        trendMasterNFT.setAuction(3 ether, 1 ether, 10^8 gwei , block.timestamp, 1 minutes, 20);


        vm.stopPrank();

    }

    function testStake() public {
        //發錢
        dealHoldersAndMintTrendToken();

        uint256 price = 0;
        vm.startPrank(0xD7C20d7178AA5c47C890dF272f449c902731b411);
        vm.warp(block.timestamp + 60);
        price = trendMasterNFT.getAuctionPrice();
        trendMasterNFT.publicAuctionMint{value: price*2 }(2);
        assertEq(trendMasterNFT.balanceOf(0xD7C20d7178AA5c47C890dF272f449c902731b411), 2);
        assertEq(trendToken.balanceOf(0xD7C20d7178AA5c47C890dF272f449c902731b411), 0);
        trendMasterNFT.approve(address(nftStakingRewardsInstance), 0);
        trendMasterNFT.approve(address(nftStakingRewardsInstance), 1);
        nftStakingRewardsInstance.stake(0);
        nftStakingRewardsInstance.stake(1);
        assertEq(nftStakingRewardsInstance.getBalanceOf(address(0xD7C20d7178AA5c47C890dF272f449c902731b411)), 2);

        vm.stopPrank();
        
    }

    function testGetRewards() public {
        //發錢
        dealHoldersAndMintTrendToken();

        uint256 price = 0;
        vm.startPrank(0xD7C20d7178AA5c47C890dF272f449c902731b411);
        vm.warp(block.timestamp + 60);
        price = trendMasterNFT.getAuctionPrice();
        trendMasterNFT.publicAuctionMint{value: price*2 }(2);
        assertEq(trendMasterNFT.balanceOf(0xD7C20d7178AA5c47C890dF272f449c902731b411), 2);
        assertEq(trendToken.balanceOf(0xD7C20d7178AA5c47C890dF272f449c902731b411), 0);
        trendMasterNFT.approve(address(nftStakingRewardsInstance), 0);
        trendMasterNFT.approve(address(nftStakingRewardsInstance), 1);
        nftStakingRewardsInstance.stake(0);
        nftStakingRewardsInstance.stake(1);
        assertEq(nftStakingRewardsInstance.getBalanceOf(address(0xD7C20d7178AA5c47C890dF272f449c902731b411)), 2);
        vm.warp(block.timestamp + 86400 * 30);
        nftStakingRewardsInstance.getReward();
        console.log("0xD7C20d7178AA5c47C890dF272f449c902731b411: ", trendToken.balanceOf(address(0xD7C20d7178AA5c47C890dF272f449c902731b411)));
        assertTrue(trendToken.balanceOf(0xD7C20d7178AA5c47C890dF272f449c902731b411) > 0);
        vm.stopPrank();

    }

    function testWithdraw() public {
        //發錢
        dealHoldersAndMintTrendToken();

        uint256 price = 0;
        vm.startPrank(0xD7C20d7178AA5c47C890dF272f449c902731b411);
        vm.warp(block.timestamp + 60);
        price = trendMasterNFT.getAuctionPrice();
        trendMasterNFT.publicAuctionMint{value: price*2 }(2);
        assertEq(trendMasterNFT.balanceOf(0xD7C20d7178AA5c47C890dF272f449c902731b411), 2);
        assertEq(trendToken.balanceOf(0xD7C20d7178AA5c47C890dF272f449c902731b411), 0);
        trendMasterNFT.approve(address(nftStakingRewardsInstance), 0);
        trendMasterNFT.approve(address(nftStakingRewardsInstance), 1);
        nftStakingRewardsInstance.stake(0);
        nftStakingRewardsInstance.stake(1);
        assertEq(nftStakingRewardsInstance.getBalanceOf(address(0xD7C20d7178AA5c47C890dF272f449c902731b411)), 2);
        vm.warp(block.timestamp + 86400 * 30);
        nftStakingRewardsInstance.getReward();
        console.log("0xD7C20d7178AA5c47C890dF272f449c902731b411: ", trendToken.balanceOf(address(0xD7C20d7178AA5c47C890dF272f449c902731b411)));
        assertTrue(trendToken.balanceOf(0xD7C20d7178AA5c47C890dF272f449c902731b411) > 0);

        nftStakingRewardsInstance.withdraw(0);
        nftStakingRewardsInstance.withdraw(1);
        assertEq(nftStakingRewardsInstance.getBalanceOf(address(0xD7C20d7178AA5c47C890dF272f449c902731b411)), 0);
        assertEq(trendMasterNFT.balanceOf(address(0xD7C20d7178AA5c47C890dF272f449c902731b411)), 2);

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