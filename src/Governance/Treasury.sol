//SPDX-license-Identifier
pragma solidity >=0.8.17;


contract Treasury{

    //交易通過所需的確認數
    uint256 requireConfirmedNum;
    
    
    address[] public owners; //國庫共同經營者
    mapping(address => bool) isOwner; //判定是否為國庫經營者的map

    struct Transaction{
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmedNum;
    }

    //tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) isComfirmed;

    Transaction[] public transactions;

    modifier onlyOwner(){
        require(isOwner[msg.sender], "not owner.");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "Tx does not exist.");
        _;
    }

    modifier notExecuted (uint256 _txIndex){
        require(!transactions[_txIndex].executed, "Tx already existd.");
        _;
    }

    modifier notConfirmed(uint256 _txIndex){
        require(isComfirmed[_txIndex][msg.sender], "tx already confirmed.");
        _;
    }

    constructor (address[] memory _owners){
        require(_owners.length > 0, "owners required");
        
        //確認地址數預設為半數＋1
        requireConfirmedNum = (_owners.length / 2) +1;

        //初始化owners 和 isOwner map;
        for (uint256 i = 0 ; i< _owners.length; i++){
            address owner = owners[i];
            require(owner != address(0), "invalid owner.");
            require(!isOwner[owner], "owner not unique.");
            
            isOwner[owner] = true;
            owners.push(owner);
        }

    }

    receive() external payable{ }

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

    function confirmTransaction(uint256 _txIndex) 
        external 
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.confirmedNum ++;
        isComfirmed[_txIndex][msg.sender] = true;

    }

    function executeTransaction(uint256 _txIndex)
        external 
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(transaction.confirmedNum >= requireConfirmedNum, "can not execute tx.");

        transaction.executed = true;

        (bool success, ) =address(transaction.to).call{value: transaction.value}(transaction.data);
        require(success, "tx failed!");
    }

    function revokeConfirmed(uint256 _txIndex)
        external 
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        require(isComfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.confirmedNum --;
        isComfirmed[_txIndex][msg.sender] = false;
    }

    function getOwner() external view returns(address[] memory){
        return owners;
    }

    function getTransactionCount() external view returns(uint256){
        return transactions.length;
    }

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