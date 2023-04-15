//SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./ERC20/TrendToken.sol";
import "./ERC721A/TrendMasterNFT.sol";
import "./Governance/Council.sol";
import "./Governance/Proposal.sol";
import "./Governance/Treasury.sol";

import "./Governance/ICouncil.sol";
import "./Governance/IProposal.sol";
import "./Governance/ITreasury.sol";
import "./ERC20/ITrendToken.sol";
import "./ERC721A/ITrendMasterNFT.sol";

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract SetUp is Ownable{
    event GetProposal(address prposalAddr);

    ICouncil public council;
    IProposal public proposal;
    ITrendToken public trendToken;
    ITrendMasterNFT public trendMasterNFT;
    ITreasury public treasury;

    

    constructor(address[] memory _admins){
        TrendToken trendTokenInstance = new TrendToken(18);
        Treasury treasuryInstance = new Treasury(_admins);
        TrendMasterNFT trendMasterNFTInstance = new TrendMasterNFT(address(trendTokenInstance));
        Council councilInstance = new Council(address(trendTokenInstance), address(treasuryInstance));
        Proposal proposalInstance = new Proposal(address(trendTokenInstance), address(trendMasterNFTInstance), address(treasuryInstance), address(councilInstance));

        councilInstance.setController(address(proposalInstance));
        trendTokenInstance.setController(address(proposalInstance));
        trendMasterNFTInstance.setController(address(proposalInstance));

        trendTokenInstance.setDistribution(
            {
                _treasury_address: address(treasuryInstance),
                _treasury_amount: 200000000, 
                _tokenStakeInterest_amount: 250000000, 
                _consultant_address: address(0xb8A813833b6032b90a658231E1AA71Da1E7eA2ed), 
                _consultant_amount: 30000000, 
                _airdrop_amount: 20000000, 
                _nftStakeInterest_address: address(trendMasterNFTInstance), 
                _nftStakeInterest_amount: 300000000, 
                _publicMint_amount: 200000000
            });

        council = ICouncil(address(councilInstance));
        proposal = IProposal(address(proposalInstance));
        trendToken = ITrendToken(address(trendTokenInstance));
        treasury = ITreasury(address(treasuryInstance));
        trendMasterNFT = ITrendMasterNFT(address(trendMasterNFTInstance));
    }

    //競選結算
    function campaignConfirm() external onlyOwner{
        council.campaignConfirm();
    }

    // 更改提案為投票階段
    function changeProposalPhaseToVoting(uint256 _proposalIndex) external onlyOwner{
        proposal.changeProposalPhaseToVoting(_proposalIndex);
    }

    // 更改提案為確認階段
    function changeProposalPhaseTocConfirming(uint256 _proposalIndex) external onlyOwner{
        proposal.changeProposalPhaseToConfirming(_proposalIndex);
    }
    //提案結算
    function proposalConfirm(uint256 _proposalIndex) external onlyOwner{
        proposal.proposalConfirm(_proposalIndex);
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

    //代幣分配
    function tokenDistribute() external onlyOwner{
        trendToken.tokenDistribute();
    }

    //設定token空投白名單數量
    function setWhitelistNum(uint256 _whitelistNum) external onlyOwner{
        trendToken.setWhitelistNum(_whitelistNum);
    }

    //給前端定期呼叫
    function updateTotalStakedTokenHistory() external onlyOwner{
        trendToken.updateTotalStakedTokenHistory();
    }
    function setWhitelistMerkleTree(bytes32 _root) external onlyOwner{
        trendMasterNFT.setWhitelistMerkleTree(_root);
    }
    function setWhielistlimit(uint8 _amount) external onlyOwner{
        trendMasterNFT.setWhielistlimit(_amount);
    }
    function setAuction(
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _priceStep,
        uint256 _startTime,
        uint256 _timeStep, 
        uint256 _timeStepNum) 
    external
    onlyOwner
    {
        trendMasterNFT.setAuction(_startPrice, _endPrice, _priceStep, _startTime, _timeStep, _timeStepNum);
    }

    //開盲
    function openBlindbox() external onlyOwner{
        trendMasterNFT.openBlindbox();
    }

    function getTreasury () external view returns(address ){
        return address(treasury);
    }

    function getTrendToken () external view returns(address ){
        return address(trendToken);
    }

    function getTrendMasterNFT () external view returns(address ){
        return address(trendMasterNFT);
    }

    function getCouncil () external view returns(address ){
        return address(council);
    }

    function getProposal () external  returns(address ){
        emit GetProposal(address(proposal));
        return address(proposal);
    }
}