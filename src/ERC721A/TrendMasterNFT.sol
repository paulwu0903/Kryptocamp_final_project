//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../Governance/IMasterTreasury.sol";

contract TrendMasterNFT is ERC721A, Ownable, ReentrancyGuard{

    using Strings for uint256;

    //控制合約
    address private controller;

    //TODO: 白名單地址要設定哪些來測試

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

    uint256 contractCreateTime;

    uint8 openBlindPhase = 0;

    event BalanceOf(address _account, uint256 _amount);
    event AuctionInfo(uint256 _startPrice, uint256 _endPrice, uint256 _priceStep, uint256 _startTime, uint256 _timeStep, uint256 _timeStepNum);
    event AuctionPrice(uint256 _price);
    event BlindboxPhrase(uint256 _openBlindPhase);
    event WhitelistMint(address _account,uint256 _price, uint256 _amount);
    event PublicMint(address _account, uint256 _price, uint256 _amount);
    event TokenURI(uint256 _tokenId, string uri);
    event Controller (address _controllerAddress);
    event TransferToTreasury(address _treasuryAddress, uint256 _value);
    event GetWhitelistMintPrice(uint256 _price);

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

    modifier ownNFT(uint256 _tokenId){
        require(ownerOf(_tokenId) == msg.sender, "NFT is not yours.");
        _;
    }

    constructor () ERC721A ("TrendMaster", "TM"){
        contractCreateTime = block.timestamp;
        whitelistMintParam.whitelistMintPrice = 500000000000000000; // 白名單售價0.5E
        maxSupply = 1000; //最大供給量
        isOpen = [false, false, false]; //分三批開盲
        openNum = [500, 300,200];
        whitelistMintParam.whitelistMintLimit = 4;
    }


    //設定控制者
    function setController(address _controllerAddress) external onlyOwner{
        controller = _controllerAddress;
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
    function getAuctionInfo() 
        external 
        returns(uint256, uint256, uint256, uint256, uint256, uint256){
        emit AuctionInfo(auction.startPrice, auction.endPrice, auction.priceStep, auction.startTime, auction.timeStep, auction.timeStepNum);
        return (auction.startPrice, auction.endPrice, auction.priceStep,  auction.startTime, auction.timeStep, auction.timeStepNum);
    }

    //取得荷蘭拍當前NFT售價
    function getAuctionPrice() public returns(uint256){

        if (block.timestamp <= auction.startTime){
            return auction.startPrice;
        }

      uint256 steps = (block.timestamp - auction.startTime) / auction.timeStep;

        if (steps > auction.timeStepNum){
            steps = auction.timeStepNum;
        }

        uint256 price = auction.startPrice >= auction.priceStep * steps?
         auction.startPrice - (auction.priceStep * steps) : auction.endPrice;

        emit AuctionPrice(price);

      return price;
    } 

    //開盲盒
    function openBlindbox() external onlyOwner{
        require(openBlindPhase < 3, "All NFT were opened!!");
        isOpen[openBlindPhase] = true;
        openBlindPhase++;
    }

    //查詢盲盒狀態
    function getBlindboxPhase() external returns(uint256){
        emit BlindboxPhrase(openBlindPhase);
        return openBlindPhase;
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
    
    function getTokenURI (uint256 _tokenId) external returns (string memory){
        string memory uri = tokenURI(_tokenId);
        emit TokenURI(_tokenId, uri);
        return uri;
    }

    //白名單Mint
    function whitelistMint(bytes32[] calldata _proof, uint256 _quantity) external payable nonReentrant checkOverMaxSupply(_quantity){
        require(verifyWhitelist(_proof), "You're not in whitelist.");
        require(_quantity <= whitelistMintParam.whitelistMintLimit, "Over whitelist mint limit.");
        require(_quantity * whitelistMintParam.whitelistMintPrice <= msg.value, "ETH not enough.");

        _mint(msg.sender, _quantity);

        //若多支付，則退還給用戶
        remainRefund((_quantity * whitelistMintParam.whitelistMintPrice), msg.value);

        emit WhitelistMint(msg.sender, whitelistMintParam.whitelistMintPrice , _quantity);

    }

    //公售荷蘭拍
    function publicAuctionMint(uint256 _quantity)  external payable nonReentrant checkOverMaxSupply(_quantity) {
        uint256 price = getAuctionPrice();
        require(msg.value >= _quantity * price, "ETH not enough.");

        _mint(msg.sender, _quantity);

        //若多支付，則退還給用戶
        remainRefund(( _quantity * price), msg.value);

        emit PublicMint(msg.sender, price , _quantity);
    }

    function getController() external returns (address){
        emit Controller(controller);
        return controller;
    }

    function transferBalanceToTreasury(address _treasuryAddress) external onlyOwner{
        
        IMasterTreasury masterTreasury = IMasterTreasury(_treasuryAddress);
        masterTreasury.addBalance(address(this).balance);
        payable(_treasuryAddress).transfer(address(this).balance);
        emit TransferToTreasury(_treasuryAddress, address(this).balance);
    }

    function getBalanceOf(address _account) external returns(uint256){
        uint256 balance = balanceOf(_account);
        emit BalanceOf(_account, balance);
        return balance;
    }

    function getWhitelistMintPrice() external returns(uint256){
        uint256 price = whitelistMintParam.whitelistMintPrice;
        emit GetWhitelistMintPrice(price);
        return price;
    }


}