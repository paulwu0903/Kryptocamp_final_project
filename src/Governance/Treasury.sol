//SPDX-license-Identifier
pragma solidity >=0.8.17;

contract Treasury{

    //控制國庫規範的參數
    struct Rule{
        uint256 requireConfirmedNum;
    }
    
    address[] public owner; //國庫共同經營者
    mapping(address => bool) isOwner; //判定是否為國庫經營者的map

    


    
}