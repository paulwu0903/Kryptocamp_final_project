//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../ERC20/TrendToken.sol";

contract TrendToken is ERC20, Ownable, ReentrancyGuard{

    uint8 public decimals_; //精準度
    uint256 public maxSupply; //最大供給量
    uint256 public tokenPrice; //價格，單位: wei

    //代幣分配各標的結構定義
    struct DistributionItem{
        address target; //分配地址
        uint256 max_amount; //總分配量
        uint256 current_amount; //當前釋出
    }

    //代幣分配
    struct Distribution{
        DistributionItem treasury; //國庫
        DistributionItem tokenStakeInterest; // TrendToken質押利息，即為本合約
        DistributionItem consultant; //顧問
        DistributionItem airdrop; //空投
        DistributionItem nftStakeInterest; // TrendMaster質押利息
        DistributionItem publicMint; //公售
    }

    
    Distribution public distribution; 


    //檢查是否超出最大供給量
    modifier checkOverMaxSupply(uint256 _amount){
        require(totalSupply() + _amount <= maxSupply, "Over the max supply.");
        _;
    }

    //設定代幣分配
    function setDistribution(
        address _treasury_address,
        uint256 _treasury_amount,
        uint256 _tokenStakeInterest_amount,
        address _consultant_address,
        uint256 _consultant_amount,
        uint256 _airdrop_amount,
        address _nftStakeInterest_address,
        uint256 _nftStakeInterest_amount,
        uint256 _publicMint_amount
    ) external onlyOwner{

        require((_treasury_amount+ _tokenStakeInterest_amount+ _consultant_amount+ _airdrop_amount+ _nftStakeInterest_amount+ _publicMint_amount) == maxSupply, "Distribution Error!");
        
        //設定國庫地址、代幣分配量
        distribution.treasury.target = _treasury_address;
        distribution.treasury.max_amount = _treasury_amount;
        
        //TrendToken質押利息發放合約即為此合約
        distribution.tokenStakeInterest.target = address(this);
        distribution.tokenStakeInterest.max_amount = _tokenStakeInterest_amount;
        
        //設定顧問地址、代幣分配量
        distribution.consultant.target = _consultant_address;
        distribution.consultant.max_amount = _consultant_amount;

        //空投合約即為此合約
        distribution.airdrop.target = address(this);
        distribution.airdrop.max_amount = _airdrop_amount;
        
        //設定NFT質押利息發送合約地址、代幣分配量
        distribution.nftStakeInterest.target = _nftStakeInterest_address;
        distribution.nftStakeInterest.max_amount = _nftStakeInterest_amount;

        //公售合約即為此合約
        distribution.publicMint.target = address(this);
        //設定公售代幣分配量
        distribution.publicMint.max_amount = _publicMint_amount;
        
    } 

    // 建構子初始化參數
    constructor (uint8 _decimals) 
                ERC20("TrendToken", "TREND"){
        decimals_ = _decimals;
        maxSupply = 1000000000;
        tokenPrice = 100000000000000;
    }

    //設定價格
    function setPrice(uint256 _price) external onlyOwner{
        tokenPrice = _price;
    }

    //取得精準度
    function decimals() public onlyOwner view override returns (uint8) {
        return decimals_;
    }

    //取得最大供給量
    function getMaxSupply() external view returns(uint256){
        return maxSupply;
    }

    //多付退款
    function remainRefund(uint256 _need, uint256 _pay) private {

        if (_need < _pay){
            (bool success, ) = msg.sender.call{value: (_pay - _need)}("");
            require(success, "Transaction Failed!");
        }
    }

    // mint功能，支付ETH購買
    function mint(uint256 _amount) external checkOverMaxSupply(_amount) payable{
        require(msg.value >= tokenPrice * _amount, "ETH not enough!!"); //判斷支付費用是否足夠
        _mint(msg.sender, _amount); 

        remainRefund(( tokenPrice * _amount), msg.value);
    }

    //執行代幣分配
    function tokenDistribute() external onlyOwner {

        // 空投、TrendToken質押利息、公售合約即為本合約，故不需要執行代幣轉移

        //國庫代幣分配
        (bool treasury_success, ) = address(distribution.treasury.target).call{value: distribution.treasury.max_amount}("");
        require(treasury_success, "Distrubuting tokens to the treasury contract address failed!");

        
        (bool tokenStakeInterest_success, ) = address(distribution.tokenStakeInterest.target).call{value: distribution.tokenStakeInterest.max_amount}("");
        require(tokenStakeInterest_success, "Distrubuting tokens to the token-stake contract address failed!");

        //顧問代幣分配
        (bool consultant_success, ) = address(distribution.consultant.target).call{value: distribution.consultant.max_amount}("");
        require(consultant_success, "Distrubuting tokens to the consultant address failed!");

        //TrendMaster質押代幣分配
        (bool nftStakeInterest_success, ) = address(distribution.nftStakeInterest.target).call{value: distribution.nftStakeInterest.max_amount}("");
        require(nftStakeInterest_success, "Distrubuting tokens to the nft-stake contract address failed!");
  
    }
}