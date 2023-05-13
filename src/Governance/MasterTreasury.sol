//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../Invest/IUniswapV2Invest.sol";
import "../ERC721A/ITrendMasterNFT.sol";
import "../Invest/RevenueRewardsSharedByNFTs.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract MasterTreasury{

    //交易通過所需的確認數
    uint256 txRequireConfirmedNum;
    
    address[] public owners; //國庫共同經營者
    mapping(address => bool) isOwner; //判定是否為國庫經營者的map

    // token address => ETH value 
    mapping (address => uint256) investingETHValue;
    // token address => amount
    mapping (address => uint256) investingTokenAmount;

    uint256 public treasuryBalance;

    address[] public investments;
    address[] public rewardsContract;

    IUniswapV2Invest public uniswapV2Invest;
    ITrendMasterNFT public trendMasterNFT;


    enum TransactionType{
        BUY,
        SALE
    }

    //交易結構
    struct Transaction{
        TransactionType txType;
        address[] path;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmedNum;
    }

    //tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) txIsComfirmed;

    Transaction[] public transactions;

    event AddNewOwner(address _newMember);
    event RemoveOwner(address _member);
    event SubmitTransaction(address _proposer, uint256 _txType, address[] _path, uint256 _value, bytes _data);
    event ConfirmTransaction(address _account, uint256 _txIndex);
    event ExecuteTransaction(address executer, TransactionType _txType, address[] _path, uint256 _value, bytes _data, bool _execute, uint256 _confirmedNum);
    event RevokeTransactionConfirmed(address _revoker, uint256 _txIndex);
    event GetOwner(address[] _owners);
    event GetTransactionCount(uint256 _amount);
    event GetTransaction(TransactionType _txType, address[] _path, uint256 _value, bytes data, bool _executed, uint256 _confirmedNum);
    event MasterTreasuryOriginalBalance(uint256 _balance);
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


    constructor (address[] memory _owners, address _uniswap, address _nft){
        require(_owners.length > 0, "owners required");

        uniswapV2Invest = IUniswapV2Invest(_uniswap);
        trendMasterNFT = ITrendMasterNFT(_nft);
        
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
        isOwner[_removeMember] = false;
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
        bytes memory _data
    ) external onlyOwner{
        //uint256 txIndex = transactions.length;
        if (_txType == 1){
            require(investingTokenAmount[_path[0]] != 0, "have no this investment.");
        }

        transactions.push(
            Transaction({
                txType: getTxType(_txType),
                path: _path,
                value: _value,
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
        txNotExecuted(_txIndex)
    {
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

            uniswapV2Invest.swapExactTokensForETH(transaction.value, 0, transaction.path);
            uint256 receivedETH = address(this).balance - originalBalance; //賣幣後ETH與賣幣前的差額 = 賣幣拿回的ETH
            uint256 standardETH = (investingETHValue[targetToken] * transaction.value) / investingTokenAmount[targetToken];
            if (receivedETH > standardETH){
                uint256 revenue = receivedETH - standardETH;
                //開啟分潤合約
                RevenueRewardsSharedByNFTs revenueRewardsSharedByNFTs = new RevenueRewardsSharedByNFTs{value: revenue}(address(trendMasterNFT));
                rewardsContract.push(address(revenueRewardsSharedByNFTs));
            }else{
                //賠錢賣，暫不做事
            }

            if (uniswapV2Invest.getTokenBalance(targetToken) == 0){
                investingTokenAmount[targetToken] =0;
                investingETHValue[targetToken] =0;
                removeInvestment(targetToken);
            }
        }

        emit ExecuteTransaction(msg.sender, transaction.txType, transaction.path, transaction.value, transaction.data, transaction.executed, transaction.confirmedNum);

    }

    //撤回交易確認
    function revokeTransactionConfirmed(uint256 _txIndex)
        external 
        onlyOwner
        txExists(_txIndex)
        txNotExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(txIsComfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.confirmedNum --;
        txIsComfirmed[_txIndex][msg.sender] = false;

        emit RevokeTransactionConfirmed(msg.sender, _txIndex);
    }

    //取得owner集合
    function getOwner() external view returns(address[] memory){
        return owners;
    }


    //取得交易數量
    function getTransactionCount() external view returns(uint256){
        uint256 amount = transactions.length;
        return amount;
    }

    

    //取得交易資訊
    function getTransaction(uint256 _txIndex) 
        external  
        view
        returns(
            TransactionType,
            address[] memory,
            uint256,
            bytes memory,
            bool,
            uint256
            )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.txType,
            transaction.path,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.confirmedNum
        );
    }


    function addBalance(uint256 _amount) external {
        require(address(msg.sender) == address(trendMasterNFT), "Only Trend Master NFT Contract can give ethers.");
        treasuryBalance += _amount;
        emit MasterTreasuryOriginalBalance(treasuryBalance);
    }
    function getInvestmentAmount(address _tokenAddress) external view returns(uint256){
        uint256 amount = investingTokenAmount[_tokenAddress];
        return amount;
    }

    function getInvestmentETHValue(address _tokenAddress) external view returns(uint256){
        uint256 value = investingETHValue[_tokenAddress];
        return value;
    }

    function getRewardContracts() external view returns(address[] memory){
        return rewardsContract;
    }
    function getTxRequireConfirmedNum() external view returns(uint256){
        return txRequireConfirmedNum;
    }

    function getTxType(uint256 _index) private pure returns(TransactionType txType ){
        if (_index == 0){
            txType = TransactionType.BUY;
        }else if (_index == 1){
            txType = TransactionType.SALE;
        }
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

    function setUniswapInvestAddress(address _uniswapInvestAddress) external onlyOwner {
        uniswapV2Invest = IUniswapV2Invest(_uniswapInvestAddress);
    }

    function setTrendMasterAddress(address _trendMasterAddress) external onlyOwner {
        trendMasterNFT = ITrendMasterNFT(_trendMasterAddress);
    }

    function getAllTransactions() external view returns (Transaction[] memory){
        return transactions;
    }
    
    function getInvestments() external view returns(address[] memory){
        return investments;
    }

}