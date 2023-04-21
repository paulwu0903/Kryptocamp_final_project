// SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "../ERC20/ITrendToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";



contract TokenAirdrop is Ownable{

    ITrendToken public airdropToken;

    constructor (address _airdropToken){
        airdropToken = ITrendToken(_airdropToken);
    }

    function airdrop() external onlyOwner{

    }

}