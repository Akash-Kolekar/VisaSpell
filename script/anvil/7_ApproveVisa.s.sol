// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StudentVisaSystem} from "../../src/StudentVisaSystem.sol";

contract ApproveVisa is Script {
    // Anvil's default account #2 (Embassy)
    address constant EMBASSY = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    // Anvil's default account #4 (Applicant)
    address constant APPLICANT = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;

    // Replace with your deployed contract address
    address constant SVS_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;

    // Anvil's account #2 private key
    uint256 constant EMBASSY_PRIVATE_KEY = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    function run() external {
        vm.startBroadcast(EMBASSY_PRIVATE_KEY);

        StudentVisaSystem svs = StudentVisaSystem(SVS_ADDRESS);

        // Approve visa
        svs.approveVisa(APPLICANT);

        console.log("Visa approved for applicant:", APPLICANT);

        vm.stopBroadcast();
    }
}
