// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "../ERC20/ITrendToken.sol";
import "../ERC721A/ITrendMasterNFT.sol";



contract NFTStakingRewards{
    ITrendMasterNFT public stakingNFT;
    ITrendToken public rewardsToken;

    uint256 public remainTokens;

    address public owner;

    // Duration of rewards to be paid out (in seconds)
    uint public duration;
    // Timestamp of when the rewards finish
    uint public finishAt;
    // Minimum of last updated time and reward finish time
    uint public updatedAt;
    // Reward to be paid out per second
    uint public rewardRate;
    // Sum of (reward rate * dt * 1e18 / total supply)
    uint public rewardPerTokenStored;
    // User address => rewardPerTokenStored
    mapping(address => uint) public userRewardPerTokenPaid;
    // User address => rewards to be claimed
    mapping(address => uint) public rewards;

    mapping (address => uint256[]) ownerOfNfts; 

    // Total staked
    uint public totalSupply;
    // User address => staked amount
    mapping(address => uint) public balanceOf;

    // tokenId => address
    mapping (uint => address) public stakingTokenIdMapping;

    bool isStaking = false;

    event GetRemainTokens(uint256 _reaminTokens);
    event GetBalanceOf(address _account, uint256 _balance);
    event Stake(address _account, uint256 _tokenId);
    event Withdraw(address _account, uint256 _tokenId);
    event Earned(address _account, uint256 earn);
    event RewardPerToken(uint256 _rewardPerToken);
    event GetFinishAt(uint256 _finishAt);

    constructor(address _nft, address _rewardToken) {
        owner = msg.sender;
        stakingNFT = ITrendMasterNFT(_nft);
        rewardsToken = ITrendToken(_rewardToken);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }

    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken();
        updatedAt = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewards[_account] = earned(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }

        _;
    }

    function openStake() external {
        require(!isStaking, "already open.");
        isStaking = true;
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return _min(finishAt, block.timestamp);
    }

    function rewardPerToken() public returns (uint) {
        if (totalSupply == 0) {
            emit RewardPerToken(rewardPerTokenStored);
            return rewardPerTokenStored;
        }
        uint256 res = rewardPerTokenStored +
            (rewardRate * (lastTimeRewardApplicable() - updatedAt) * 1e18) /
            totalSupply;
        
        emit RewardPerToken(res);

        return res;
            
    }

    function stake(uint _tokenId) external updateReward(msg.sender) {
        require(isStaking, "staking not open.");
        require(stakingTokenIdMapping[_tokenId] == address(0), "The Trend Master NFT is already staked.");
        require(stakingNFT.ownerOf(_tokenId) == msg.sender, "The Trend Master NFT is not yours.");
        ownerOfNfts[msg.sender].push(_tokenId);
        stakingNFT.transferFrom(msg.sender, address(this), _tokenId);
        balanceOf[msg.sender]++;
        stakingTokenIdMapping[_tokenId] = msg.sender;
        totalSupply++;

        emit Stake(msg.sender, _tokenId);
    }

    function withdraw(uint _tokenId) external updateReward(msg.sender) {
        require(stakingTokenIdMapping[_tokenId] != address(0), "The Trend Master NFT is unstaked.");
        require(stakingTokenIdMapping[_tokenId] == msg.sender, "The Trend Master NFT is not yours.");
        balanceOf[msg.sender]--;
        totalSupply--;
        
        for(uint256 i=0; i< ownerOfNfts[msg.sender].length; i++){
            if (ownerOfNfts[msg.sender][i] == _tokenId ){
                delete ownerOfNfts[msg.sender][i];
                for(uint256 j=i; j < ownerOfNfts[msg.sender].length-1; j++ ){
                    ownerOfNfts[msg.sender][j] = ownerOfNfts[msg.sender][j+1];
                }
                ownerOfNfts[msg.sender].pop();
                break;
            }
        }

        stakingNFT.safeTransferFrom(address(this), msg.sender, _tokenId);

        emit Withdraw(msg.sender, _tokenId);
    }

    //取得可以賺多少
    function earned(address _account) public returns (uint) {
        uint256 earn = ((balanceOf[_account] *
                (rewardPerToken() - userRewardPerTokenPaid[_account])) / 1e18) +
            rewards[_account];
        emit Earned(_account, earn);
        return earn;
            
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
            remainTokens -= reward;
        }
    }

    function setRewardsDuration(uint _duration) external onlyOwner {
        require(finishAt < block.timestamp, "reward duration not finished");
        duration = _duration;
    }

    function notifyRewardAmount(
        uint _amount
    ) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishAt) {
            rewardRate = _amount / duration;
        } else {
            uint remainingRewards = (finishAt - block.timestamp) * rewardRate;
            rewardRate = (_amount + remainingRewards) / duration;
        }

        require(rewardRate > 0, "reward rate = 0");
        require(
            rewardRate * duration <= rewardsToken.balanceOf(address(this)),
            "reward amount > balance"
        );

        finishAt = block.timestamp + duration;
        updatedAt = block.timestamp;

        remainTokens = _amount;
    }
    //取得質押多少幣
    function getBalanceOf(address _addr) external returns (uint256){
        uint256 balance = balanceOf[_addr];
        emit GetBalanceOf(_addr, balance);
        return balance;
    }

    function _min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    /*function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        return this.onERC721Received.selector;
    } */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        try IERC721Receiver(operator).onERC721Received(operator, from, tokenId, data) {
                    return IERC721Receiver.onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert("ERC721: transfer to non ERC721Receiver implementer");
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    //取得還有多少利息沒發出去
    function getRemainTokens() external returns(uint256){
        emit GetRemainTokens(remainTokens);
        return remainTokens;
    }

    //取得結束時間
    function getFinishAt() external returns(uint256){
        emit GetFinishAt(finishAt);
        return finishAt;
    }

    function setTrendMasterAddress(address _trendMasterAddress) external onlyOwner{
        stakingNFT = ITrendMasterNFT(_trendMasterAddress);
    }

    function setTrendTokenAddress(address _trendTokenAddress) external onlyOwner{
        rewardsToken = ITrendToken(_trendTokenAddress);
    }
    function getOwnerOfNfts(address _account) external view returns(uint256[] memory){
        return ownerOfNfts[_account];
    } 

}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

