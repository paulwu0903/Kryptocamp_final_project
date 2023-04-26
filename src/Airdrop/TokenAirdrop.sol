// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "../ERC20/ITrendToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";



contract TokenAirdrop is Ownable{

    ITrendToken public airdropToken;
    bytes32 public whitelistMerkleTreeRoot; //白名單Merkle Tree Root
    uint256 public whitelistNum;

    constructor (address _airdropToken){
        airdropToken = ITrendToken(_airdropToken);
    }

    //驗證當下呼叫合約地址是否為白名單
    modifier verifiyProof(bytes32[] calldata _proof){
        require(MerkleProof.verifyCalldata(_proof, whitelistMerkleTreeRoot, keccak256(abi.encodePacked(msg.sender))), "Invalid proof.");
        _;
    }

    //設定白名單Merkle Tree樹根
    function setWhitelistMerkleTree(bytes32 _root) external onlyOwner{
        whitelistMerkleTreeRoot = _root;
    }

    function setWhitelistNum(uint256 _whitelistNum) external onlyOwner{
        whitelistNum = _whitelistNum;
    }
    function getAirdropRewards() private view returns(uint256 rewards){
        uint256 totalTokens = airdropToken.balanceOf(address(this));
        rewards = totalTokens / whitelistNum;
    }

    function getAirdrop(bytes32[] calldata _proof) external verifiyProof(_proof){
        airdropToken.transfer(msg.sender, getAirdropRewards());

    }

}