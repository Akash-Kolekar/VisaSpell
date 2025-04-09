// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StudentVisaSystem} from "../../src/StudentVisaSystem.sol";

/**
 * @title Verify Documents Script
 * @notice Verifies submitted documents - Run by verifier
 */
contract VerifyDocuments is Script {
    // Contract address
    address constant SVS_ADDRESS = 0xE57f598BaA132F479862eC7b9AA52E792E3282A7;

    // Verifier account
    address constant VERIFIER_ACCOUNT = 0x781Bd01f97e86278397DA8C762D67E66bc67238E;

    // Applicant to verify
    address constant APPLICANT_ADDRESS = 0xB58634C4465D93A03801693FD6d76997C797e42A;

    function run() external {
        vm.startBroadcast(VERIFIER_ACCOUNT);

        StudentVisaSystem svs = StudentVisaSystem(SVS_ADDRESS);

        console.log("Verifier address: %s", VERIFIER_ACCOUNT);
        console.log("Verifying documents for: %s", APPLICANT_ADDRESS);

        // Verify documents
        svs.verifyDocument(APPLICANT_ADDRESS, StudentVisaSystem.DocumentType.PASSPORT, "Passport verified");

        svs.verifyDocument(
            APPLICANT_ADDRESS, StudentVisaSystem.DocumentType.ACADEMIC_RECORDS, "Academic records verified"
        );

        svs.verifyDocument(
            APPLICANT_ADDRESS, StudentVisaSystem.DocumentType.FINANCIAL_PROOF, "Financial proof verified"
        );

        svs.verifyDocument(
            APPLICANT_ADDRESS, StudentVisaSystem.DocumentType.ACCEPTANCE_LETTER, "Acceptance letter verified"
        );

        svs.verifyDocument(
            APPLICANT_ADDRESS, StudentVisaSystem.DocumentType.LANGUAGE_PROFICIENCY, "Language proficiency verified"
        );

        console.log("Documents verified successfully");

        vm.stopBroadcast();
    }
}
