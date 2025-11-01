// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library VotingLibrary {
    enum State {
        isRegistering,
        isVoting,
        isClosed
    }

    struct Voter {
        bool isRegistered;
        bool voted;
        Candidate votedFor;
    }

    struct Candidate {
        bool isRegistered;
        uint256 votes;
        bool isWinner;
    }

    error IS__ALREADY__REGISTERED();
    error NOT__REGISTERED();
    error WRONG__PHASE(State expected, State current);
    error NOT__OWNER();
    error ALREADY__VOTED();
    error NOT__ENOUGH__REGISTERED_MEMBERS();
    error CANDIDATE__DOES__NOT__EXIST();
}
