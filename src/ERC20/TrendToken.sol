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
    uint256 public whitelistNum;

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

    //質押細項
    struct Stake {
        uint256 amount;  
        uint256 startTime;
    }

    //質押資訊
    struct TokenStakedInfo{
        uint256 totalStaked; //總質押幣量
        uint256 stakedNum; //總質押筆數
        uint256 stakedInterest; //總質押利息
        Stake[] stakes;
    }

    //歷史質押總數（每日新增）
    struct TotalStakedTokenHistory{
        uint256 startTime;
        uint256[] dailyTotalStakedToken;
    }

    bytes32 public whitelistMerkleTreeRoot; //白名單Merkle Tree Root

    //質押總數歷史
    TotalStakedTokenHistory public totalStakedTokenHistory;
    //代幣分配
    Distribution public distribution; 

    //address =>  質押資訊
    mapping (address => TokenStakedInfo) public stakeInfoMap;

    
    //質押總數
    uint256 public totalStakedToken;
    

    //利息
    uint256 public dailyInterest;

    //是否為controller
    modifier onlyController {
        require(controller == msg.sender, "not controller.");
        _;
    }

    modifier stakedToken{
        require(stakeInfoMap[msg.sender].stakedNum > 0, "no staked token.");
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
        whitelistNum = 0;
        decimals_ = _decimals;
        maxSupply = 1000000000 ;
        tokenPrice = 10000 gwei;
        dailyInterest = 170000;
        totalStakedToken = 0;
        totalStakedTokenHistory.startTime = block.timestamp;
    }

    //設定白名單總數
    function setWhitelistNum(uint256 _whitelistNum) external onlyOwner{ 
        whitelistNum = _whitelistNum;
    }
    
    //設定控制者
    function setController(address _controllerAddress) external onlyOwner{
        controller = _controllerAddress;
    } 

    //設定利息
    function setInterest(uint256 _interest) external onlyController{
        dailyInterest = _interest;
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
    function publicMint(uint256 _amount) external nonReentrant payable{
        require(msg.value >= tokenPrice * _amount, "ETH not enough!!"); //判斷支付費用是否足夠
        require(_amount <= distribution.publicMint.max_amount - distribution.publicMint.current_amount, "Tokens for public Mint are not enough."); //代幣數量是否足夠
        
        distribution.publicMint.current_amount += _amount;
        _mint(msg.sender, _amount); 

        remainRefund(( tokenPrice * _amount), msg.value);
    }

    //執行代幣分配
    function tokenDistribute() external onlyOwner {

        // 執行國庫代幣分配
        initMint(address(distribution.treasury.target), distribution.treasury.max_amount);
        //執行Token質押代幣分配
        initMint(address(this), distribution.tokenStakeInterest.max_amount);
        //執行空投代幣分配
        initMint(address(this), distribution.airdrop.max_amount);
        //執行顧問代幣分配
        initMint(address(distribution.consultant.target), distribution.consultant.max_amount);
        //執行nft質押代幣分配
        initMint(address(distribution.nftStakeInterest.target), distribution.nftStakeInterest.max_amount);
        //執行公售代幣分配
        initMint(address(distribution.publicMint.target), distribution.publicMint.max_amount);
    }

    //質押
    function stakeToken(uint256 _stakeAmount) external {
        require(balanceOf(msg.sender) - stakeInfoMap[msg.sender].totalStaked >= _stakeAmount, "token not enough");
        require(block.timestamp < totalStakedTokenHistory.startTime + (86400 * 365 * 4), "stake-mechanism was closed.");
        stakeInfoMap[msg.sender].stakes.push(
            Stake(
                {
                    amount: _stakeAmount,
                    startTime: block.timestamp
                }
            )
        );
        stakeInfoMap[msg.sender].totalStaked += _stakeAmount;
        stakeInfoMap[msg.sender].stakedNum += 1 ;
        stakeInfoMap[msg.sender].stakedInterest = 0;

        totalStakedToken += _stakeAmount;


    }

    //非質押餘額查看
    function unstakeBalanceOf() public view returns (uint256) {
        return balanceOf(msg.sender) - stakeInfoMap[msg.sender].totalStaked;
        
    }

    //override轉錢功能
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(amount <= unstakeBalanceOf(), "unstaked tokens are not enough.");
        (bool success, ) = address(to).call{value: amount}("");
        return success;
    }

     //解除質押，取得質押利息
    function unstakeToken(uint256 _stakedIndex) external nonReentrant stakedToken{
        uint256 currentInterest = calculateInterest(_stakedIndex);

        //質押資訊調整
        stakeInfoMap[msg.sender].totalStaked -= stakeInfoMap[msg.sender].stakes[_stakedIndex].amount;
        

        for(uint256 i=_stakedIndex ; i < stakeInfoMap[msg.sender].stakes.length-1; i++){
            stakeInfoMap[msg.sender].stakes[i] = stakeInfoMap[msg.sender].stakes[i+1];
        }
        delete stakeInfoMap[msg.sender].stakes[stakeInfoMap[msg.sender].stakes.length -1];
        stakeInfoMap[msg.sender].stakes.pop();

        stakeInfoMap[msg.sender].stakedNum -= 1 ;
        stakeInfoMap[msg.sender].stakedInterest += currentInterest;

        distribution.tokenStakeInterest.current_amount += currentInterest;

        (bool success, ) = address(msg.sender).call{value: currentInterest}("");
        require(success, "Transaction Error!!");

    }

     //取得分多少利息
    function calculateInterest(uint256 _stakedIndex) public stakedToken view returns (uint256){
        
        uint256 startIndex = ((stakeInfoMap[msg.sender].stakes[_stakedIndex].startTime - totalStakedTokenHistory.startTime) / 86400) + 1;
        uint256 totalReward = 0;
        
        for(uint256 i=startIndex ; i< totalStakedTokenHistory.dailyTotalStakedToken.length; i++){
            totalReward += ((dailyInterest * stakeInfoMap[msg.sender].stakes[_stakedIndex].amount) / totalStakedTokenHistory.dailyTotalStakedToken[i]);
        }

        return totalReward;
    }

     //每日更新歷史總幣量（給前端定期呼叫）
    function updateTotalStakedTokenHistory() external onlyOwner{
        totalStakedTokenHistory.dailyTotalStakedToken.push(totalStakedToken);
    }

    //設定白名單Merkle Tree樹根
    function setWhitelistMerkleTree(bytes32 _root) external onlyOwner{
        whitelistMerkleTreeRoot = _root;
    }

    //驗證當下呼叫合約地址是否為白名單
    function verifyWhitelist(bytes32[] calldata _proof) public view returns(bool){
        bool isWhitelist = MerkleProof.verifyCalldata(_proof, whitelistMerkleTreeRoot, keccak256(abi.encodePacked(msg.sender)));
        return isWhitelist;
    }

    //發放空投，用戶自取
    function sendAirdrop(bytes32[] calldata _proof) external nonReentrant{

        require(whitelistNum != 0, "airdrop is not ready!");
        bool isWhitelist = verifyWhitelist(_proof);
        require(isWhitelist, "not in whitelist.");

        uint256 airdropTokens = distribution.airdrop.max_amount / whitelistNum;

        distribution.airdrop.current_amount += airdropTokens;

        (bool success, ) = address(msg.sender).call{value: airdropTokens }("");
        require(success, "Transaction failed.");
        
    }

    function getController() external view returns (address){
        return controller;
    }

    function getWhitelistNum() external view returns (uint256){
        return whitelistNum;
    }

    function initMint(address _addr, uint256 _amount) private {
        _mint(_addr, _amount); 
    } 
    
    function stakedBalanceOf(address _addr) external view returns(uint256) {
        return stakeInfoMap[_addr].totalStaked;
    }


}  