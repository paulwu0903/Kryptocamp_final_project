//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;


contract Treasury{

    //交易通過所需的確認數
    uint256 txRequireConfirmedNum;
    
    address[] public owners; //國庫共同經營者
    mapping(address => bool) isOwner; //判定是否為國庫經營者的map

    //交易結構
    struct Transaction{
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmedNum;
    }

    //tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) txIsComfirmed;

    Transaction[] public transactions;

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
        require(txIsComfirmed[_txIndex][msg.sender], "tx already confirmed.");
        _;
    }


    constructor (address[] memory _owners){
        require(_owners.length > 0, "owners required");
        
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
    }

    //移除owner
    function removeOwner(address _removeMember) external{
        require(isOwner[_removeMember], "not a member.");
        
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
    }

    //設定簽章數量門檻
    function setTxRequireConfirmedNum(uint256 _threshold) external {
        txRequireConfirmedNum = _threshold;
    }

    receive() external payable{ }

    //發送交易
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyOwner{
        //uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                confirmedNum: 0
            })
        );
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

        (bool success, ) =address(transaction.to).call{value: transaction.value}(transaction.data);
        require(success, "tx failed!");
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
    }

    //取得owner集合
    function getOwner() external view returns(address[] memory){
        return owners;
    }


    //取得交易數量
    function getTransactionCount() external view returns(uint256){
        return transactions.length;
    }

    //取得交易資訊
    function getTransaction(uint256 _txIndex) 
        external 
        view 
        returns(
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 confirmedNum
            )
    {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.confirmedNum
        );
    }

}