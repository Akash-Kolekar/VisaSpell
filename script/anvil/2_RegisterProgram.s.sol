// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {UniversityHandler} from "../../src/UniversityHandler.sol";

contract RegisterProgram is Script {
    // Anvil's default account #1 (University)
    address constant UNIVERSITY = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    // Replace with your deployed contract address
    address constant UNIVERSITY_HANDLER_ADDRESS = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;

    function run() external {
        vm.startBroadcast(UNIVERSITY);

        UniversityHandler universityHandler = UniversityHandler(UNIVERSITY_HANDLER_ADDRESS);

        // Register multiple programs
        universityHandler.registerProgram("CS101");
        universityHandler.registerProgram("ENG201");
        universityHandler.registerProgram("MED301");
        universityHandler.registerProgram("BUS401");

        console.log("Programs registered successfully by University", UNIVERSITY);

        vm.stopBroadcast();
    }
}
