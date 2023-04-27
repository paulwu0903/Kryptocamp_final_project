//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../Governance/ITreasury.sol";

contract TrendToken is ERC20Snapshot, Ownable, ReentrancyGuard{

    uint8 public decimals_; //精準度
    uint256 public immutable maxSupply = 1000000000 ether; //最大供給量
    uint256 public tokenPrice; //價格，單位: wei

    //控制合約
    address private controller;

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
   
    //代幣分配
    Distribution public distribution; 

    event TokenMaxSupply(uint256 indexed _maxSupply);
    event TokenTotalSupply(uint256 indexed _totalSupply);
    event PublicMintTokens(address _to, uint256 _amount);
    event Balance(address _account, uint256 _balance);
    event BalanceOfAt(address _account, uint256 _balance, uint256 _snapshotId);


    //是否為controller
    modifier onlyController {
        require(controller == msg.sender, "not controller.");
        _;
    }


    // 建構子初始化參數
    constructor (uint8 _decimals) 
                ERC20("TrendToken", "TREND"){
        decimals_ = _decimals;
        tokenPrice = 10000 gwei;
    }

    //設定代幣分配
    function setDistribution(
        address _treasuryAddress,
        uint256 _treasuryAmount,
        address _tokenStakeInterestAddress,
        uint256 _tokenStakeInterestAmount,
        address _consultantAddress,
        uint256 _consultantAmount,
        address _airdropAddress,
        uint256 _airdropAmount,
        address _nftStakeInterestAddress,
        uint256 _nftStakeInterestAmount,
        uint256 _publicMintAmount
    ) external onlyOwner{

        require((_treasuryAmount+ _tokenStakeInterestAmount+ _consultantAmount+ _airdropAmount+ _nftStakeInterestAmount+ _publicMintAmount) == maxSupply, "Distribution Error!");
        
        //設定國庫地址、代幣分配量
        distribution.treasury.target = _treasuryAddress;
        distribution.treasury.max_amount = _treasuryAmount;
        
        //TrendToken質押利息發放合約即為此合約
        distribution.tokenStakeInterest.target = address(_tokenStakeInterestAddress);
        distribution.tokenStakeInterest.max_amount = _tokenStakeInterestAmount;
        
        //設定顧問地址、代幣分配量
        distribution.consultant.target = _consultantAddress;
        distribution.consultant.max_amount = _consultantAmount;

        //空投合約即為此合約
        distribution.airdrop.target = address(_airdropAddress);
        distribution.airdrop.max_amount = _airdropAmount;
        
        //設定NFT質押利息發送合約地址、代幣分配量
        distribution.nftStakeInterest.target = _nftStakeInterestAddress;
        distribution.nftStakeInterest.max_amount = _nftStakeInterestAmount;

        //公售合約即為此合約
        distribution.publicMint.target = address(this);
        //設定公售代幣分配量
        distribution.publicMint.max_amount = _publicMintAmount;
        
    } 
    
    //設定控制者
    function setController(address _controllerAddress) external onlyOwner{
        controller = _controllerAddress;
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
    function getMaxSupply() external returns(uint256){
        emit TokenMaxSupply(maxSupply);
        return maxSupply;
    }

    //取得總供給量
    function getTotalSupply() external returns(uint256){
        uint256 tokenTotalSupply = totalSupply();
        emit TokenTotalSupply(tokenTotalSupply);
        return tokenTotalSupply;
    }

    //多付退款
    function remainRefund(uint256 _need, uint256 _pay) private {

        if (_need < _pay){
            (bool success, ) = msg.sender.call{value: (_pay - _need)}("");
            require(success, "Transaction Failed!");
        }
    }

    // mint功能，支付ETH購買
    function publicMint(uint256 _amount) external nonReentrant payable{
        require(msg.value >= tokenPrice * (_amount/ 1e18) , "ETH not enough!!"); //判斷支付費用是否足夠
        require(_amount <= distribution.publicMint.max_amount - distribution.publicMint.current_amount, "Tokens for public Mint are not enough."); //代幣數量是否足夠
        
        distribution.publicMint.current_amount += _amount;
        _mint(msg.sender, _amount); 

        emit PublicMintTokens(msg.sender, _amount);

        remainRefund(( tokenPrice * _amount), msg.value);
    }

    //執行代幣分配
    function tokenDistribute() external onlyOwner {
        // 執行國庫代幣分配
        initMint(address(distribution.treasury.target), distribution.treasury.max_amount);
        //執行Token質押代幣分配
        initMint(address(distribution.tokenStakeInterest.target), distribution.tokenStakeInterest.max_amount);
        //執行空投代幣分配
        initMint(address(distribution.airdrop.target), distribution.airdrop.max_amount);
        //執行顧問代幣分配
        initMint(address(distribution.consultant.target), distribution.consultant.max_amount);
        //執行nft質押代幣分配
        initMint(address(distribution.nftStakeInterest.target), distribution.nftStakeInterest.max_amount);
        //執行公售代幣分配
        initMint(address(distribution.publicMint.target), distribution.publicMint.max_amount);
    }

    function getController() external view returns (address){
        return controller;
    }

    function initMint(address _addr, uint256 _amount) private {
        _mint(_addr, _amount); 
    } 

    function transferBalanceToTreasury(address _treasuryAddress) external onlyOwner{
        ITreasury treasury = ITreasury(_treasuryAddress);
        treasury.addBalance(address(this).balance);
        payable(_treasuryAddress).transfer(address(this).balance);
    }

    function snapshot() public onlyOwner returns(uint256 snapshotId){
        snapshotId = _snapshot();
    }

    function getBalance(address _account) external returns (uint256){
        uint256 balance = balanceOf(_account);
        emit Balance(_account, balance);
        return balanceOf(_account);
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override(ERC20Snapshot){
        super._beforeTokenTransfer(from, to, amount);
    }

    function getBalanceOfAt(address _account, uint256 _snapshotId) external returns(uint256){
        uint256 balance = balanceOfAt(_account, _snapshotId);
        emit BalanceOfAt(_account, balance, _snapshotId );
        return balance;
    }

    
}  