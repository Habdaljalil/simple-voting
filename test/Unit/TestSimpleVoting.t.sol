// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;


import {Test} from "../../lib/forge-std/src/Test.sol";
import {DeploySimpleVoting} from "../../script/DeploySimpleVoting.s.sol";
import {SimpleVoting} from "../../src/SimpleVoting.sol";
import {VotingLibrary} from "../../src/VotingLibrary.sol";


contract TestSimpleVoting is Test {
    SimpleVoting private simpleVoting;
    address private OWNER = makeAddr("Hassan");


    function setUp() public {
        DeploySimpleVoting deploySimpleVoting = new DeploySimpleVoting();
        simpleVoting = deploySimpleVoting.run(OWNER);
    }

    function testOwner() public view {
        assertEq(OWNER, simpleVoting.getOwner());
    }

    function testRegisterVoter() public {
        address voter = makeAddr("Voter #1");

        vm.startPrank(OWNER);
        simpleVoting.registerVoter(voter);
        
        vm.stopPrank();

        VotingLibrary.Voter memory voterStruct = simpleVoting.getAddressToVoter(voter);

        assertEq(voterStruct.isRegistered, true);
    }


}