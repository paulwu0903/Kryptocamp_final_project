// SPDX-License-Identifier: MIT
pragma solidity ^0.8;




interface ITokenAirdrop {
    //設定白名單Merkle Tree樹根
    function setWhitelistMerkleTree(bytes32 _root) external;

    function setWhitelistNum(uint256 _whitelistNum) external;
    

    function getAirdrop(bytes32[] calldata _proof) external;

}