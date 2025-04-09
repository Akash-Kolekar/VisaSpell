// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StudentVisaSystem} from "../../src/StudentVisaSystem.sol";

/**
 * @title Create Application Script
 * @notice Creates a new visa application - Run by applicant
 */
contract CreateApplication is Script {
    // Contract address
    address constant SVS_ADDRESS = 0xE57f598BaA132F479862eC7b9AA52E792E3282A7;

    // Applicant account
    address constant APPLICANT_ACCOUNT = 0xB58634C4465D93A03801693FD6d76997C797e42A;

    // Application details
    string universityId = "Harvard";
    string programId = "CS101";

    function run() external {
        vm.startBroadcast(APPLICANT_ACCOUNT);

        StudentVisaSystem svs = StudentVisaSystem(SVS_ADDRESS);

        console.log("Applicant address: %s", APPLICANT_ACCOUNT);
        console.log("Creating application for %s at %s", programId, universityId);

        // Calculate enrollment date (6 months from now)
        uint32 enrollmentDate = uint32(block.timestamp + 180 days);

        // Get required fee
        uint256 standardFee = svs.standardFee();
        console.log("Required fee: %s wei", standardFee);

        // Create application
        svs.createApplication{value: standardFee}(
            universityId,
            programId,
            enrollmentDate,
            StudentVisaSystem.Priority.STANDARD,
            new string[](0) // Empty array for previous countries
        );

        console.log("Application created successfully");

        vm.stopBroadcast();
    }
}
