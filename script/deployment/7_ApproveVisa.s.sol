// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StudentVisaSystem} from "../../src/StudentVisaSystem.sol";

/**
 * @title Approve Visa Script
 * @notice Approves visa application - Run by embassy
 */
contract ApproveVisa is Script {
    // Contract address
    address constant SVS_ADDRESS = 0xE57f598BaA132F479862eC7b9AA52E792E3282A7;

    // Embassy account
    address constant EMBASSY_ACCOUNT = 0xAF8E81e74bA006134493a92D1EAACb8686e86A93;

    // Applicant to approve
    address constant APPLICANT_ADDRESS = 0xB58634C4465D93A03801693FD6d76997C797e42A;

    function run() external {
        vm.startBroadcast(EMBASSY_ACCOUNT);

        // Get embassy's private key from environment
        uint256 embassyPrivateKey = vm.envUint("PRIVATE_KEY");
        address embassyAddress = vm.addr(embassyPrivateKey);

        StudentVisaSystem svs = StudentVisaSystem(SVS_ADDRESS);

        console.log("Embassy address: %s", embassyAddress);
        console.log("Approving visa for: %s", APPLICANT_ADDRESS);

        // Approve visa
        svs.approveVisa(APPLICANT_ADDRESS);

        console.log("Visa approved successfully");

        vm.stopBroadcast();
    }
}
