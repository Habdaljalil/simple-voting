// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "../../lib/forge-std/src/Test.sol";
import {DeploySimpleVoting} from "../../script/DeploySimpleVoting.s.sol";
import {SimpleVoting} from "../../src/SimpleVoting.sol";
import {VotingLibrary} from "../../src/VotingLibrary.sol";

contract TestSimpleVoting is Test {
    SimpleVoting internal simpleVoting;
    address internal OWNER = makeAddr("Hassan");
    address internal NOT_OWNER = makeAddr("Not Hassan");
    address internal VOTER_1 = makeAddr("Voter #1");
    address internal UNREGISTERED_VOTER = makeAddr("Voter #2");
    string internal CANDIDATE_1 = "Candidate #1";

    address[] internal voters;
    string[] internal candidates;

    function setUp() public {
        DeploySimpleVoting deploySimpleVoting = new DeploySimpleVoting();
        simpleVoting = deploySimpleVoting.run(OWNER);

        voters.push(VOTER_1);
        candidates.push(CANDIDATE_1);
    }

    modifier register(address[] memory votersList, string[] memory candidatesList) {
        _register(voters, candidates);
        _;
    }

    function _register(address[] memory votersList, string[] memory candidatesList) internal {
        for (uint256 i = 0; i < votersList.length; i++) {
            vm.startPrank(OWNER);
            simpleVoting.registerVoter(votersList[i]);
            vm.stopPrank();
        }

        for (uint256 i = 0; i < candidatesList.length; i++) {
            vm.startPrank(OWNER);
            simpleVoting.registerCandidate(candidatesList[i]);
            vm.stopPrank();
        }
    }

    modifier inVotingPhase() {
        _inVotingPhase();
        _;
    }

    function _inVotingPhase() internal {
        vm.startPrank(OWNER);
        simpleVoting.startVoting();
        vm.stopPrank();
    }

    modifier inClosedPhase() {
        _inClosedPhase();
        _;
    }

    function _inClosedPhase() internal {
        vm.startPrank(OWNER);
        simpleVoting.endVoting();
        vm.stopPrank();
    }

    modifier registeredAndVoted() {
        _registeredAndVoted();
        _;
    }

    function _registeredAndVoted() internal {
        _register(voters, candidates);
        vm.startPrank(OWNER);
        simpleVoting.startVoting();
        vm.stopPrank();

        vm.startPrank(VOTER_1);
        simpleVoting.vote(CANDIDATE_1);
        vm.stopPrank();
    }

    function testOwner() public view {
        assertEq(OWNER, simpleVoting.getOwner());
    }

    function testRegisterVoter() public {
        vm.startPrank(OWNER);
        vm.expectEmit(true, false, false, true);
        emit SimpleVoting.VoterRegistered(VOTER_1);
        simpleVoting.registerVoter(VOTER_1);

        vm.stopPrank();

        VotingLibrary.Voter memory voterStruct = simpleVoting.getAddressToVoter(VOTER_1);

        assertEq(voterStruct.isRegistered, true);
    }

    function testRegisterVoterNotOwner() public {
        vm.expectRevert(VotingLibrary.NOT__OWNER.selector);
        vm.startPrank(NOT_OWNER);
        simpleVoting.registerVoter(VOTER_1);
        vm.stopPrank();
    }

    function testRegisterVoterAlreadyRegistered() public register(voters, candidates) {
        vm.expectRevert(VotingLibrary.IS__ALREADY__REGISTERED.selector);
        vm.startPrank(OWNER);
        simpleVoting.registerVoter(VOTER_1);
        vm.stopPrank();
    }

    function testRegisterCandidate() public {
        vm.startPrank(OWNER);
        vm.expectEmit(true, false, false, true);
        emit SimpleVoting.CandidateRegistered(CANDIDATE_1);
        simpleVoting.registerCandidate(CANDIDATE_1);

        vm.stopPrank();

        VotingLibrary.Candidate memory candidateStruct = simpleVoting.getCandidateByName(CANDIDATE_1);

        assertEq(candidateStruct.isRegistered, true);
    }

    function testRegisterCandidateNotOwner() public {
        vm.expectRevert(VotingLibrary.NOT__OWNER.selector);
        vm.startPrank(NOT_OWNER);
        simpleVoting.registerCandidate(CANDIDATE_1);
        vm.stopPrank();
    }

    function testRegisterCandidateAlreadyRegistered() public register(voters, candidates) {
        vm.expectRevert(VotingLibrary.IS__ALREADY__REGISTERED.selector);
        vm.startPrank(OWNER);
        simpleVoting.registerCandidate(CANDIDATE_1);

        vm.stopPrank();
    }

    function testStartVoting() public register(voters, candidates) {
        vm.startPrank(OWNER);
        vm.expectEmit(false, false, false, true);
        emit SimpleVoting.RegistrationEnded();
        vm.expectEmit(false, false, false, true);
        emit SimpleVoting.VotingStarted();
        simpleVoting.startVoting();
        vm.stopPrank();

        assert(simpleVoting.getState() == VotingLibrary.State.isVoting);
    }

    function testStartVotingNotOwner() public register(voters, candidates) {
        vm.expectRevert(VotingLibrary.NOT__OWNER.selector);
        vm.startPrank(NOT_OWNER);
        simpleVoting.startVoting();
        vm.stopPrank();
    }

    function testStartVotingNotEnoughPeople() public {
        vm.expectRevert(VotingLibrary.NOT__ENOUGH__REGISTERED_MEMBERS.selector);
        vm.startPrank(OWNER);
        simpleVoting.startVoting();
        vm.stopPrank();
    }

    function testVote() public register(voters, candidates) inVotingPhase {
        uint256 candidateVotes = simpleVoting.getCandidateByName(CANDIDATE_1).votes;

        vm.startPrank(VOTER_1);
        vm.expectEmit(true, true, false, true);
        emit SimpleVoting.Voted(VOTER_1, CANDIDATE_1);
        simpleVoting.vote(CANDIDATE_1);
        vm.stopPrank();

        assertEq(simpleVoting.getAddressToVoter(VOTER_1).voted, true);
        assertEq(
            keccak256(abi.encode(simpleVoting.getAddressToVoter(VOTER_1).votedFor)),
            keccak256(abi.encode(simpleVoting.getCandidateByName(CANDIDATE_1)))
        );
        assertEq(candidateVotes + 1, 1);
    }

    function testVoteNotCorrectPhase() public register(voters, candidates) {
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingLibrary.WRONG__PHASE.selector, VotingLibrary.State.isVoting, VotingLibrary.State.isRegistering
            )
        );
        vm.startPrank(VOTER_1);
        simpleVoting.vote(CANDIDATE_1);
        vm.stopPrank();
    }

    function testVoteCandidateDoesNotExist() public register(voters, candidates) inVotingPhase {
        vm.expectRevert(VotingLibrary.CANDIDATE__DOES__NOT__EXIST.selector);
        vm.startPrank(VOTER_1);
        simpleVoting.vote("CANDIDATE_2");
        vm.stopPrank();
    }

    function testVoteVoterNotRegistered() public register(voters, candidates) inVotingPhase {
        vm.expectRevert(VotingLibrary.NOT__REGISTERED.selector);
        vm.startPrank(UNREGISTERED_VOTER);
        simpleVoting.vote(CANDIDATE_1);
        vm.stopPrank();
    }

    function testVoteVoterAlreadyVoted() public register(voters, candidates) inVotingPhase {
        vm.startPrank(VOTER_1);
        simpleVoting.vote(CANDIDATE_1);
        vm.expectRevert(VotingLibrary.ALREADY__VOTED.selector);
        simpleVoting.vote(CANDIDATE_1);
        vm.stopPrank();
    }

    function testEndVoting() public register(voters, candidates) inVotingPhase {
        vm.startPrank(OWNER);
        vm.expectEmit(false, false, false, true);
        emit SimpleVoting.VotingEnded();
        simpleVoting.endVoting();
        vm.stopPrank();
    }

    function testEndVotingNotInVotingPhase() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingLibrary.WRONG__PHASE.selector, VotingLibrary.State.isVoting, VotingLibrary.State.isRegistering
            )
        );
        vm.startPrank(OWNER);
        simpleVoting.endVoting();
        vm.stopPrank();
    }

    function testGetWinner() public registeredAndVoted inClosedPhase {
        (string memory winnerName, VotingLibrary.Candidate memory winnerStruct) = simpleVoting.getWinner();
        assertEq(winnerName, CANDIDATE_1);
        assertEq(
            keccak256(abi.encode(winnerStruct)), keccak256(abi.encode(simpleVoting.getCandidateByName(CANDIDATE_1)))
        );
    }

    function testGetWinnerNotInClosedPhase() public registeredAndVoted {
        vm.expectRevert(
            abi.encodeWithSelector(
                VotingLibrary.WRONG__PHASE.selector, VotingLibrary.State.isClosed, VotingLibrary.State.isVoting
            )
        );
        simpleVoting.getWinner();
    }

    function testGetCandidateNames() public register(voters, candidates) {
        assertEq(candidates, simpleVoting.getCandidateNames());
    }
}
