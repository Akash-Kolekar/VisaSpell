// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StudentVisaSystem} from "../../src/StudentVisaSystem.sol";

contract UpgradePriority is Script {
    // Anvil's default account #4 (Applicant)
    address constant APPLICANT = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;

    // Replace with your deployed contract address
    address constant SVS_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;

    // Anvil's account #4 private key
    uint256 constant APPLICANT_PRIVATE_KEY = 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a;

    function run() external {
        vm.startBroadcast(APPLICANT_PRIVATE_KEY);

        StudentVisaSystem svs = StudentVisaSystem(SVS_ADDRESS);

        // Calculate additional fee (expedited - standard)
        uint256 standardFee = svs.standardFee();
        uint256 expeditedFee = svs.expeditedFee();
        uint256 additionalFee = expeditedFee - standardFee;

        // Upgrade to expedited processing
        svs.upgradeProcessingPriority{value: additionalFee}(StudentVisaSystem.Priority.EXPEDITED);

        console.log("Application priority upgraded for applicant:", APPLICANT);

        vm.stopBroadcast();
    }
}
