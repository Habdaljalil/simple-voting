// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VotingLibrary} from "./VotingLibrary.sol";

contract SimpleVoting {
    VotingLibrary.State private stateMachine;
    mapping(address => VotingLibrary.Voter) private addressToVoter;
    mapping(string => VotingLibrary.Candidate) nameToCandidate;

    uint256 private numberOfRegisteredVoters;

    string[] private candidates;

    string private winner;

    address private immutable I_OWNER;

    constructor() {
        I_OWNER = msg.sender;
    }

    event VoterRegistered(address indexed voter);
    event CandidateRegistered(string indexed candidate);
    event Voted(address indexed voter, string indexed candidate);
    event RegistrationEnded();
    event VotingStarted();
    event VotingEnded();

    modifier eqState(VotingLibrary.State expectedState) {
        _eqState(expectedState);
        _;
    }

    function _eqState(VotingLibrary.State expectedState) internal view {
        if (stateMachine != expectedState) {
            revert VotingLibrary.WRONG__PHASE(expectedState, stateMachine);
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

    modifier candidateExists(string memory candidateName) {
        // assumes that candidates is greater than 0(otherwise voting can't begin)
        _candidateExists(candidateName);
        _;
    }

    function _candidateExists(string memory candidateName) internal view {
        if (nameToCandidate[candidateName].isRegistered == false) {
            revert VotingLibrary.CANDIDATE__DOES__NOT__EXIST();
        }
    }

    modifier isRegistered() {
        _isRegistered();
        _;
    }

    function _isRegistered() internal view {
        if (addressToVoter[msg.sender].isRegistered == false) {
            revert VotingLibrary.NOT__REGISTERED();
        }
    }

    function registerVoter(address _voterAddress)
        external
        onlyOwner
        eqState(VotingLibrary.State.isRegistering)
        returns (VotingLibrary.Voter memory registeredVoter)
    {
        VotingLibrary.Voter storage voter = addressToVoter[_voterAddress];

        if (voter.isRegistered) {
            revert VotingLibrary.IS__ALREADY__REGISTERED();
        } else {
            voter.isRegistered = true;
            numberOfRegisteredVoters++;
            emit VoterRegistered(_voterAddress);
        }
        return voter;
    }

    function registerCandidate(string memory _name) external onlyOwner eqState(VotingLibrary.State.isRegistering) {
        if (nameToCandidate[_name].isRegistered) {
            revert VotingLibrary.IS__ALREADY__REGISTERED();
        } else {
            nameToCandidate[_name].isRegistered = true;
            candidates.push(_name);
            emit CandidateRegistered(_name);
        }
    }

    function vote(string memory candidateName)
        external
        candidateExists(candidateName)
        isRegistered
        eqState(VotingLibrary.State.isVoting)
    {
        VotingLibrary.Voter storage voter = addressToVoter[msg.sender];

        if (voter.voted) {
            revert VotingLibrary.ALREADY__VOTED();
        } else {
            nameToCandidate[candidateName].votes++;
            voter.voted = true;
            voter.votedFor = nameToCandidate[candidateName];
            emit Voted(msg.sender, candidateName);
        }
    }

    function startVoting() external onlyOwner {
        if (candidates.length > 0 && numberOfRegisteredVoters > 0) {
            stateMachine = VotingLibrary.State.isVoting;
            emit RegistrationEnded();
            emit VotingStarted();
        } else {
            revert VotingLibrary.NOT__ENOUGH__REGISTERED_MEMBERS();
        }
    }

    function endVoting() external eqState(VotingLibrary.State.isVoting) onlyOwner {
        stateMachine = VotingLibrary.State.isClosed;
        emit VotingEnded();
    }

    function getWinner()
        external
        eqState(VotingLibrary.State.isClosed)
        returns (string memory, VotingLibrary.Candidate memory returnedWinner)
    {
        VotingLibrary.Candidate memory currentWinner;
        string memory currentWinnerName;
        if (keccak256(abi.encode(winner)) != keccak256(abi.encode(""))) {
            return (winner, nameToCandidate[winner]);
        } else {
            string[] memory candidatesMemory = candidates;
            uint256 candidatesMemorylength = candidatesMemory.length;

            for (uint256 i = 0; i < candidatesMemorylength; i++) {
                VotingLibrary.Candidate memory currentCandidate = nameToCandidate[candidates[i]];
                if (currentCandidate.votes > currentWinner.votes) {
                    currentWinner = currentCandidate;
                    currentWinnerName = candidates[i];
                }
            }
        }
        winner = currentWinnerName;
        return (currentWinnerName, currentWinner);
    }

    function getOwner() external view returns (address) {
        return I_OWNER;
    }

    function getAddressToVoter(address voter) external view returns (VotingLibrary.Voter memory) {
        return addressToVoter[voter];
    }

    function getCandidateNames() external view returns (string[] memory) {
        return candidates;
    }

    function getCandidateByName(string memory name)
        external
        view
        candidateExists(name)
        returns (VotingLibrary.Candidate memory)
    {
        return nameToCandidate[name];
    }

    function getState() external view returns (VotingLibrary.State) {
        return stateMachine;
    }
}
