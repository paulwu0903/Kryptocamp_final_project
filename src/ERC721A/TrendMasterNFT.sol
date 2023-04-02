//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "../../lib/erc721a/contracts/ERC721A.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/Strings.sol";

import "../../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../ERC20/ITrendToken.sol";

contract TrendMasterNFT is ERC721A, Ownable, ReentrancyGuard{

    using Strings for uint256;

    //控制合約
    address private controller;
    //利息
    uint256 public dailyInterest;

    //TODO: 白名單地址要設定哪些來測試

    enum StakeState{
        STAKED, UNSTAKED
    }

    //質押資訊
    struct NFTStakedInfo{
        StakeState stakeState;
        uint256 startTime;
        uint256 stakedInterest;
    }

    //歷史質押總數（每日新增）
    struct TotalStakedNFTHistory{
        uint256 startTime;
        uint256[] dailyTotalStakedNFT;
    }

     //質押總數歷史
    TotalStakedNFTHistory public totalStakedNFTHistory;

    // address => tokenId => 質押資訊
    mapping (address => mapping(uint256 => NFTStakedInfo)) public nftStakedInfoMap;

    //質押總數
    uint256 public totalStakedNFT;

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
        uint8 whitelistMintLimit; //白名單帳號Mint數量限制
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

    ITrendToken public trendToken;

    //檢查是否超出最大供給量
    modifier checkOverMaxSupply(uint256 _quentity){
        require(totalSupply() + _quentity <= maxSupply, "Over the max supply.");
        _;
    }

    //是否為controller
    modifier onlyController {
        require(controller == msg.sender, "not controller.");
        _;
    }

    constructor (address _trendTokenAddress) ERC721A ("TrendMaster", "TM"){
        contractCreateTime = block.timestamp;
        whitelistMintParam.whitelistMintPrice = 50000000000000000; // 白名單售價0.05E
        maxSupply = 1000; //最大供給量
        isOpen = [false, false, false]; //分三批開盲
        openNum = [500, 300,200];

        dailyInterest = 200000000000000000000000;

        trendToken = ITrendToken(_trendTokenAddress);
    }


    //設定控制者
    function setController(address _controllerAddress) external onlyOwner{
        controller = _controllerAddress;
    } 

    //設定利息
    function setInterest(uint256 _interest) external onlyController{
        dailyInterest = _interest;
    }
    
    //設定白名單Merkle Tree樹根
    function setWhitelistMerkleTree(bytes32 _root) external onlyOwner{
        whitelistMintParam.whitelistMerkleTreeRoot = _root;
    }

    //驗證當下呼叫合約地址是否為白名單
    function verifyWhitelist(bytes32[] calldata _proof) private view returns(bool){
        bool isWhitelist = MerkleProof.verifyCalldata(_proof, whitelistMintParam.whitelistMerkleTreeRoot, keccak256(abi.encodePacked(msg.sender)));
        return isWhitelist;
    }

    //設定白名單mint上限數量
    function setWhielistlimit(uint8 _amount) external onlyOwner{
        whitelistMintParam.whitelistMintLimit = _amount;
    }
    modifier ownNFT(uint256 _tokenId){
        require(ownerOf(_tokenId) == msg.sender, "NFT is not yours.");
        _;
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


    //多付退款
    function remainRefund(uint256 _need, uint256 _pay) private {

        if (_need < _pay){
            (bool success, ) = msg.sender.call{value: (_pay - _need)}("");
            require(success, "Transaction Failed!");
        }
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

    //白名單Mint
    function whitelistMint(bytes32[] calldata _proof, uint256 _quantity) external payable nonReentrant checkOverMaxSupply(_quantity){
        require(verifyWhitelist(_proof), "You're not in whitelist.");
        require(_quantity <= whitelistMintParam.whitelistMintLimit, "Over whitelist mint limit.");
        require(_quantity * whitelistMintParam.whitelistMintPrice < msg.value, "ETH not enough.");

        _mint(msg.sender, _quantity);

        //若多支付，則退還給用戶
        remainRefund((_quantity * whitelistMintParam.whitelistMintPrice), msg.value);

    }

    //公售荷蘭拍
    function publicAuctionMint(uint256 _quantity)  external payable nonReentrant checkOverMaxSupply(_quantity) {
        require(msg.value > _quantity * getAuctionPrice(), "ETH not enough.");

        _mint(msg.sender, _quantity);

        //若多支付，則退還給用戶
        remainRefund(( _quantity * getAuctionPrice()), msg.value);
    }
    
    //質押
    function stakeNFT(uint256 _tokenId) external ownNFT(_tokenId){
        require(nftStakedInfoMap[msg.sender][_tokenId].stakeState == StakeState.UNSTAKED, "Already STAKED.");
        
        nftStakedInfoMap[msg.sender][_tokenId].stakeState = StakeState.STAKED;
        nftStakedInfoMap[msg.sender][_tokenId].startTime = block.timestamp;

        totalStakedNFT += 1;

    }

    //解除質押
    function unstakeNFT(uint256 _tokenId) external ownNFT(_tokenId){
        require( nftStakedInfoMap[msg.sender][_tokenId].stakeState == StakeState.STAKED, "Already UNSTAKED.");
        nftStakedInfoMap[msg.sender][_tokenId].stakeState = StakeState.UNSTAKED;

        uint256 currentInterest = calculateInterest(_tokenId);
        nftStakedInfoMap[msg.sender][_tokenId].stakedInterest += currentInterest;

        //用戶可以動用這筆利息的錢
        trendToken.transferFrom(address(this), address(msg.sender), currentInterest);
    } 

    //覆寫轉移方法
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId) 
    public 
    payable 
    override 
    {
        require( nftStakedInfoMap[msg.sender][tokenId].stakeState == StakeState.UNSTAKED, "NFT is STAKED.");
        safeTransferFrom(from, to, tokenId, '');
    }

    //每日更新歷史總幣量（給前端定期呼叫）
    function updateTotalStakedTokenHistory() external onlyOwner{
        totalStakedNFTHistory.dailyTotalStakedNFT.push(totalStakedNFT);
    }

    //取得分多少利息
    function calculateInterest(uint256 _tokenId) public  view returns (uint256){

        uint256 startIndex = ((nftStakedInfoMap[msg.sender][_tokenId].startTime - totalStakedNFTHistory.startTime) / 86400) + 1;
        uint256 totalReward = 0;
        
        for(uint256 i=startIndex ; i< totalStakedNFTHistory.dailyTotalStakedNFT.length; i++){
            totalReward += (dailyInterest / totalStakedNFTHistory.dailyTotalStakedNFT[i]);
        }

        return totalReward;
    }


}