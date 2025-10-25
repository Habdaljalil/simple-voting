// SPDX-LICENSE-IDENTIFIER: MIT
pragma solidity ^0.8.30;

library VotingLibrary {
    struct State {
        bool isRegistering;
        bool isVoting;
        bool isClosed;
    }

    struct Voter {
        bool isRegistered;
        bool voted;
        Candidate votedFor;
    }

    struct Candidate {
        string name;
        bool isRegistered;
        uint256 votes;
        bool isWinner;
    }

    error IS__ALREADY__REGISTERED();
    error IS__NOT__CLOSED();
    error REGISTERING__IS__OVER();
    error NOT__OWNER();
    error ALREADY__VOTED();
    error NOT__ENOUGH__CANDIDATES();
    error CANDIDATE__DOES__NOT__EXIST();
}
