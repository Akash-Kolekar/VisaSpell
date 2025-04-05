// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import {Test, console} from "forge-std/Test.sol";
// import {StudentVisaSystem} from "../../src/StudentVisaSystem.sol";
// import {UniversityHandler} from "../../src/UniversityHandler.sol";
// import {FeeManager} from "../../src/FeeManager.sol";
// import {DeploySVS} from "../../script/DeploySVS.s.sol";
// import {VerificationHub} from "../../src/VerificationHub.sol";
// import {TimelineEnhancer} from "../../src/TimelineEnhancer.sol";
// import {EmbassyGateway} from "../../src/EmbassyGateway.sol";
// import {DeployOtherSC} from "../../script/DeployOtherSC.s.sol";

// contract SubmitDocumentTest is Test {
//     DeploySVS deployer;
//     StudentVisaSystem visaSystem;
//     VerificationHub verificationHub;
//     FeeManager feeManager;
//     TimelineEnhancer timelineEnhancer;
//     UniversityHandler universityHandler;
//     EmbassyGateway embassyGateway;
//     DeployOtherSC deployerOtherSC;

//     address public admin = makeAddr("admin");
//     address public student = makeAddr("student");
//     address public university = makeAddr("university");
//     address public attacker = makeAddr("attacker");
//     address public treasury = makeAddr("treasury");

//     string public constant UNIVERSITY_ID = "uni_123";
//     string public constant PROGRAM_ID = "cs_2023";
//     string[] public previousCountries;

//     // Test document data
//     string public constant DOC_HASH = "QmXYZ123";
//     uint256 public constant VALID_EXPIRY = 365 days;
//     uint256 public constant EXPIRED_EXPIRY = 1 days;

//     function setUp() public {
//         vm.startPrank(admin);

//         deployer = new DeploySVS();

//         (visaSystem, embassyGateway, feeManager, timelineEnhancer, universityHandler, verificationHub) = deployer.run();

//         vm.startPrank(admin);
//         universityHandler.grantRole(university, universityHandler.UNIVERSITY_ROLE());

//         // Setup university
//         universityHandler.registerUniversity(university, UNIVERSITY_ID);
//         vm.stopPrank();

//         vm.startPrank(address(university));
//         universityHandler.registerProgram(PROGRAM_ID);

//         vm.stopPrank();

//         // Fund student and create application
//         vm.deal(student, 1 ether);
//         vm.stopPrank();

//         _createValidApplication();
//     }

//     function test_SubmitDocumentByApplicant() public {
//         vm.startPrank(student);
//         vm.deal(student, 10 ether);

//         vm.expectEmit(true, true, true, true);
//         emit StudentVisaSystem.DocumentSubmitted(student, StudentVisaSystem.DocumentType.PASSPORT, DOC_HASH);

//         visaSystem.submitDocument(
//             student, StudentVisaSystem.DocumentType.PASSPORT, DOC_HASH, block.timestamp + VALID_EXPIRY
//         );

//         // Verify document state
//         StudentVisaSystem.VerificationStatus status =
//             visaSystem.getDocumentStatus(student, StudentVisaSystem.DocumentType.PASSPORT);
//         assertEq(uint256(status), uint256(StudentVisaSystem.VerificationStatus.SUBMITTED));
//     }

//     function test_SubmitDocumentByUniversity() public {
//         vm.startPrank(university);

//         visaSystem.submitDocument(
//             student, StudentVisaSystem.DocumentType.ACCEPTANCE_LETTER, DOC_HASH, block.timestamp + VALID_EXPIRY
//         );

//         StudentVisaSystem.VerificationStatus status =
//             visaSystem.getDocumentStatus(student, StudentVisaSystem.DocumentType.ACCEPTANCE_LETTER);
//         assertEq(uint256(status), uint256(StudentVisaSystem.VerificationStatus.SUBMITTED));
//     }

//     function test_RevertIfUnauthorizedSubmitter() public {
//         vm.startPrank(attacker);

//         vm.expectRevert("Unauthorized");
//         visaSystem.submitDocument(
//             student, StudentVisaSystem.DocumentType.PASSPORT, DOC_HASH, block.timestamp + VALID_EXPIRY
//         );
//     }

//     function test_RevertIfDocumentExpired() public {
//         vm.startPrank(student);

//         vm.expectRevert("Document already expired");
//         visaSystem.submitDocument(
//             student,
//             StudentVisaSystem.DocumentType.PASSPORT,
//             DOC_HASH,
//             block.timestamp - 1 // Expired
//         );
//     }

//     function test_RevertIfInvalidApplication() public {
//         address invalidApplicant = makeAddr("invalid");

//         vm.startPrank(student);
//         vm.expectRevert("No application exists");
//         visaSystem.submitDocument(
//             invalidApplicant, StudentVisaSystem.DocumentType.PASSPORT, DOC_HASH, block.timestamp + VALID_EXPIRY
//         );
//     }

//     function test_RevertIfApprovedApplication() public {
//         // Approve application first
//         vm.prank(admin);
//         visaSystem.grantRole(visaSystem.EMBASSY_ROLE(), admin);

//         vm.prank(admin);
//         visaSystem.approveVisa(student);

//         // Try submitting document
//         vm.startPrank(student);
//         vm.expectRevert("Application already approved");
//         visaSystem.submitDocument(
//             student, StudentVisaSystem.DocumentType.PASSPORT, DOC_HASH, block.timestamp + VALID_EXPIRY
//         );
//     }

//     // Helper to create valid application
//     function _createValidApplication() internal {
//         vm.startPrank(student);
//         feeManager.payWithETH{value: 0.01 ether}(student);

//         visaSystem.createApplication(
//             UNIVERSITY_ID,
//             PROGRAM_ID,
//             uint32(block.timestamp + 60 days),
//             StudentVisaSystem.Priority.STANDARD,
//             previousCountries
//         );
//         vm.stopPrank();
//     }
// }
