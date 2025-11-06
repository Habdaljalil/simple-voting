// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {DeploySimpleVoting} from "../../script/DeploySimpleVoting.s.sol";
import {SimpleVoting} from "../../src/SimpleVoting.sol";
import {VotingLibrary} from "../../src/VotingLibrary.sol";
import {TestSimpleVoting} from "../Unit/TestSimpleVoting.t.sol";

/// @title
/// @author
/// @notice
contract TestSimpleVotingIntegration is Test, TestSimpleVoting {
    function testRegisterVoterIntegration(address voter) public {
        vm.startPrank(OWNER);
        simpleVoting.registerVoter(voter);
        vm.stopPrank();
    }

    function testRegisterCandidateIntegration(string memory candidate) public {
        vm.startPrank(OWNER);
        simpleVoting.registerCandidate(candidate);
        vm.stopPrank();
    }

    function testVoteIntegration(address voter, string memory candidate) public {
        vm.startPrank(OWNER);
        simpleVoting.registerVoter(voter);
        simpleVoting.registerCandidate(candidate);
        simpleVoting.startVoting();
        vm.stopPrank();

        vm.startPrank(voter);
        simpleVoting.vote(candidate);
        vm.stopPrank();
    }
}
