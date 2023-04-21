//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "erc721a/contracts/IERC721A.sol";

interface ITrendMasterNFT is IERC721A{
    //設定控制者
    function setController(address _controllerAddress) external;
}