//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ITreasury{

    function addOwner(address _newMember) external;
    function removeOwner(address _removeMember) external;
    function setTxRequireConfirmedNum(uint256 _threshold) external;
    function getOwner() external view returns(address[] memory);
    

    
}