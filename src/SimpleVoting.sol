// SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity ^0.8.30;

import {VotingLibrary} from "./VotingLibrary.sol";

contract SimpleVoting {
    VotingLibrary.State stateMachine = VotingLibrary.State({isRegistering: true, isVoting: false, isClosed: false});
    mapping(address => VotingLibrary.Voter) addressToVoter;
    VotingLibrary.Candidate[] private candidates;

    VotingLibrary.Candidate private winner;

    address immutable I_OWNER;

    constructor() {
        I_OWNER = msg.sender;
    }

    modifier isRegistrationPhase() {
        _isRegistrationPhase();
        _;
    }

    function _isRegistrationPhase() internal view {
        if (stateMachine.isRegistering == false) {
            revert VotingLibrary.REGISTERING__IS__OVER();
        }
    }

    modifier isClosed() {
        _isClosed();
        _;
    }

    function _isClosed() internal view {
        if (stateMachine.isClosed == false) {
            revert VotingLibrary.IS__NOT__CLOSED();
        }
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        if (msg.sender != I_OWNER) {
            revert VotingLibrary.NOT__OWNER();
        }
    }

    modifier candidateExists(uint256 candidateId) {
        // assumes that candidates is greater than 0(otherwise voting can't begin)
        _candidateExists(candidateId);
        _;
    }

    function _candidateExists(uint256 candidateId) internal view {
        if (candidateId > candidates.length) {
            revert VotingLibrary.CANDIDATE__DOES__NOT__EXIST();
        }
    }

    function registerVoter(address _voterAddress)
        external
        onlyOwner
        isRegistrationPhase
        returns (VotingLibrary.Voter memory registeredVoter)
    {
        VotingLibrary.Voter storage voter = addressToVoter[_voterAddress];

        if (voter.isRegistered) {
            revert VotingLibrary.IS__ALREADY__REGISTERED();
        } else {
            voter.isRegistered = true;
        }
        return voter;
    }

    function registerCandidate(uint256 candidateId, string memory _name)
        external
        onlyOwner
        isRegistrationPhase
        candidateExists(candidateId)
    {
        VotingLibrary.Candidate storage candidate = candidates[candidateId];

        if (candidate.isRegistered) {
            revert VotingLibrary.IS__ALREADY__REGISTERED();
        } else {
            candidate.name = _name;
            candidate.isRegistered = true;
        }
    }

    function vote(uint256 candidateId) external candidateExists(candidateId) {
        VotingLibrary.Voter storage voter = addressToVoter[msg.sender];

        if (voter.voted) {
            revert VotingLibrary.ALREADY__VOTED();
        } else {
            voter.voted = true;
            voter.votedFor = candidates[candidateId];
            candidates[candidateId].votes++;
        }
    }

    function startVoting() external onlyOwner {
        if (candidates.length > 0) {
            stateMachine.isRegistering = false;
            stateMachine.isVoting = true;
        } else {
            revert VotingLibrary.NOT__ENOUGH__CANDIDATES();
        }
    }

    function endVoting() external onlyOwner {
        stateMachine.isVoting = false;
        stateMachine.isClosed = true;
    }

    function getWinner() external view isClosed returns (VotingLibrary.Candidate memory returnedWinner) {
        VotingLibrary.Candidate memory currentWinner;

        if (keccak256(abi.encode(winner.name)) != keccak256(abi.encode(""))) {
            return winner;
        } else {
            VotingLibrary.Candidate[] memory candidatesMemory = candidates;
            uint256 candidatesMemorylength = candidatesMemory.length;

            for (uint256 i = 0; i < candidatesMemorylength; i++) {
                VotingLibrary.Candidate memory currentCandidate = candidates[i];
                if (currentCandidate.votes > currentWinner.votes) {
                    currentWinner = currentCandidate;
                }
            }
        }
        return currentWinner;
    }
}
