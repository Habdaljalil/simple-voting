// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Script} from "../lib/forge-std/src/Script.sol";
import {SimpleVoting} from "../src/SimpleVoting.sol";

contract DeploySimpleVoting is Script {
    SimpleVoting simpleVoting;

    function run(address owner) public returns (SimpleVoting) {
        vm.startPrank(owner);
        simpleVoting = new SimpleVoting();
        vm.stopPrank();

        return simpleVoting;
    }
}
