//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./ERC20/TrendToken.sol";
import "./ERC721A/TrendMasterNFT.sol";
import "./Governance/Council.sol";
import "./Governance/Proposal.sol";
import "./Governance/Treasury.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Setup is Ownable{

    constructor(address[] memory _admins){
        TrendToken trendToken = new TrendToken(18);
        Treasury treasury = new Treasury(_admins);
        TrendMasterNFT trendMasterNFT = new TrendMasterNFT();
        Council council = new Council(address(trendToken), address(treasury));
        Proposal proposal = new Proposal(address(trendToken), address(trendMasterNFT), address(treasury), address(council));

        council.setController(address(proposal));
        
        
    }

    // 更改提案階段
    function changeProposalPhase() external onlyOwner{

    }

    //更改競選階段
    function changeCamgaignPhase() external onlyOwner{

    }
    //更改罷免階段
    function changeRecallPhase() external onlyOwner{

    }
    
    
}