// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "../ERC20/ITrendToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../Governance/ITreasury.sol";



contract TokenAirdrop is Ownable{

    ITrendToken public airdropToken;
    bytes32 public whitelistMerkleTreeRoot; //白名單Merkle Tree Root
    uint256 public whitelistNum;

    bool isOpenDonate = false;
    bool isOpenAirdrop = false;
    

    mapping (address => bool) isDonate;

    event AirdropToken(address indexed _receiver, uint256 indexed _amount);

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

    function getAirdropRewards() private view returns(uint256 rewards){
        uint256 totalTokens = airdropToken.balanceOf(address(this));
        rewards = totalTokens / whitelistNum;
    }

    function getAirdrop(bytes32[] calldata _proof) external verifiyProof(_proof){
        require(isOpenAirdrop, "not open airdrop.");
        uint256 rewards = getAirdropRewards();
        airdropToken.transfer(msg.sender, rewards);
        emit AirdropToken(msg.sender, rewards);

    }
    function setTrendTokenAddress(address _trendTokenAddress)external onlyOwner{
        airdropToken = ITrendToken(_trendTokenAddress);
    } 

    function openAirdrop() external onlyOwner{
        require(!isOpenAirdrop, "already open airdrop");
        isOpenAirdrop = true;
    }

    function openDonate() external onlyOwner{
        require(!isOpenDonate, "already open donate");
        isOpenDonate = true;
    }

    function donate() external payable{
        require(isOpenDonate, "not open donate.");
        require(whitelistNum < 100, "u are not the top 100 address.");
        require(msg.value == 1 ether, "just 1 ETH!");
        require(isDonate[msg.sender] == false, "already donate");
        whitelistNum++;
        isDonate[msg.sender] = true;
    }

    function transferBalanceToTreasury(address _treasuryAddress) external onlyOwner{
        ITreasury treasury = ITreasury(_treasuryAddress);
        treasury.addBalance(address(this).balance);
        payable(_treasuryAddress).transfer(address(this).balance);
    }

}