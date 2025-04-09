// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {UniversityHandler} from "../../src/UniversityHandler.sol";

contract VerifyAdmission is Script {
    // Anvil's default account #1 (University)
    address constant UNIVERSITY = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    // Anvil's default account #4 (Applicant)
    address constant APPLICANT = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;

    // Replace with your deployed contract address
    address constant UNIVERSITY_HANDLER_ADDRESS = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;

    // Anvil's account #1 private key
    uint256 constant UNIVERSITY_PRIVATE_KEY = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;

    function run() external {
        vm.startBroadcast(UNIVERSITY_PRIVATE_KEY);

        UniversityHandler universityHandler = UniversityHandler(UNIVERSITY_HANDLER_ADDRESS);

        // University verifies admission
        universityHandler.verifyAdmission(APPLICANT, "CS101");

        console.log("Admission verified for applicant:", APPLICANT);

        vm.stopBroadcast();
    }
}
