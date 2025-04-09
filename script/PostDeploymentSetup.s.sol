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
 * @title Post Deployment Setup Script
 * @notice This script handles all post-deployment operations for the Student Visa System
 * @dev It automates role assignments, entity registrations, and a complete application flow
 */
contract PostDeploymentSetup is Script {
    // Contract instances
    StudentVisaSystem public svs;
    EmbassyGateway public embassyGateway;
    FeeManager public feeManager;
    TimelineEnhancer public timelineEnhancer;
    UniversityHandler public universityHandler;
    VerificationHub public verificationHub;

    // Main account that deploys and administers the system
    address public admin;

    // Test accounts - in production, replace with actual addresses
    address public university = 0xBAdD41a60a8B2fE17c09B52f9996fD145C99c67c;
    address public embassy = 0x23738189Bb7Fd5EDa4920d684d10bA34D491c11A;
    address public verifier = 0x8CD9214A3653AB4EfB6c3e3Fa8f17c46f7A25c6c;
    address public applicant = 0x7a41378a76A273F20929F2FC7C8D2c1e1DD42e45;
    address public treasury = 0x76b1e60A5Bdd0954C951Ff91Ce40675c87F74507;

    // Application data
    string public universityId = "Harvard";
    string public programId = "CS101";
    uint32 public enrollmentDate;
    string[] public previousVisaCountries;

    // Document values
    uint256 public documentExpiryDate;
    string public passportHash = "QmPassportDocumentHash";
    string public academicHash = "QmAcademicRecordsHash";
    string public financialHash = "QmFinancialProofHash";
    string public languageHash = "QmLanguageProficiencyHash";
    string public biometricHash = "QmBiometricHash";

    // Add a broadcast tracking flag to the contract
    bool private _isBroadcasting = false;

    constructor(
        address _svs,
        address _embassyGateway,
        address _feeManager,
        address _timelineEnhancer,
        address _universityHandler,
        address _verificationHub
    ) {
        svs = StudentVisaSystem(_svs);
        embassyGateway = EmbassyGateway(_embassyGateway);
        feeManager = FeeManager(payable(_feeManager));
        timelineEnhancer = TimelineEnhancer(_timelineEnhancer);
        universityHandler = UniversityHandler(_universityHandler);
        verificationHub = VerificationHub(_verificationHub);

        admin = msg.sender;

        // Initialize dates
        enrollmentDate = uint32(block.timestamp + 180 days);
        documentExpiryDate = block.timestamp + 365 days;
    }

    /**
     * @notice Sets custom addresses for entities
     */
    function setCustomAddresses(address _university, address _embassy, address _verifier, address _applicant)
        external
    {
        university = _university;
        embassy = _embassy;
        verifier = _verifier;
        applicant = _applicant;
    }

    /**
     * @notice Main function to run the full setup
     */
    function run() external {
        // Use our own flag instead of vm.isBroadcasting()
        if (!_isBroadcasting) {
            _isBroadcasting = true;
            vm.startBroadcast(admin);
        }

        // Step 1: Initialize all roles
        initializeRoles();

        // Step 2: Register entities
        registerEntities();

        // Step 3: Run sample application flow (optional in production)
        if (vm.envBool("INCLUDE_SAMPLE_FLOW")) {
            processSampleApplication();
        }

        if (_isBroadcasting) {
            vm.stopBroadcast();
            _isBroadcasting = false;
        }

        console.log("Post-deployment setup completed successfully");
    }

    /**
     * @notice Initialize all necessary roles
     */
    function initializeRoles() public {
        bool localBroadcast = !_isBroadcasting;

        if (localBroadcast) {
            _isBroadcasting = true;
            vm.startBroadcast(admin);
        }

        // Grant roles in StudentVisaSystem
        svs.grantRole(svs.UNIVERSITY_ROLE(), university);
        svs.grantRole(svs.EMBASSY_ROLE(), embassy);
        svs.grantRole(svs.BANK_ROLE(), verifier);

        // Register verifier in VerificationHub
        verificationHub.registerVerifier(verifier, "Official Document Verifier");

        // Register embassy official
        embassyGateway.registerEmbassyOfficial(embassy);

        if (localBroadcast) {
            vm.stopBroadcast();
            _isBroadcasting = false;
        }

        console.log("Roles initialized successfully");
    }

    /**
     * @notice Register universities and programs
     */
    function registerEntities() public {
        bool localBroadcast = !_isBroadcasting;

        if (localBroadcast) {
            _isBroadcasting = true;
            vm.startBroadcast(admin);
        }

        // Register university
        universityHandler.registerUniversity(university, universityId);

        if (localBroadcast) {
            vm.stopBroadcast();
            _isBroadcasting = false;
        }

        // University registers program
        vm.startBroadcast(university);
        universityHandler.registerProgram(programId);
        vm.stopBroadcast();

        console.log("Entities registered successfully");
    }

    /**
     * @notice Process a sample application from start to finish
     */
    function processSampleApplication() public {
        // 1. Create application
        createApplication();

        // 2. Submit documents
        submitDocuments();

        // 3. University verifies admission
        verifyAdmission();

        // 4. Verify documents
        verifyDocuments();

        // 5. Approve visa
        approveVisa();

        console.log("Sample application processed successfully");
    }

    /**
     * @notice Create a new visa application
     */
    function createApplication() public {
        bool localBroadcast = !_isBroadcasting;

        if (localBroadcast) {
            _isBroadcasting = true;
            vm.startBroadcast(admin);
        }

        // Fund applicant with ETH for fees
        vm.deal(applicant, 1 ether);

        // Create application
        vm.startBroadcast(applicant);
        uint256 standardFee = svs.standardFee();
        svs.createApplication{value: standardFee}(
            universityId, programId, enrollmentDate, StudentVisaSystem.Priority.STANDARD, previousVisaCountries
        );
        vm.stopBroadcast();

        if (localBroadcast) {
            vm.stopBroadcast();
            _isBroadcasting = false;
        }

        console.log("Application created successfully");
    }

    /**
     * @notice Submit all required documents
     */
    function submitDocuments() public {
        bool localBroadcast = !_isBroadcasting;

        if (localBroadcast) {
            _isBroadcasting = true;
            vm.startBroadcast(admin);
        }

        vm.startBroadcast(applicant);

        // Submit passport
        svs.submitDocument(applicant, StudentVisaSystem.DocumentType.PASSPORT, passportHash, documentExpiryDate);

        // Submit academic records
        svs.submitDocument(applicant, StudentVisaSystem.DocumentType.ACADEMIC_RECORDS, academicHash, documentExpiryDate);

        // Submit financial proof
        svs.submitDocument(applicant, StudentVisaSystem.DocumentType.FINANCIAL_PROOF, financialHash, documentExpiryDate);

        // Submit language proficiency
        svs.submitDocument(
            applicant, StudentVisaSystem.DocumentType.LANGUAGE_PROFICIENCY, languageHash, documentExpiryDate
        );

        // Submit biometric verification
        svs.submitBiometricVerification(biometricHash);

        vm.stopBroadcast();

        if (localBroadcast) {
            vm.stopBroadcast();
            _isBroadcasting = false;
        }

        console.log("Documents submitted successfully");
    }

    /**
     * @notice University verifies admission
     */
    function verifyAdmission() public {
        bool localBroadcast = !_isBroadcasting;

        if (localBroadcast) {
            _isBroadcasting = true;
            vm.startBroadcast(admin);
        }

        vm.startBroadcast(university);
        universityHandler.verifyAdmission(applicant, programId);
        vm.stopBroadcast();

        if (localBroadcast) {
            vm.stopBroadcast();
            _isBroadcasting = false;
        }

        console.log("Admission verified successfully");
    }

    /**
     * @notice Verify all submitted documents
     */
    function verifyDocuments() public {
        bool localBroadcast = !_isBroadcasting;

        if (localBroadcast) {
            _isBroadcasting = true;
            vm.startBroadcast(admin);
        }

        vm.startBroadcast(verifier);

        // Verify all documents
        svs.verifyDocument(applicant, StudentVisaSystem.DocumentType.PASSPORT, "Verified passport");
        svs.verifyDocument(applicant, StudentVisaSystem.DocumentType.ACADEMIC_RECORDS, "Verified academic records");
        svs.verifyDocument(applicant, StudentVisaSystem.DocumentType.FINANCIAL_PROOF, "Verified financial proof");
        svs.verifyDocument(applicant, StudentVisaSystem.DocumentType.ACCEPTANCE_LETTER, "Verified acceptance letter");
        svs.verifyDocument(
            applicant, StudentVisaSystem.DocumentType.LANGUAGE_PROFICIENCY, "Verified language proficiency"
        );

        vm.stopBroadcast();

        if (localBroadcast) {
            vm.stopBroadcast();
            _isBroadcasting = false;
        }

        console.log("Documents verified successfully");
    }

    /**
     * @notice Embassy approves visa
     */
    function approveVisa() public {
        bool localBroadcast = !_isBroadcasting;

        if (localBroadcast) {
            _isBroadcasting = true;
            vm.startBroadcast(admin);
        }

        vm.startBroadcast(embassy);
        svs.approveVisa(applicant);
        vm.stopBroadcast();

        if (localBroadcast) {
            vm.stopBroadcast();
            _isBroadcasting = false;
        }

        console.log("Visa approved successfully");
    }

    /**
     * @notice Alternative function to reject visa
     */
    function rejectVisa() public {
        bool localBroadcast = !_isBroadcasting;

        if (localBroadcast) {
            _isBroadcasting = true;
            vm.startBroadcast(admin);
        }

        vm.startBroadcast(embassy);
        svs.rejectVisa(applicant, "Application does not meet requirements");
        vm.stopBroadcast();

        if (localBroadcast) {
            vm.stopBroadcast();
            _isBroadcasting = false;
        }

        console.log("Visa rejected");
    }

    /**
     * @notice Check application status - useful for monitoring
     */
    function checkApplicationStatus() public view returns (StudentVisaSystem.VisaStatus) {
        return svs.getApplicationStatus(applicant);
    }
}
