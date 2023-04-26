//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IUniswapV2Invest{

    function swapExactETHForTokens(uint amountOut, address[] memory path) external payable;
    function getTokenBalance(address _tokenAddress) external view returns(uint256);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path)external returns (uint[] memory amounts);



}