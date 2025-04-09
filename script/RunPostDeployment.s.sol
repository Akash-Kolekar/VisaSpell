// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StudentVisaSystem} from "../src/StudentVisaSystem.sol";
import {EmbassyGateway} from "../src/EmbassyGateway.sol";
import {FeeManager} from "../src/FeeManager.sol";
import {TimelineEnhancer} from "../src/TimelineEnhancer.sol";
import {UniversityHandler} from "../src/UniversityHandler.sol";
import {VerificationHub} from "../src/VerificationHub.sol";

/**
 * @title Run Post-Deployment Single Broadcast
 * @notice Setup script that uses a single broadcast with pranks for all operations
 */
contract RunPostDeployment is Script {
    // Contract instances
    StudentVisaSystem svs;
    EmbassyGateway embassyGateway;
    FeeManager feeManager;
    TimelineEnhancer timelineEnhancer;
    UniversityHandler universityHandler;
    VerificationHub verificationHub;

    // Actual contract addresses from Sepolia
    address constant SVS_ADDRESS = 0xE57f598BaA132F479862eC7b9AA52E792E3282A7;
    address constant EMBASSY_GATEWAY_ADDRESS = 0x611646DE9FF0615249652939E3ee2813D35Eca10;
    address constant FEE_MANAGER_ADDRESS = 0x6Ad58B6725D603f593b201b1cd3B760Be6e1d235;
    address constant TIMELINE_ENHANCER_ADDRESS = 0xe492a1868F986255E8de329B77d9beFEAD320D90;
    address constant UNIVERSITY_HANDLER_ADDRESS = 0x024a9f709e15F9Bd0B4a1535E1c4a740dCa8893D;
    address constant VERIFICATION_HUB_ADDRESS = 0x2b5DF1B6BD26602188497D8F13C45A79932d2a4f;

    // Entity addresses
    address constant ADMIN_ADDRESS = 0xB58634C4465D93A03801693FD6d76997C797e42A;
    address constant UNIVERSITY_ADDRESS = 0x04F136a9B269e1efb6eB6E9D24cb2884BdbfFb11;
    address constant EMBASSY_ADDRESS = 0xAF8E81e74bA006134493a92D1EAACb8686e86A93;
    address constant VERIFIER_ADDRESS = 0x781Bd01f97e86278397DA8C762D67E66bc67238E;
    address constant APPLICANT_ADDRESS = 0xB58634C4465D93A03801693FD6d76997C797e42A;

    // Application settings
    string constant UNIVERSITY_ID = "Harvard";
    string constant PROGRAM_ID = "CS101";
    uint32 enrollmentDate;
    uint256 documentExpiryDate;

    function run() external {
        // Initialize contract references
        svs = StudentVisaSystem(SVS_ADDRESS);
        embassyGateway = EmbassyGateway(EMBASSY_GATEWAY_ADDRESS);
        feeManager = FeeManager(payable(FEE_MANAGER_ADDRESS));
        timelineEnhancer = TimelineEnhancer(TIMELINE_ENHANCER_ADDRESS);
        universityHandler = UniversityHandler(UNIVERSITY_HANDLER_ADDRESS);
        verificationHub = VerificationHub(VERIFICATION_HUB_ADDRESS);

        // Set dates
        enrollmentDate = uint32(block.timestamp + 180 days);
        documentExpiryDate = block.timestamp + 365 days;

        // Single broadcast for all operations
        vm.startBroadcast(ADMIN_ADDRESS);

        // STEP 1: Initialize roles as ADMIN
        console.log("Initializing roles...");

        // Acting as admin
        svs.grantRole(svs.UNIVERSITY_ROLE(), UNIVERSITY_ADDRESS);
        svs.grantRole(svs.EMBASSY_ROLE(), EMBASSY_ADDRESS);
        svs.grantRole(svs.BANK_ROLE(), VERIFIER_ADDRESS);
        verificationHub.registerVerifier(VERIFIER_ADDRESS, "Official Document Verifier");
        embassyGateway.registerEmbassyOfficial(EMBASSY_ADDRESS);
        universityHandler.registerUniversity(UNIVERSITY_ADDRESS, UNIVERSITY_ID);

        // STEP 2: University actions - this works if ADMIN_ADDRESS is impersonating UNIVERSITY_ADDRESS
        console.log("Registering university program...");

        // Note: This is the key point - we don't need vm.startBroadcast for UNIVERSITY_ADDRESS
        // We're still broadcasting as ADMIN_ADDRESS but telling the EVM we're making the call from UNIVERSITY_ADDRESS
        vm.prank(UNIVERSITY_ADDRESS);
        universityHandler.registerProgram(PROGRAM_ID);

        // If the sample flow is enabled and ADMIN is the applicant
        if (vm.envBool("INCLUDE_SAMPLE_FLOW") && ADMIN_ADDRESS == APPLICANT_ADDRESS) {
            console.log("Processing sample application flow...");

            // Create application
            uint256 standardFee = svs.standardFee();
            svs.createApplication{value: standardFee}(
                UNIVERSITY_ID, PROGRAM_ID, enrollmentDate, StudentVisaSystem.Priority.STANDARD, new string[](0)
            );

            // Submit documents
            svs.submitDocument(
                APPLICANT_ADDRESS, StudentVisaSystem.DocumentType.PASSPORT, "passportHash", documentExpiryDate
            );
            svs.submitDocument(
                APPLICANT_ADDRESS, StudentVisaSystem.DocumentType.ACADEMIC_RECORDS, "academicHash", documentExpiryDate
            );
            svs.submitDocument(
                APPLICANT_ADDRESS, StudentVisaSystem.DocumentType.FINANCIAL_PROOF, "financialHash", documentExpiryDate
            );
            svs.submitDocument(
                APPLICANT_ADDRESS,
                StudentVisaSystem.DocumentType.LANGUAGE_PROFICIENCY,
                "languageHash",
                documentExpiryDate
            );
            svs.submitBiometricVerification("biometricHash");

            // University verifies admission
            vm.prank(UNIVERSITY_ADDRESS);
            universityHandler.verifyAdmission(APPLICANT_ADDRESS, PROGRAM_ID);

            // Verifier verifies documents
            vm.prank(VERIFIER_ADDRESS);
            svs.verifyDocument(APPLICANT_ADDRESS, StudentVisaSystem.DocumentType.PASSPORT, "Verified passport");

            vm.prank(VERIFIER_ADDRESS);
            svs.verifyDocument(APPLICANT_ADDRESS, StudentVisaSystem.DocumentType.ACADEMIC_RECORDS, "Verified records");

            vm.prank(VERIFIER_ADDRESS);
            svs.verifyDocument(APPLICANT_ADDRESS, StudentVisaSystem.DocumentType.FINANCIAL_PROOF, "Verified financial");

            vm.prank(VERIFIER_ADDRESS);
            svs.verifyDocument(APPLICANT_ADDRESS, StudentVisaSystem.DocumentType.ACCEPTANCE_LETTER, "Verified letter");

            vm.prank(VERIFIER_ADDRESS);
            svs.verifyDocument(APPLICANT_ADDRESS, StudentVisaSystem.DocumentType.LANGUAGE_PROFICIENCY, "Verified lang");

            // Embassy approves visa
            vm.prank(EMBASSY_ADDRESS);
            svs.approveVisa(APPLICANT_ADDRESS);
        }

        vm.stopBroadcast();

        console.log("Post-deployment setup completed successfully");
    }
}
