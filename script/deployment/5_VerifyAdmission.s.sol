// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {UniversityHandler} from "../../src/UniversityHandler.sol";

/**
 * @title Verify Admission Script
 * @notice Verifies student admission - Run by university
 */
contract VerifyAdmission is Script {
    // Contract address
    address constant UNIVERSITY_HANDLER_ADDRESS = 0x024a9f709e15F9Bd0B4a1535E1c4a740dCa8893D;

    // University account
    address constant UNIVERSITY_ACCOUNT = 0x04F136a9B269e1efb6eB6E9D24cb2884BdbfFb11;

    // Program details
    string constant PROGRAM_ID = "CS101";

    // Applicant to verify
    address constant APPLICANT_ADDRESS = 0xB58634C4465D93A03801693FD6d76997C797e42A;

    function run() external {
        vm.startBroadcast(UNIVERSITY_ACCOUNT);

        UniversityHandler universityHandler = UniversityHandler(UNIVERSITY_HANDLER_ADDRESS);

        console.log("University address: %s", UNIVERSITY_ACCOUNT);
        console.log("Verifying admission for: %s", APPLICANT_ADDRESS);

        // Verify admission
        universityHandler.verifyAdmission(APPLICANT_ADDRESS, PROGRAM_ID);

        console.log("Admission verified successfully");

        vm.stopBroadcast();
    }
}
