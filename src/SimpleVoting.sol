// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {VotingLibrary} from "./VotingLibrary.sol";

/// @title SimpleVoting
/// @author Hassan Abdaljalil
/// @notice Implements a simple, one-session voting system where an authorized entity can register voters and candidates and dictate the stages of voting
contract SimpleVoting {
    /// @dev The State struct that controls the stages of the voting procedure
    VotingLibrary.State private stateMachine;
    /// @dev Maps every address to a voter identity(struct)
    mapping(address => VotingLibrary.Voter) private addressToVoter;
    /// @dev Maps every candidate name to a candidate identity(struct)
    mapping(string => VotingLibrary.Candidate) nameToCandidate;

    /// @dev A count of the number of voters registered by the owner
    uint256 private numberOfRegisteredVoters;
    /// @dev A collection of the names of the candidates
    string[] private candidates;
    /// @dev The name of the winner
    string private winner;
    /// @dev The address of the deployed instance's owner
    address private immutable I_OWNER;

    constructor() {
        I_OWNER = msg.sender;
    }

    /// @param voter The address of the voter that was registered
    event VoterRegistered(address indexed voter);
    ///
    /// @param candidate The name of the candidate that was registered
    event CandidateRegistered(string indexed candidate);

    /// @param voter the name of the registered voter who voted for the candidate
    /// @param candidate the name of the registered candidate
    event Voted(address indexed voter, string indexed candidate);
    event RegistrationEnded();
    event VotingStarted();
    event VotingEnded();

    /// @param expectedState What the expected stage of voting is(i.e. Registration)
    modifier eqState(VotingLibrary.State expectedState) {
        _eqState(expectedState);
        _;
    }

    /// @dev Compares the expected stage of voting vs the actual stage; reverts if they do not match
    /// @param expectedState What the expected stage of voting is(i.e. Registration)
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

    /// @param candidateName The name of the candidate who supposedly exists
    modifier candidateExists(string memory candidateName) {
        // assumes that candidates is greater than 0(otherwise voting can't begin)
        _candidateExists(candidateName);
        _;
    }

    /// @dev The function looks to see if the candidate is registered
    /// @param candidateName The name of the candidate who supposedly exists
    function _candidateExists(string memory candidateName) internal view {
        if (nameToCandidate[candidateName].isRegistered == false) {
            revert VotingLibrary.CANDIDATE__DOES__NOT__EXIST();
        }
    }

    modifier isRegistered() {
        _isRegistered();
        _;
    }

    /// @dev Checks to see if msg.sender is a registered voter
    function _isRegistered() internal view {
        if (addressToVoter[msg.sender].isRegistered == false) {
            revert VotingLibrary.NOT__REGISTERED();
        }
    }

    /// @dev Only the owner can register voters; the function checks to see if the voter is not registered, otherwise it will revert; it updates correlated state variables subsequently
    /// @param _voterAddress The address of the voter to register
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

    /// @dev Only the owner can call this function; registeres a candidate and updates state if they are not already registered
    /// @param _name The name of the candidate to register
    function registerCandidate(string memory _name) external onlyOwner eqState(VotingLibrary.State.isRegistering) {
        if (nameToCandidate[_name].isRegistered) {
            revert VotingLibrary.IS__ALREADY__REGISTERED();
        } else {
            nameToCandidate[_name].isRegistered = true;
            candidates.push(_name);
            emit CandidateRegistered(_name);
        }
    }

    /// @dev If a registered voter has not yet voted, then they can vote for a registered candidate once
    /// @param candidateName The name of the candidate
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

    ///
    function endVoting() external eqState(VotingLibrary.State.isVoting) onlyOwner {
        stateMachine = VotingLibrary.State.isClosed;
        emit VotingEnded();
    }

    /// @dev Checks to see if voting has ended; then it looks for the winner, if they haven't already been found
    /// @return winnerName Name of the winner
    /// @return returnedWinner  Data(struct) associated with the winner
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

    /// @param voter Address of the voter
    function getAddressToVoter(address voter) external view returns (VotingLibrary.Voter memory) {
        return addressToVoter[voter];
    }

    function getCandidateNames() external view returns (string[] memory) {
        return candidates;
    }

    /// @param name Name of the candidate
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
