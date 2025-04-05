// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.20;

// import {Test, console} from "forge-std/Test.sol";
// import {StudentVisaSystem} from "../../src/StudentVisaSystem.sol";
// import {UniversityHandler} from "../../src/UniversityHandler.sol";
// import {FeeManager} from "../../src/FeeManager.sol";

// contract StudentVisaSystemTest is Test {
//     StudentVisaSystem public visaSystem;
//     UniversityHandler public universityHandler;
//     FeeManager public feeManager;

//     address public admin = makeAddr("admin");
//     address public student = makeAddr("student");
//     address public university = makeAddr("university");
//     address public treasury = makeAddr("treasury");

//     string public constant UNIVERSITY_ID = "uni_123";
//     string public constant PROGRAM_ID = "cs_2023";
//     string[] public previousCountries;

//     function setUp() public {
//         vm.startPrank(admin);

//         // Deploy contracts
//         visaSystem = new StudentVisaSystem();
//         universityHandler = new UniversityHandler(address(visaSystem));
//         feeManager = new FeeManager(treasury);

//         // Initialize dependencies
//         visaSystem.initializeDependencies(
//             address(universityHandler),
//             address(0), // verificationHub
//             address(feeManager),
//             address(0) // timelineEnhancer
//         );

//         universityHandler.grantRole(address(university), universityHandler.UNIVERSITY_ROLE());

//         // Setup university
//         universityHandler.registerUniversity(university, UNIVERSITY_ID);
//         vm.stopPrank();

//         vm.startPrank(address(university));
//         universityHandler.registerProgram(PROGRAM_ID);

//         vm.stopPrank();
//     }

//     // Happy path test
//     function test_CreateApplicationSuccess() public {
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
//         emit StudentVisaSystem.ApplicationCreated(student, block.timestamp, priority);
//         emit StudentVisaSystem.FeePaid(student, requiredFee, priority);

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

//     // // Edge cases
//     // function test_RevertIfDuplicateApplication() public {
//     //     _createValidApplication();

//     //     vm.expectRevert("Application already exists");
//     //     _createValidApplication();
//     // }

//     // function test_RevertIfInvalidProgram() public {
//     //     StudentVisaSystem.Priority priority = StudentVisaSystem.Priority.STANDARD;
//     //     (uint256 requiredFee,) = visaSystem.getFeeAndProcessingTime(priority);
//     //     vm.startPrank(student);

//     //     _payFee(requiredFee);

//     //     vm.expectRevert("Invalid program");
//     //     visaSystem.createApplication(
//     //         "invalid_id",
//     //         PROGRAM_ID,
//     //         uint32(block.timestamp + 60 days),
//     //         StudentVisaSystem.Priority.STANDARD,
//     //         previousCountries
//     //     );
//     // }

//     // function test_RevertIfInsufficientFee() public {
//     //     vm.startPrank(student);
//     //     _payFee(0.005 ether); // Below standard fee

//     //     vm.expectRevert("Insufficient fee");
//     //     _createValidApplication();
//     // }

//     // // Helper functions
//     // function _createValidApplication() internal {
//     //     visaSystem.createApplication(
//     //         UNIVERSITY_ID,
//     //         PROGRAM_ID,
//     //         uint32(block.timestamp + 60 days),
//     //         StudentVisaSystem.Priority.STANDARD,
//     //         previousCountries
//     //     );
//     // }

//     // function _payFee(uint256 amount) internal {
//     //     (bool success,) =
//     //         address(feeManager).call{value: amount}(abi.encodeWithSignature("payWithETH(address)", student));
//     //     require(success, "Fee payment failed");
//     // }
// }
