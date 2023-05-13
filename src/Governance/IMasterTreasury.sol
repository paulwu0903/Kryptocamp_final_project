//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IMasterTreasury{

    function addOwner(address _newMember) external;
    function removeOwner(address _removeMember) external;
    function setTxRequireConfirmedNum(uint256 _threshold) external;
    function getOwner() external view returns(address[] memory);
    function addBalance(uint256 _amount) external;
    function getTxRequireConfirmedNum() external view returns(uint256);

    function submitTransaction(
        uint256 _txType,
        address[] memory _path,
        uint256 _value,
        bytes memory _data
    ) external;
    function getTransaction(uint256 _txIndex) 
        external
        view  
        returns(
            uint256 txType,
            address[] memory path,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 confirmedNum);
    function confirmTransaction(uint256 _txIndex) external;
    function executeTransaction(uint256 _txIndex) external;
    function getTransactionCount() external view returns(uint256);
    function revokeTransactionConfirmed(uint256 _txIndex) external;
    function getInvestmentETHValue(address _tokenAddress) external view returns(uint256);
    function getInvestmentAmount(address _tokenAddress) external view returns(uint256);
    function getRewardContracts() external view returns(address[] memory);
    function getInvestments() external view returns(address[] memory);

    
}