// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {StudentVisaSystem} from "../src/StudentVisaSystem.sol";
import {VerificationHub} from "../src/VerificationHub.sol";
import {UniversityHandler} from "../src/UniversityHandler.sol";
import {FeeManager} from "../src/FeeManager.sol";
import {TimelineEnhancer} from "../src/TimelineEnhancer.sol";
import {EmbassyGateway} from "../src/EmbassyGateway.sol";
import {DeploySVS} from "../script/DeploySVS.s.sol";

contract StudentVisaSystemTest is Test {
    StudentVisaSystem svs;
    VerificationHub verificationHub;
    UniversityHandler universityHandler;
    FeeManager feeManager;
    TimelineEnhancer timelineEnhancer;
    EmbassyGateway embassyGateway;

    // address admin = 0xB58634C4465D93A03801693FD6d76997C797e42A;
    address admin = makeAddr("admin");
    address applicant1 = makeAddr("applicant1");
    address applicant2 = makeAddr("applicant2");
    address university = makeAddr("university");
    address embassy = makeAddr("embassy");
    address verifier = makeAddr("verifier");
    address treasury = makeAddr("treasury");

    string universityId = "Stanford";
    string programId = "CS101";
    uint32 enrollmentDate;
    string[] previousVisaCountries;

    // Test values
    uint256 documentExpiryDate = block.timestamp + 365 days;
    string documentHash = "QmDocumentHash123";
    string biometricHash = "QmBiometricHash123";

    function setUp() public {
        // Generate test admin address
        admin = makeAddr("admin");
        vm.startPrank(admin);

        // Deploy all contracts using the deployment script
        DeploySVS deployer = new DeploySVS();
        deployer.setTestMode(true); // Set to test mode to avoid broadcasting
        (svs, embassyGateway, feeManager, timelineEnhancer, universityHandler, verificationHub) = deployer.run();

        // Grant necessary admin roles to our test admin for each contract
        // To fix the error, we need to transfer admin roles
        address deployScript = address(deployer);

        // Fix: Grant DEFAULT_ADMIN_ROLE to our test admin in UniversityHandler
        vm.stopPrank();
        vm.startPrank(deployScript); // Need to be the original deployer
        universityHandler.grantRole(universityHandler.DEFAULT_ADMIN_ROLE(), admin);
        verificationHub.grantRole(verificationHub.DEFAULT_ADMIN_ROLE(), admin);
        svs.grantRole(svs.DEFAULT_ADMIN_ROLE(), admin);
        feeManager.grantRole(feeManager.DEFAULT_ADMIN_ROLE(), admin);
        timelineEnhancer.grantRole(timelineEnhancer.DEFAULT_ADMIN_ROLE(), admin);
        embassyGateway.grantRole(embassyGateway.DEFAULT_ADMIN_ROLE(), admin);
        vm.stopPrank();

        // Now continue with admin operations
        vm.startPrank(admin);

        // Additional role assignment - grant university address the UNIVERSITY_ROLE
        svs.grantRole(svs.UNIVERSITY_ROLE(), university);

        // Grant BANK_ROLE directly to the verifier from admin
        svs.grantRole(svs.BANK_ROLE(), verifier);

        // Set up test values
        enrollmentDate = uint32(block.timestamp + 180 days);

        // Register a university and program for testing
        universityHandler.registerUniversity(university, universityId);
        vm.stopPrank();

        vm.startPrank(university);
        universityHandler.registerProgram(programId);
        vm.stopPrank();

        // Register embassy official
        vm.startPrank(admin);
        svs.grantRole(svs.EMBASSY_ROLE(), embassy);

        // Register verifier
        verificationHub.registerVerifier(verifier, "Test Verifier");
        vm.stopPrank();

        // Give ether to test accounts
        vm.deal(applicant1, 10 ether);
        vm.deal(applicant2, 10 ether);
    }

    function testCreateApplication() public {
        vm.startPrank(applicant1);

        // Create a standard application
        uint256 requiredFee = svs.standardFee();
        svs.createApplication{value: requiredFee}(
            universityId, programId, enrollmentDate, StudentVisaSystem.Priority.STANDARD, previousVisaCountries
        );

        // Verify application was created successfully
        assertTrue(svs.hasApplication(applicant1), "Application should exist");

        // Check application status
        StudentVisaSystem.VisaStatus status = svs.getApplicationStatus(applicant1);
        assertEq(
            uint256(status),
            uint256(StudentVisaSystem.VisaStatus.DOCUMENTS_PENDING),
            "Application should be pending documents"
        );

        vm.stopPrank();
    }

    function testDocumentSubmissionAndVerification() public {
        // First create an application
        testCreateApplication();

        // Submit passport document
        vm.startPrank(applicant1);
        svs.submitDocument(applicant1, StudentVisaSystem.DocumentType.PASSPORT, documentHash, documentExpiryDate);

        // Verify document status
        StudentVisaSystem.VerificationStatus docStatus =
            svs.getDocumentStatus(applicant1, StudentVisaSystem.DocumentType.PASSPORT);
        assertEq(
            uint256(docStatus), uint256(StudentVisaSystem.VerificationStatus.SUBMITTED), "Document should be submitted"
        );
        vm.stopPrank();

        // Verify the document as a verifier
        vm.startPrank(verifier);
        // Find the request ID (in a real test we would need a way to get this)
        // For this example we need to assume the verification hub has a way to find pending requests

        // We would normally call:
        // bytes32 requestId = /* method to get pending request */;
        // verificationHub.processVerification(requestId, true);

        // Since we can't easily get the request ID in this test,
        // we'll use the direct verification method from SVS
        vm.stopPrank();

        vm.startPrank(verifier);
        svs.verifyDocument(applicant1, StudentVisaSystem.DocumentType.PASSPORT, "Document is valid");

        // Verify document status after verification
        vm.stopPrank();
        vm.startPrank(applicant1);
        docStatus = svs.getDocumentStatus(applicant1, StudentVisaSystem.DocumentType.PASSPORT);
        assertEq(
            uint256(docStatus), uint256(StudentVisaSystem.VerificationStatus.VERIFIED), "Document should be verified"
        );
        vm.stopPrank();
    }

    function testCompleteApplicationProcess() public {
        // Create application
        testCreateApplication();

        // Submit all required documents
        vm.startPrank(applicant1);
        svs.submitDocument(applicant1, StudentVisaSystem.DocumentType.PASSPORT, "passportHash", documentExpiryDate);

        svs.submitDocument(
            applicant1, StudentVisaSystem.DocumentType.ACADEMIC_RECORDS, "academicHash", documentExpiryDate
        );

        svs.submitDocument(
            applicant1, StudentVisaSystem.DocumentType.FINANCIAL_PROOF, "financialHash", documentExpiryDate
        );

        // Add language proficiency document
        svs.submitDocument(
            applicant1, StudentVisaSystem.DocumentType.LANGUAGE_PROFICIENCY, "languageHash", documentExpiryDate
        );

        // Submit biometric verification
        svs.submitBiometricVerification(biometricHash);
        vm.stopPrank();

        // University submits acceptance letter
        vm.startPrank(university);
        universityHandler.verifyAdmission(applicant1, programId);
        vm.stopPrank();

        // Verify all documents as a verifier
        vm.startPrank(verifier);
        svs.verifyDocument(applicant1, StudentVisaSystem.DocumentType.PASSPORT, "Passport verified");

        svs.verifyDocument(applicant1, StudentVisaSystem.DocumentType.ACADEMIC_RECORDS, "Academic records verified");

        svs.verifyDocument(applicant1, StudentVisaSystem.DocumentType.FINANCIAL_PROOF, "Financial proof verified");

        svs.verifyDocument(applicant1, StudentVisaSystem.DocumentType.ACCEPTANCE_LETTER, "Acceptance letter verified");

        // After verifying other documents, also verify language proficiency
        svs.verifyDocument(applicant1, StudentVisaSystem.DocumentType.LANGUAGE_PROFICIENCY, "Language test verified");
        vm.stopPrank();

        // Check if application status changed to under review
        StudentVisaSystem.VisaStatus status = svs.getApplicationStatus(applicant1);
        assertEq(
            uint256(status), uint256(StudentVisaSystem.VisaStatus.UNDER_REVIEW), "Application should be under review"
        );

        // Embassy approves the visa
        vm.startPrank(embassy);
        svs.approveVisa(applicant1);
        vm.stopPrank();

        // Check final status
        status = svs.getApplicationStatus(applicant1);
        assertEq(uint256(status), uint256(StudentVisaSystem.VisaStatus.APPROVED), "Application should be approved");
    }

    function testUpgradePriority() public {
        // Create standard application
        testCreateApplication();

        vm.startPrank(applicant1);

        // Get initial priority
        StudentVisaSystem.Priority initialPriority = svs.getTimelinePriority(applicant1);
        assertEq(
            uint256(initialPriority),
            uint256(StudentVisaSystem.Priority.STANDARD),
            "Initial priority should be standard"
        );

        // Calculate additional fee (expedited - standard)
        uint256 additionalFee = svs.expeditedFee() - svs.standardFee();

        // Upgrade to expedited
        svs.upgradeProcessingPriority{value: additionalFee}(StudentVisaSystem.Priority.EXPEDITED);

        // Verify new priority
        StudentVisaSystem.Priority newPriority = svs.getTimelinePriority(applicant1);
        assertEq(
            uint256(newPriority),
            uint256(StudentVisaSystem.Priority.EXPEDITED),
            "Priority should be upgraded to expedited"
        );

        vm.stopPrank();
    }

    function testRejectionAndReset() public {
        // Create application and submit documents
        testCreateApplication();

        // Submit passport document
        vm.startPrank(applicant1);
        svs.submitDocument(applicant1, StudentVisaSystem.DocumentType.PASSPORT, documentHash, documentExpiryDate);
        vm.stopPrank();

        // Verify document to move application to review status
        vm.startPrank(verifier);
        svs.verifyDocument(applicant1, StudentVisaSystem.DocumentType.PASSPORT, "Document verified");
        // Submit other documents and verify them...
        vm.stopPrank();

        // Reject the application
        vm.prank(embassy);
        svs.rejectVisa(applicant1, "Missing essential documents");

        // Verify rejection
        StudentVisaSystem.VisaStatus status = svs.getApplicationStatus(applicant1);
        assertEq(uint256(status), uint256(StudentVisaSystem.VisaStatus.REJECTED), "Application should be rejected");

        // Reset application
        vm.prank(applicant1);
        svs.resetApplication();

        // Verify application is deleted
        bool hasApp = svs.hasApplication(applicant1);
        assertFalse(hasApp, "Application should be deleted after reset");
    }
}
