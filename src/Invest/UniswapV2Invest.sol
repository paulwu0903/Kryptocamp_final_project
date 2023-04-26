// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UniswapDemo{
    // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    //["0x07865c6E87B9F70255377e024ace6630C1Eaa37F","0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"]
    // ["0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6","0x07865c6E87B9F70255377e024ace6630C1Eaa37F"]
    
    IUniswap uniswap;
    address public uniAddress;

    address[] public investingToken;
    mapping(address => uint256) public tokenAmountMap;
    
    constructor(address _uniswap) {
        uniswap = IUniswap(_uniswap);
        uniAddress = _uniswap;
    }

    function swapExactETHForTokens(
        uint amountOut,
        address[] memory path
    ) external payable {
        address targetToken = path[path.length-1];
        investingToken.push(targetToken);
        uniswap.swapExactETHForTokens{value: msg.value}(
            amountOut,
            path,
            msg.sender,
            block.timestamp
        );
        tokenAmountMap[targetToken] = getTokenBalance(targetToken);
    }

    //要先讓用戶去approve代幣到這個合約，此方法才會通過
    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path
        )external
        returns (uint[] memory amounts){
            IERC20 token = IERC20(path[0]);
            token.transferFrom(msg.sender, address(this), token.balanceOf(msg.sender));
            token.approve(uniAddress, token.balanceOf(address(this)));

            amounts = uniswap.swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                msg.sender,
                block.timestamp + 60
            );
            tokenAmountMap[path[0]] = getTokenBalance(path[0]);

            if (tokenAmountMap[path[0]] == 0){
                removeToken(path[0]);
            }
        
    }

    function getTokenBalance(address _tokenAddress) public view returns(uint256){
        IERC20 token = IERC20(_tokenAddress);
        return token.balanceOf(msg.sender);
    }

    function removeToken(address _token) private {
        for (uint256 i=0; i < investingToken.length; i++){
            if (investingToken[i] == _token){
                delete investingToken[i];
                for(uint256 j= i ; j < investingToken.length-1; j++){
                    investingToken[j] = investingToken[j+1];
                }
                investingToken.pop();
                break;
            }
        }
    }
  
}
interface IUniswap {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}