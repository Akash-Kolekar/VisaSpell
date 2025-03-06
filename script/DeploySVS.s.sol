// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {StudentVisaSystem} from "../src/StudentVisaSystem.sol";

contract DeploySVS is Script {
    function run() external returns (StudentVisaSystem) {
        // vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        vm.startBroadcast();
        StudentVisaSystem svs = new StudentVisaSystem();
        vm.stopBroadcast();
        return svs;
    }
}
