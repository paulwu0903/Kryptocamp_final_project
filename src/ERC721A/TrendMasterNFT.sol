//SPDX-license-Identifier
pragma solidity >=0.8.17;

import "../../lib/erc721a/contracts/ERC721A.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

contract TrendMasterNFT is ERC721A, Ownable{

    using Strings for uint256;

    //TODO: 白名單地址有哪些尚未完成


    //荷蘭拍參數定義
    struct Auction{
        uint256 startPrice;
        uint256 endPrice;
        uint256 priceStep;
        uint256 startTime;
        uint256 timeStep;
        uint256 timeStepNum;
    }

    struct WhitelistMintParam{
        uint256 whitelistMintTime; //白名單開賣時間
        uint256 whitelistMintPrice; //白名單售價
        bytes32 whitelistMerkleTreeRoot; //白名單Merkle Tree Root
    }

    //開盲參數
    bool[] isOpen = [false, false, false]; //分三批開盲
    uint256[] openNum = [500, 300, 200]; //各批開盲NFTs
    

    WhitelistMintParam public whitelistMintParam; //白名單相關參數
    Auction public auction; //荷蘭拍參數
    uint256 private maxSupply; //最大NFTs供給量
    
    uint8 openBlindPhase = 0;

    uint256 contractCreateTime;

    constructor () ERC721A ("TrendMaster", "TM"){
        contractCreateTime = block.timestamp;
        whitelistMintParam.whitelistMintPrice = 50000000000000000; // 白名單售價0.05E
        maxSupply = 1000; //最大供應量
        isOpen = [false, false, false]; //分三批開盲
        openNum = [500, 300,200];
    }

    
    //設定白名單Merkle Tree樹根
    function setWhitelistMerkleTree(bytes32 _root) external onlyOwner{
        whitelistMintParam.whitelistMerkleTreeRoot = _root;
    }

    //驗證當下呼叫合約地址是否為白名單
    function verifyWhitelist(bytes32[] calldata _proof) public view returns(bool){
        bool isWhitelist = MerkleProof.verifyCalldata(_proof, whitelistMintParam.whitelistMerkleTreeRoot, keccak256(abi.encodePacked(msg.sender)));
        return isWhitelist;
    }
    
    //設定荷蘭拍參數
    function setAuction(
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _priceStep,
        uint256 _startTime,
        uint256 _timeStep,
        uint256 _timeStepNum
    ) external onlyOwner{

        auction.startPrice = _startPrice;
        auction.endPrice + _endPrice;
        auction.priceStep = _priceStep;
        auction.startTime = _startTime;
        auction.timeStep = _timeStep;
        auction.timeStepNum = _timeStepNum;
    }
    //取得荷蘭拍參數
    function getAuctionInfo() external view returns(Auction memory){
        return auction;
    }

    //取得荷蘭拍當前NFT售價
    function getAuctionPrice() private view returns(uint256){

        if (block.timestamp <= auction.startTime){
            return auction.startPrice;
        }

      uint256 steps = (block.timestamp - auction.startTime) / auction.timeStep;

        if (steps > auction.timeStepNum){
            steps = auction.timeStepNum;
        }

      return auction.startPrice >= auction.priceStep * steps?
         auction.startPrice - (auction.priceStep * steps) : auction.endPrice;
    } 

    //開盲盒
    function openBlindbox() external onlyOwner{
        require(openBlindPhase < 3, "All NFT were opened!!");
        isOpen[openBlindPhase] = true;
        openBlindPhase++;
    }

    //設定NFT Base URI
    //TODO:baseURI網址尚未提供
    function _baseURI() internal pure override returns (string memory) {
        return '';
    }

    //設定token URI
    //TODO:return網址尚未完成
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721A: invalid token ID");

        string memory baseURI = _baseURI();

        if (isOpen[0] && tokenId < openNum[0]){
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "paulNFTMetadata_", tokenId.toString(), ".json")) : "";
        }else if (isOpen[1] && tokenId < (openNum[1] + openNum[0])){
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "paulNFTMetadata_", tokenId.toString(), ".json")) : ""; 
        }else if (isOpen[2] && tokenId < (openNum[2] + openNum[1] + openNum[0])){
            return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, "paulNFTMetadata_", tokenId.toString(), ".json")) : "";
        }else{
            return bytes(baseURI).length > 0 ? "https://gateway.pinata.cloud/ipfs/QmSy6wJPhTkqZ11UJVgRJDFey9vgw58pn3n6BVkAw83bjJ": "";
        }
    }

    //TODO: 白名單Mint function尚未實作
    //TODO: 荷蘭拍Mint function尚未實作
    //TODO: 質押 function 尚未實作
}
