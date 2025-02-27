// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {UniversityRegistry} from "../src/UniversityRegistry.sol";

contract DeployUniversityRegistry is Script {

    address Manager = makeAddr("Manager");

    function run() public returns(UniversityRegistry) {

        vm.startBroadcast(Manager);
        UniversityRegistry registry = new UniversityRegistry();
        vm.stopBroadcast();

        return registry;

    }

}
