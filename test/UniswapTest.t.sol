// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import "../src/ERC20/ITrendToken.sol";

interface IUniswapV2Pair {
  event Approval(address indexed owner, address indexed spender, uint value);
  event Transfer(address indexed from, address indexed to, uint value);

  function name() external pure returns (string memory);
  function symbol() external pure returns (string memory);
  function decimals() external pure returns (uint8);
  function totalSupply() external view returns (uint);
  function balanceOf(address owner) external view returns (uint);
  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint value) external returns (bool);
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external pure returns (bytes32);
  function nonces(address owner) external view returns (uint);

  function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

  event Mint(address indexed sender, uint amount0, uint amount1);
  event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
  event Swap(
      address indexed sender,
      uint amount0In,
      uint amount1In,
      uint amount0Out,
      uint amount1Out,
      address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint);
  function factory() external view returns (address);
  function token0() external view returns (address);
  function token1() external view returns (address);
  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
  function price0CumulativeLast() external view returns (uint);
  function price1CumulativeLast() external view returns (uint);
  function kLast() external view returns (uint);

  function mint(address to) external returns (uint liquidity);
  function burn(address to) external returns (uint amount0, uint amount1);
  function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
  function skim(address to) external;
  function sync() external;
}


interface IUniswapRoute02 {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
        ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
        ) external returns (uint amountToken, uint amountETH);

}
interface IUniswapV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint);

  function getPair(address tokenA, address tokenB) external view returns (address pair);
  function allPairs(uint) external view returns (address pair);
  function allPairsLength() external view returns (uint);

  function feeTo() external view returns (address);
  function feeToSetter() external view returns (address);

  function createPair(address tokenA, address tokenB) external returns (address pair);
}


contract UniswapTest is Test {

    ITrendToken public trendToken;
    IUniswapRoute02 public uniswap;
    IUniswapV2Factory public factory;
    IUniswapV2Pair public uniswapPair;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth_goerli");
        trendToken = ITrendToken(0xCb40518a7dCC16Bc4B4b04e6022E9751008c5CaD);
        uniswap = IUniswapRoute02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
        
    }

    function testUniswap() public {

        vm.deal(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed, 2000 ether);

        vm.startPrank(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed);
        trendToken.publicMint{value: 1000 ether}(10000000 ether);

        console.log("TrendToken balance:", trendToken.balanceOf(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed));
        console.log(address(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed).balance);
        address pair = factory.createPair(address(trendToken), address(uniswap.WETH()));
        uniswapPair = IUniswapV2Pair(pair);
        console.log("pair address : " , address(pair));
        trendToken.approve(address(uniswap), trendToken.balanceOf(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed));
        (uint amountToken, uint amountETH, uint liquidity) = uniswap.addLiquidityETH{value: 1 ether}(
            address(trendToken),
            100000 ether, 
            0, 
            0, 
            address(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed), 
            block.timestamp);
        
        console.log("amountToken : ", amountToken);
        console.log("amountETH : ", amountETH); 
        console.log("liquidity : ", liquidity);
        console.log(uniswapPair.balanceOf(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed));

        uniswapPair.approve(address(uniswap), uniswapPair.balanceOf(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed));

        (uint removeAmount, uint removeETH) = uniswap.removeLiquidityETH(
            address(trendToken), 
            liquidity, 
            0, 
            0, 
            address(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed), 
            block.timestamp);
        console.log("removeAmount : ", removeAmount);
        console.log("removeETH", removeETH);

        vm.stopPrank();
        
    }


}