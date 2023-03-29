//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

interface ITreasury{
    function addOwner(address _newMember) external;
    function removeOwner(address _removeMember) external;
    
}