// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../ERC20/ITrendToken.sol";

contract UniswapV2Invest is Ownable{
    // 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    // 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    //["0x07865c6E87B9F70255377e024ace6630C1Eaa37F","0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6"]
    // ["0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6","0x07865c6E87B9F70255377e024ace6630C1Eaa37F"]
    
    IUniswapRoute02 uniswapRoute02;
    IUniswapV2Factory uniswapFactory;
    ITrendToken trendToken;
    IUniswapV2Pair public uniswapPair;
    bool isCreatePool = false;
    
    mapping(address => bool) public isController;

     //是否為controller
    modifier onlyController {
        require(isController[msg.sender], "not controller.");
        _;
    }
    
    constructor(address _uniswapRoute02Addr, address _uniswapFactory, address _trendTokenAddr) {
        uniswapRoute02 = IUniswapRoute02(_uniswapRoute02Addr);
        uniswapFactory = IUniswapV2Factory(_uniswapFactory);
        trendToken = ITrendToken(_trendTokenAddr);
    }

    function addController(address _controller) external onlyOwner{
        isController[_controller] = true;
    }

    function swapExactETHForTokens(
        uint amountOut,
        address[] memory path
    ) 
    external 
    onlyController
    payable {
        uniswapRoute02.swapExactETHForTokens{value: msg.value}(
            amountOut,
            path,
            msg.sender,
            block.timestamp
        );
    }

    //要先讓用戶去approve代幣到這個合約，此方法才會通過
    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path
        )
    external
    onlyController
    returns (uint[] memory amounts){
            IERC20 token = IERC20(path[0]);
            token.transferFrom(msg.sender, address(this), token.balanceOf(msg.sender));
            token.approve(address(uniswapRoute02), token.balanceOf(address(this)));

            amounts = uniswapRoute02.swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                msg.sender,
                block.timestamp + 60
            );
        
    }

    function getTokenBalance(address _tokenAddress) public view returns(uint256){
        IERC20 token = IERC20(_tokenAddress);
        return token.balanceOf(msg.sender);
    }

    function createPool() external returns(address){
        address poolAddr = uniswapFactory.createPair(address(trendToken), uniswapRoute02.WETH());
        uniswapPair = IUniswapV2Pair(poolAddr);
        return poolAddr;
    }

    function addTrendTokenLiquidityETH(
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin
        ) external payable returns (uint amountToken, uint amountETH, uint liquidity){
            trendToken.transferFrom(msg.sender, address(this), amountTokenDesired);
            trendToken.approve(address(uniswapRoute02), amountTokenDesired);
            (amountToken, amountETH, liquidity) = uniswapRoute02.addLiquidityETH{value: msg.value}(address(trendToken), amountTokenDesired, amountTokenMin, amountETHMin, address(msg.sender), block.timestamp+60);

        }
    function removeTrendTokenLiquidityETH(
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin
        ) external returns (uint amountToken, uint amountETH){
            uniswapPair.transferFrom(msg.sender, address(this), liquidity);
            uniswapPair.approve(address(uniswapRoute02), liquidity);
            (amountToken, amountETH) = uniswapRoute02.removeLiquidityETH(address(trendToken), liquidity, amountTokenMin, amountETHMin, address(msg.sender), block.timestamp+60);

        }
    function getPairAddress() external view returns(address){
        return address(uniswapPair);
    }

}

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
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
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
