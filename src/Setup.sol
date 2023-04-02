//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./ERC20/TrendToken.sol";
import "./ERC721A/TrendMasterNFT.sol";
import "./Governance/Council.sol";
import "./Governance/Proposal.sol";
import "./Governance/Treasury.sol";

import "./Governance/ICouncil.sol";
import "./Governance/IProposal.sol";
import "./ERC20/ITrendToken.sol";

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Setup is Ownable{

    ICouncil public council;
    IProposal public proposal;
    ITrendToken public trendToken;

    

    constructor(address[] memory _admins){
        TrendToken trendTokenInstance = new TrendToken(18);
        Treasury treasuryInstance = new Treasury(_admins);
        TrendMasterNFT trendMasterNFTInstance = new TrendMasterNFT();
        Council councilInstance = new Council(address(trendTokenInstance), address(treasuryInstance));
        Proposal proposalInstance = new Proposal(address(trendTokenInstance), address(trendMasterNFTInstance), address(treasuryInstance), address(councilInstance));

        councilInstance.setController(address(proposalInstance));
        trendTokenInstance.setController(address(proposalInstance));
        trendMasterNFTInstance.setController(address(proposalInstance));

        trendTokenInstance.setDistribution(
            {
                _treasury_address: address(treasuryInstance),
                _treasury_amount: 200000000000000000000000000, 
                _tokenStakeInterest_amount: 250000000000000000000000000, 
                _consultant_address: address(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed), 
                _consultant_amount: 30000000000000000000000000, 
                _airdrop_amount: 20000000000000000000000000, 
                _nftStakeInterest_address: address(trendMasterNFTInstance), 
                _nftStakeInterest_amount: 300000000000000000000000000, 
                _publicMint_amount: 200000000000000000000000000
            });

        council = ICouncil(address(councilInstance));
        proposal = IProposal(address(proposalInstance));
        trendToken = ITrendToken(address(treasuryInstance));
    }

    // 更改提案為投票階段
    function changeProposalPhaseToVoting(uint256 _proposalIndex) external onlyOwner{
        proposal.changeProposalPhaseToVoting(_proposalIndex);
    }

    // 更改提案為確認階段
    function changeProposalPhaseTocConfirming(uint256 _proposalIndex) external onlyOwner{
        proposal.changeProposalPhaseToConfirming(_proposalIndex);
    }

    //更改競選為候選人報名階段
    function changeCamgaignPhaseToCandidateAttending() external onlyOwner{
        council.changeCampaignToCandidateAttending();
    }

    //更改競選為投票階段
    function changeCamgaignPhaseToVoting() external onlyOwner{
        council.changeCampaignToVoting();
    }

    //更改競選為確認階段
    function changeCamgaignPhaseToConfirming() external onlyOwner{
        council.changeCampaignToConforming();
    }

    //更改罷免為投票階段
    function changeRecallPhaseToVoting() external onlyOwner{
        council.changeRecallToVoting();
    }

    //更改罷免為確認階段
    function changeRecallPhaseToConfirming() external onlyOwner{
        council.changeRecallToConfirming();
    }

    //發放空投
    function sendAirdrop() external onlyOwner{
        trendToken.sendAirdrop();
    }

    //設定token空投白名單數量
    function setWhitelistNum(uint256 _whitelistNum) external onlyOwner{
        trendToken.setWhitelistNum(_whitelistNum);
    }


    //給前端定期呼叫
    function updateTotalStakedTokenHistory() external onlyOwner{
        trendToken.updateTotalStakedTokenHistory();
    }

}