//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


interface IProposal{

    function changeProposalPhaseToVoting (uint256 _proposalIndex) external;
    function changeProposalPhaseToConfirming (uint256 _proposalIndex) external;
    
}