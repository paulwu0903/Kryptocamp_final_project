//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../Invest/IUniswapV2Invest.sol";
import "../ERC20/ITrendToken.sol";
import "../Invest/RevenueRewardsSharedByTokens.sol";
import "../Stake/ITokenStakingRewards.sol";
import "../Stake/INFTStakingRewards.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Treasury{

    //交易通過所需的確認數
    uint256 txRequireConfirmedNum;
    IUniswapPair public uniswapPair;
    address[] public owners; //國庫共同經營者
    mapping(address => bool) isOwner; //判定是否為國庫經營者的map

    IUniswapV2Invest public uniswapV2Invest;
    ITrendToken public trendToken;
    ITokenStakingRewards public tokenStakingRewards;
    INFTStakingRewards public nftStakingRewards;

    // token address => ETH value 
    mapping (address => uint256) investingETHValue;
    // token address => amount
    mapping (address => uint256) investingTokenAmount;

    uint256 public treasuryBalance;
    address[] public rewardsContract;

    address[] public investments;

    uint256 liquidityTokensAmount = 0;
    uint256 liquidityETHAmount = 0;
    uint256 liquidity = 0;

    enum TransactionType{
        BUY, //投資
        SALE,//出售
        ADD,//添增流動性
        REMOVE, //移除流動性
        CREATE //建立流動池
    }

    //交易結構
    struct Transaction{
        TransactionType txType;
        address[] path;
        uint256 value;
        uint256 amount;
        bytes data;
        bool executed;
        uint256 confirmedNum;
    }

    //tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) txIsComfirmed;

    Transaction[] public transactions;
    bool isCreatePool = false;

    event AddNewOwner(address _newMember);
    event RemoveOwner(address _member);
    event SubmitTransaction(address _proposer, uint256 _txType, address[] _path, uint256 _value, bytes _data);
    event ConfirmTransaction(address _account, uint256 _txIndex);
    event ExecuteTransaction(address executer, TransactionType _txType, address[] _path, uint256 _value, bytes _data, bool _execute, uint256 _confirmedNum);
    event RevokeTransactionConfirmed(address _revoker, uint256 _txIndex);
    event GetOwner(address[] _owners);
    event GetTransactionCount(uint256 _amount);
    event GetTransaction(TransactionType _txType, address[] _path, uint256 _value, bytes data, bool _executed, uint256 _confirmedNum);
    event TreasuryOriginalBalance(uint256 _balance);
    event GetRewardContracts(address[] _contract);
    event GetTxRequireConfirmedNum(uint256 txRequireConfirmedNum);
    event GetInvestmentAmount(uint256 amount);
    event GetInvestmentETHValue(uint256 _value);

    //判定是否為owner集合
    modifier onlyOwner(){
        require(isOwner[msg.sender], "not owner.");
        _;
    }

    //判定交易是否矬在
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Tx does not exist.");
        _;
    }

    //判定交易是否尚未執行
    modifier txNotExecuted (uint256 _txIndex){
        require(!transactions[_txIndex].executed, "Tx already existd.");
        _;
    }

    //判定用戶是否尚未確認過
    modifier txNotConfirmed(uint256 _txIndex){
        require(!txIsComfirmed[_txIndex][msg.sender], "tx already confirmed.");
        _;
    }


    constructor (address[] memory _owners, address _uniswap, address _token, address _stakingNFT, address _stakingToken){
        require(_owners.length > 0, "owners required");

        uniswapV2Invest = IUniswapV2Invest(_uniswap);
        trendToken = ITrendToken(_token);
        tokenStakingRewards = ITokenStakingRewards(_stakingToken);
        nftStakingRewards = INFTStakingRewards(_stakingNFT);
        
        //交易確認地址數預設為半數＋1
        txRequireConfirmedNum = (_owners.length / 2) +1;


        //初始化owners 和 isOwner map;
        for (uint256 i = 0 ; i< _owners.length; i++){
            address owner = _owners[i];
            require(owner != address(0), "invalid owner.");
            require(!isOwner[owner], "owner not unique.");
            
            isOwner[owner] = true;
            owners.push(owner);
        }

    }

    //新增owner
    function addOwner(address _newMember) external {
        require(_newMember != address(0), "invalid owner.");
        require(!isOwner[_newMember], "owner not unique.");
        owners.push(_newMember);
        isOwner[_newMember] = true;
        txRequireConfirmedNum = (owners.length /2) +1;

         emit AddNewOwner(_newMember);
    }

    //移除owner
    function removeOwner(address _removeMember) external{
        require(isOwner[_removeMember], "not a member.");
        
        //TODO: 待優化
        for(uint256 i=0; i< owners.length; i++){
            if (owners[i] == _removeMember ){
                delete owners[i];
                for(uint256 j=i; j < owners.length-1; j++ ){
                    owners[j] = owners[j+1];
                }
                owners.pop();
                break;
            }
        }
        txRequireConfirmedNum = (owners.length /2) +1;

        emit RemoveOwner(_removeMember);
    }

    //設定簽章數量門檻
    function setTxRequireConfirmedNum(uint256 _threshold) external {
        txRequireConfirmedNum = _threshold;
    }

    receive() external payable{ 
    }
    fallback() external payable{ 
    }

    //發送交易
    function submitTransaction(
        uint256 _txType,
        address[] memory _path,
        uint256 _value,
        uint256 _amount,
        bytes memory _data
    ) external onlyOwner{
        //uint256 txIndex = transactions.length;
        if (_txType == 1){
            require(investingTokenAmount[_path[0]] != 0, "have no this investment.");
        }
        if (_txType == 4){
            require(!isCreatePool, "already create pool.");
            isCreatePool = true;
        }

        transactions.push(
            Transaction({
                txType: getTxType(_txType),
                path: _path,
                value: _value,
                amount: _amount,
                data: _data,
                executed: false,
                confirmedNum: 0
            })
        );
        emit SubmitTransaction(msg.sender, _txType, _path, _value, _data);
    }

    //確認交易
    function confirmTransaction(uint256 _txIndex) 
        external 
        onlyOwner
        txExists(_txIndex)
        txNotExecuted(_txIndex)
        txNotConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.confirmedNum ++;
        txIsComfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);

    }

    //執行交易
    function executeTransaction(uint256 _txIndex)
        external 
        onlyOwner
        txExists(_txIndex)
        txNotExecuted(_txIndex){
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.confirmedNum >= txRequireConfirmedNum, "can not execute tx.");

        transaction.executed = true;

        if (transaction.txType == TransactionType.BUY){
            address targetToken = transaction.path[transaction.path.length-1];
            investingETHValue[targetToken] += transaction.value;
            investments.push(targetToken);
            uniswapV2Invest.swapExactETHForTokens{value: transaction.value}(0, transaction.path);
            investingTokenAmount[targetToken] = uniswapV2Invest.getTokenBalance(targetToken);
        }else if(transaction.txType == TransactionType.SALE) {
            address targetToken = transaction.path[0];
            uint256 originalBalance = address(this).balance; //賣幣前ETH

            IERC20(targetToken).approve(address(uniswapV2Invest), investingTokenAmount[targetToken]);

            uniswapV2Invest.swapExactTokensForETH(transaction.amount, 0, transaction.path);
            uint256 receivedETH = address(this).balance - originalBalance; //賣幣後ETH與賣幣前的差額 = 賣幣拿回的ETH
            uint256 standardETH = (investingETHValue[targetToken] * transaction.amount) / investingTokenAmount[targetToken];
            if (receivedETH > standardETH){
                uint256 revenue = receivedETH - standardETH;
                //開啟分潤合約
                uint256 snapshotId = trendToken.snapshot();
                RevenueRewardsSharedByTokens revenueRewardsSharedByTokens = new RevenueRewardsSharedByTokens{value: revenue}(address(trendToken), address(tokenStakingRewards),address(nftStakingRewards), snapshotId);
                rewardsContract.push(address(revenueRewardsSharedByTokens));
            }else{
                //賠錢賣，暫不做事
            }

            if (uniswapV2Invest.getTokenBalance(targetToken) == 0){
                investingTokenAmount[targetToken] =0;
                investingETHValue[targetToken] =0;
                removeInvestment(targetToken);
            }

        }else if (transaction.txType == TransactionType.ADD){
            trendToken.approve(address(uniswapV2Invest), transaction.amount);
            (uint amountToken, uint amountETH, uint liquidityToken) = uniswapV2Invest.addTrendTokenLiquidityETH{value: transaction.value}(transaction.amount,0,0);
            liquidityETHAmount += amountETH;
            liquidityTokensAmount += amountToken;
            liquidity += liquidityToken;
        }else if (transaction.txType == TransactionType.REMOVE){
            uniswapPair.approve(address(uniswapV2Invest), transaction.amount);
            // amount為liquility量
            (uint amountToken, uint amountETH) = uniswapV2Invest.removeTrendTokenLiquidityETH(transaction.amount,0,0);
            uint256 originETH = (liquidityETHAmount * transaction.amount) / liquidity; //原放進去ETH
            liquidity -= transaction.amount;
            liquidityETHAmount -= amountETH;
            liquidityTokensAmount -= amountToken;
            if (amountETH > originETH){
                uint256 revenue = amountETH - originETH;
                //開啟分潤合約
                uint256 snapshotId = trendToken.snapshot();
                RevenueRewardsSharedByTokens revenueRewardsSharedByTokens = new RevenueRewardsSharedByTokens{value: revenue}(address(trendToken), address(tokenStakingRewards),address(nftStakingRewards), snapshotId);
                rewardsContract.push(address(revenueRewardsSharedByTokens));
            }else{
                //認賠不做事
            }
        }else if (transaction.txType == TransactionType.CREATE){
            uniswapPair = IUniswapPair(uniswapV2Invest.createPool());
        }
        emit ExecuteTransaction(msg.sender, transaction.txType, transaction.path, transaction.value, transaction.data, transaction.executed, transaction.confirmedNum);

    }

    //撤回交易確認
    function revokeTransactionConfirmed(uint256 _txIndex)
        external 
        onlyOwner
        txExists(_txIndex)
        txNotExecuted(_txIndex){
        Transaction storage transaction = transactions[_txIndex];
        require(txIsComfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.confirmedNum --;
        txIsComfirmed[_txIndex][msg.sender] = false;

        emit RevokeTransactionConfirmed(msg.sender, _txIndex);
    }

    //取得owner集合
    function getOwner() external returns(address[] memory){
        emit GetOwner(owners);
        return owners;
    }


    //取得交易數量
    function getTransactionCount() external returns(uint256){
        uint256 amount = transactions.length;
        emit GetTransactionCount(amount);
        return amount;
    }

    //取得交易資訊
    function getTransaction(uint256 _txIndex) 
        external  
        returns(
            uint256 txType,
            address[] memory path,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 confirmedNum
            )
    {
        Transaction storage transaction = transactions[_txIndex];
        emit GetTransaction(transaction.txType, transaction.path, transaction.value, transaction.data, transaction.executed, transaction.confirmedNum);


        return (
            txType,
            transaction.path,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.confirmedNum
        );
    }

    function addBalance(uint256 _amount) external {
        require(address(msg.sender) == address(trendToken), "Only Trend Master NFT Contract can give ethers.");
        treasuryBalance += _amount;
        emit TreasuryOriginalBalance(treasuryBalance);
    }

    function getRewardContracts() external returns(address[] memory){
        emit GetRewardContracts(rewardsContract);
        return rewardsContract;
    }

    function getTxRequireConfirmedNum() external returns(uint256){
        emit GetTxRequireConfirmedNum(txRequireConfirmedNum);
        return txRequireConfirmedNum;
    }

    function getTxType(uint256 _index) private pure returns(TransactionType txType ){
        if (_index == 0){
            txType = TransactionType.BUY;
        }else if (_index == 1){
            txType = TransactionType.SALE;
        }else if (_index == 2){
            txType = TransactionType.ADD;
        }else if (_index == 3){
            txType = TransactionType.REMOVE;
        }else if (_index == 4){
            txType = TransactionType.CREATE;
        }else{
            revert();
        }
    }

    function getInvestmentAmount(address _tokenAddress) external returns(uint256){
        uint256 amount = investingTokenAmount[_tokenAddress];
        emit GetInvestmentAmount(amount);
        return amount;
    }

    function getInvestmentETHValue(address _tokenAddress) external returns(uint256){
        uint256 value = investingETHValue[_tokenAddress];
        emit GetInvestmentETHValue(value);
        return value;
    }

    function removeInvestment(address _target) private {
        for(uint256 i= 0; i < investments.length; i++){
            if (investments[i] == _target){
                delete investments[i];
                for (uint256 j= i; j < investments.length-1; j++){
                    investments[j] = investments[j+1];
                }
                investments.pop();
            }
        }
    }

    function setUniswapInvestAddress(address _uniswapInvestAddress) external onlyOwner{
        uniswapV2Invest = IUniswapV2Invest(_uniswapInvestAddress);
    }
    function setTrendTokenAddress(address _trendTokenAddress) external onlyOwner{
        trendToken = ITrendToken(_trendTokenAddress);
    }
    function setTokenStakingRewardsAddress(address _tokenStakingRewards) external onlyOwner{
        tokenStakingRewards = ITokenStakingRewards(_tokenStakingRewards);
    }

    function setNFTStakingRewardsAddress(address _nftStakingRewards) external onlyOwner{
        nftStakingRewards = INFTStakingRewards(_nftStakingRewards);
    }

    function getLiquility() external view returns(uint256){
        return liquidity;
    }

    function getLiquidityETHAmount() external view returns(uint256){
        return liquidityETHAmount;
    }

    function getLiquidityTokensAmount() external view returns(uint256){
        return liquidityTokensAmount;
    }
}
interface IUniswapPair {
  function balanceOf(address owner) external view returns (uint);
  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);
}