//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IUniswapV2Invest{

    function swapExactETHForTokens(uint amountOut, address[] memory path) external payable;
    function getTokenBalance(address _tokenAddress) external view returns(uint256);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path)external returns (uint[] memory amounts);
    function createPool() external returns(address);
    function addTrendTokenLiquidityETH(
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin
        ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeTrendTokenLiquidityETH(
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin
        ) external returns (uint amountToken, uint amountETH);
    function getPairAddress() external view returns(address);


}