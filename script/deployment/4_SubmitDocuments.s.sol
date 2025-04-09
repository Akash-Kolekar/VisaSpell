// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StudentVisaSystem} from "../../src/StudentVisaSystem.sol";

/**
 * @title Submit Documents Script
 * @notice Submits required documents for a visa application - Run by applicant
 */
contract SubmitDocuments is Script {
    // Contract address
    address constant SVS_ADDRESS = 0xE57f598BaA132F479862eC7b9AA52E792E3282A7;

    // Applicant account
    address constant APPLICANT_ACCOUNT = 0xB58634C4465D93A03801693FD6d76997C797e42A;

    function run() external {
        vm.startBroadcast(APPLICANT_ACCOUNT);

        // Get applicant's private key from environment
        uint256 applicantPrivateKey = vm.envUint("PRIVATE_KEY");
        address applicantAddress = vm.addr(applicantPrivateKey);

        StudentVisaSystem svs = StudentVisaSystem(SVS_ADDRESS);

        console.log("Applicant address: %s", applicantAddress);
        console.log("Submitting documents...");

        // Document expiry (1 year from now)
        uint256 documentExpiryDate = block.timestamp + 365 days;

        // Submit required documents
        svs.submitDocument(
            applicantAddress, StudentVisaSystem.DocumentType.PASSPORT, "passportHash", documentExpiryDate
        );

        svs.submitDocument(
            applicantAddress, StudentVisaSystem.DocumentType.ACADEMIC_RECORDS, "academicHash", documentExpiryDate
        );

        svs.submitDocument(
            applicantAddress, StudentVisaSystem.DocumentType.FINANCIAL_PROOF, "financialHash", documentExpiryDate
        );

        svs.submitDocument(
            applicantAddress, StudentVisaSystem.DocumentType.LANGUAGE_PROFICIENCY, "languageHash", documentExpiryDate
        );

        // Submit biometric verification
        svs.submitBiometricVerification("biometricHash");

        console.log("Documents submitted successfully");

        vm.stopBroadcast();
    }
}
