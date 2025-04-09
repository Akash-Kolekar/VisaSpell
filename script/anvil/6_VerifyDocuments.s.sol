// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StudentVisaSystem} from "../../src/StudentVisaSystem.sol";

contract VerifyDocuments is Script {
    // Anvil's default account #3 (Verifier)
    address constant VERIFIER = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;

    // Anvil's default account #4 (Applicant)
    address constant APPLICANT = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;

    // Replace with your deployed contract address
    address constant SVS_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;

    // Anvil's account #3 private key
    uint256 constant VERIFIER_PRIVATE_KEY = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    function run() external {
        vm.startBroadcast(VERIFIER_PRIVATE_KEY);

        StudentVisaSystem svs = StudentVisaSystem(SVS_ADDRESS);

        // Verify documents
        svs.verifyDocument(APPLICANT, StudentVisaSystem.DocumentType.PASSPORT, "Verified passport");

        svs.verifyDocument(APPLICANT, StudentVisaSystem.DocumentType.ACADEMIC_RECORDS, "Verified academic records");

        svs.verifyDocument(APPLICANT, StudentVisaSystem.DocumentType.FINANCIAL_PROOF, "Verified financial proof");

        svs.verifyDocument(APPLICANT, StudentVisaSystem.DocumentType.ACCEPTANCE_LETTER, "Verified acceptance letter");

        svs.verifyDocument(
            APPLICANT, StudentVisaSystem.DocumentType.LANGUAGE_PROFICIENCY, "Verified language proficiency"
        );

        console.log("Documents verified for applicant:", APPLICANT);

        vm.stopBroadcast();
    }
}
