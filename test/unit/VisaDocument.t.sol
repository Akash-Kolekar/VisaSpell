// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {VisaDocument} from "../../src/VisaDocument.sol";
import {DeployVisaDocument} from "../../script/VisaDocument.s.sol";

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

            /* AccessControl: only in unit test */
contract VisaDocumentTest is Test, AccessControl {

    VisaDocument visaDoc;

    address Banker = makeAddr("Banker");
    address Alice = makeAddr("Alice");
    address Kylie = makeAddr("Kylie");
    
    function setUp() public {
        DeployVisaDocument deployment = new DeployVisaDocument();
        visaDoc = deployment.run();
    }

    /*//////////////////////////////////////////////////////////////
                              Failure Test
    //////////////////////////////////////////////////////////////*/

    function test_createApplication_revert() public {
        // current local timestamp == 1 .... so lame :D 
        console.log(block.timestamp);
        skip(100e18 days);

        ///////////////////////////////////////////////////////////
        /////////// registered user cannot register again
        ///////////////////////////////////////////////////////////
        visaDoc.createApplication("APU-1", block.timestamp + 100e18 days);

        vm.expectRevert(
            abi.encodePacked(
                "Application already exists"
            )
        );
        visaDoc.createApplication("APU-1", block.timestamp + 100e18 days);
        
        ///////////////////////////////////////////////////////////
        /////////// enrollment date should be in future
        ///////////////////////////////////////////////////////////
        vm.startPrank(Kylie);

        // test current date
        vm.expectRevert(
            abi.encodePacked(
                "Enrollment date must be in the future"
            )
        );
        visaDoc.createApplication("APU-1", block.timestamp);

        // test past date
        vm.expectRevert(
            abi.encodePacked(
                "Enrollment date must be in the future"
            )
        );
        visaDoc.createApplication("APU-1", block.timestamp - 1e18 days);

        vm.stopPrank();
    }

    function test_submitDocument_revert() public {
        ///////////////////////////////////////////////////////////
        /////////// should call ``submitDocument()`` to register first
        ///////////////////////////////////////////////////////////
        
        vm.expectRevert(
            abi.encodePacked(
                "No application exists"
            )
        );
        visaDoc.submitDocument(VisaDocument.DocumentType.PASSPORT, "FAKE_PASSPORT");

        ///////////////////////////////////////////////////////////
        /////////// empty string is not allowed
        ///////////////////////////////////////////////////////////

        visaDoc.createApplication("APU-1", block.timestamp + 100e18 days);
        vm.expectRevert(
            abi.encodePacked(
                "Empty document hash"
            )
        );
        visaDoc.submitDocument(VisaDocument.DocumentType.PASSPORT, "");
    }
 
    /*//////////////////////////////////////////////////////////////
                           test registration
    //////////////////////////////////////////////////////////////*/    

    function test_can_create_application_and_submit_document() public {
        vm.startPrank(Alice);
        
        ///////////////////////////////////////////////////////////
        /////////// register
        ///////////////////////////////////////////////////////////

        vm.expectEmit(true, false, false, true);
        emit VisaDocument.ApplicationCreated(Alice, block.timestamp);
        
        // set 50 days left before enrollment to university
        uint enrollmentDate = block.timestamp + 50 days;
        visaDoc.createApplication("APU-1", enrollmentDate);

        ///////////////////////////////////////////////////////////
        /////////// submit documents after 10 days 
        ///////////////////////////////////////////////////////////
        skip(10 days); // OPTIONAL, but not after enrollment date
        
        // PASSPORT
        VisaDocument.DocumentType PASSPORT = VisaDocument.DocumentType.PASSPORT;      

        vm.expectEmit(true, false, false, true);
        emit VisaDocument.DocumentSubmitted(Alice, PASSPORT, "PASSPORT");

        visaDoc.submitDocument(PASSPORT, "PASSPORT");

        ///////////////////////////////////////////////////////////
        /////////// check assertion
        ///////////////////////////////////////////////////////////

        (
            address applicant,
            uint256 visaStatus,
            uint256 createdAt,
            uint256 updatedAt,
            string memory universityId,
            uint256 expectedEnrollmentDate,
            /* 👇 nested struct in ``Application.documents``👇 */
            string memory documentHash,
            uint256 documentStatus,
            address verifiedBy,
            uint256 timestamp,
            string memory comments
        ) = visaDoc.getApplications(Alice, 0); // docType == 0: PASSPORT

        assertEq(applicant, Alice);
        assertEq(visaStatus, uint(VisaDocument.VisaStatus.DOCUMENTS_PENDING));
        assertEq(createdAt, block.timestamp - 10 days);
        assertEq(updatedAt, block.timestamp);
        assertEq(universityId, "APU-1");
        assertEq(expectedEnrollmentDate, enrollmentDate);

        assertEq(documentHash, "PASSPORT");
        assertEq(documentStatus, uint(VisaDocument.VerificationStatus.SUBMITTED));
        assertEq(verifiedBy, address(0)); // not yet
        assertEq(timestamp, block.timestamp);
        assertEq(comments, ""); // not yet

        vm.stopPrank();
    }

    /// @notice will fix soon ...
    /*
    bytes32 BANK_ROLE = keccak256("BANK_ROLE");
    function test_can_verify_documents() public {
        vm.startPrank(Kylie);

        ///////////////////////////////////////////////////////////
        /////////// register
        ///////////////////////////////////////////////////////////

        uint enrollmentDate = block.timestamp + 50 days;
        visaDoc.createApplication("INTI-1", enrollmentDate);

        ///////////////////////////////////////////////////////////
        /////////// submit documents
        ///////////////////////////////////////////////////////////

        VisaDocument.DocumentType PASSPORT = VisaDocument.DocumentType.PASSPORT;    
        visaDoc.submitDocument(PASSPORT, "PASSPORT");

        vm.stopPrank();
        ///////////////////////////////////////////////////////////
        /////////// verify documents
        ///////////////////////////////////////////////////////////           

        bool ok = _grantRole(BANK_ROLE, Banker);
        assert(ok);

        vm.prank(Banker);
        visaDoc.verifyDocument(Kylie, PASSPORT);


    }
    */

}
