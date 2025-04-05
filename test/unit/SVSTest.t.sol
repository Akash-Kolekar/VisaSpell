// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {Test, console} from "forge-std/Test.sol";
// import {DeploySVS} from "../../script/DeploySVS.s.sol";
// import {DeployOtherSC} from "../../script/DeployOtherSC.s.sol";
// import {StudentVisaSystem} from "../../src/StudentVisaSystem.sol";
// import {VerificationHub} from "../../src/VerificationHub.sol";
// import {FeeManager} from "../../src/FeeManager.sol";
// import {TimelineEnhancer} from "../../src/TimelineEnhancer.sol";
// import {UniversityHandler} from "../../src/UniversityHandler.sol";
// import {EmbassyGateway} from "../../src/EmbassyGateway.sol";

// contract SVSTest is Test {
//     DeploySVS deployer;
//     StudentVisaSystem visaSystem;
//     VerificationHub verificationHub;
//     FeeManager feeManager;
//     TimelineEnhancer timelineEnhancer;
//     UniversityHandler universityHandler;
//     EmbassyGateway embassyGateway;
//     DeployOtherSC deployerOtherSC;

//     // address public admin = makeAddr("admin");
//     address public student = makeAddr("student");
//     // address public university = makeAddr("university");
//     // address public treasury = makeAddr("treasury");

//     bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

//     address public admin = 0xB58634C4465D93A03801693FD6d76997C797e42A;
//     address public university = 0x04F136a9B269e1efb6eB6E9D24cb2884BdbfFb11;
//     address public treasury = 0x76b1e60A5Bdd0954C951Ff91Ce40675c87F74507;
//     address public verifierOnVerificationHub = 0x781Bd01f97e86278397DA8C762D67E66bc67238E;

//     string public constant UNIVERSITY_ID = "uni_123";
//     string public constant PROGRAM_ID = "cs_2023";
//     string[] public previousCountries;

//     // Test document data
//     string public constant DOC_HASH = "QmXYZ123";
//     uint256 public constant VALID_EXPIRY = 365 days;
//     uint256 public constant EXPIRED_EXPIRY = 1 days;

//     function setUp() public {
//         deployer = new DeploySVS();

//         (visaSystem, embassyGateway, feeManager, timelineEnhancer, universityHandler, verificationHub) = deployer.run();

//         vm.startPrank(admin);
//         universityHandler.grantRole(university, universityHandler.UNIVERSITY_ROLE());

//         // visaSystem.grantRole(verifierOnVerificationHub, verificationHub.VERIFIER_ROLE());
//         // visaSystem.grantRole(verifierOnVerificationHub, visaSystem.VERIFICATION_HUB_ROLE());
//         verificationHub.grantRole(address(verificationHub), DEFAULT_ADMIN_ROLE);
//         visaSystem.grantRole(address(verificationHub), visaSystem.VERIFICATION_HUB_ROLE());
//         // visaSystem.grantRole(address(visaSystem), visaSystem.VERIFICATION_HUB_ROLE());
//         verificationHub.grantRole(address(visaSystem), visaSystem.VERIFICATION_HUB_ROLE());
//         // verificationHub.grantRole(address(visaSystem), DEFAULT_ADMIN_ROLE);
//         // verificationHub.initializeRoles();

//         // Setup university
//         universityHandler.registerUniversity(university, UNIVERSITY_ID);
//         vm.stopPrank();

//         vm.startPrank(address(university));
//         universityHandler.registerProgram(PROGRAM_ID);

//         vm.stopPrank();

//         test_CreateApplicationSuccess1();
//     }

//     function test_CreateApplicationSuccess1() public {
//         uint32 enrollmentDate = uint32(block.timestamp + 60 days);
//         StudentVisaSystem.Priority priority = StudentVisaSystem.Priority.STANDARD;
//         (uint256 requiredFee,) = visaSystem.getFeeAndProcessingTime(priority);

//         vm.startPrank(student);
//         vm.deal(student, 10 ether);

//         // Pay application fee
//         (bool success,) =
//             address(feeManager).call{value: requiredFee}(abi.encodeWithSignature("payWithETH(address)", student));
//         require(success, "Fee payment failed");
//         console.log("Fee Manager balance:", address(feeManager).balance);

//         // Create application
//         vm.expectEmit(true, true, true, true);
//         // emit StudentVisaSystem.ApplicationCreated(student, block.timestamp, priority);
//         // emit StudentVisaSystem.FeePaid(student, requiredFee, priority);

//         visaSystem.createApplication(UNIVERSITY_ID, PROGRAM_ID, enrollmentDate, priority, previousCountries);

//         // Verify application state
//         (StudentVisaSystem.VisaStatus status,, uint256 createdAt) = visaSystem.getApplicationCore(student);
//         assertEq(uint256(status), uint256(StudentVisaSystem.VisaStatus.DOCUMENTS_PENDING));
//         console.log("StudentVisaSystem.VisaStatus.DOCUMENTS_PENDING:", uint256(status));
//         assertEq(createdAt, block.timestamp);
//         assertTrue(visaSystem.hasApplication(student));

//         // Verify fee tracking
//         assertEq(feeManager.getTotalPaid(student), requiredFee);

//         console.log("Fee Manager balance:", address(feeManager).balance);
//         assertEq(address(treasury).balance, requiredFee);
//     }

//     function test_SubmitDocumentByApplicant_1() public {
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
// }
