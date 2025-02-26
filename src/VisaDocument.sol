// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Layout of Contract:
// version
// imports
// interfaces, libraries, contracts
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

/**
 * @title VisaProcessing
 * @author Akash Kolekar
 * @notice This contract is a simple contract to manage the visa processing for students
 * @dev The VisaDocument contract is a simple contract to manage the visa processing for students
 * It allows students to submit their documents and get them verified by the university, embassy and bank
 * The contract also allows the students to pay the application fee and visa fee
 *
 */
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/// @title VisaDocument
/// @notice Contract for managing document verification in student visa applications
contract VisaDocument is AccessControl, Pausable {
    bytes32 public constant UNIVERSITY_ROLE = keccak256("UNIVERSITY_ROLE");
    bytes32 public constant EMBASSY_ROLE = keccak256("EMBASSY_ROLE");
    bytes32 public constant BANK_ROLE = keccak256("BANK_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    enum DocumentType {
        PASSPORT,
        ACADEMIC_RECORDS,
        FINANCIAL_PROOF,
        ACCEPTANCE_LETTER,
        BACKGROUND_CHECK
    }

    enum VerificationStatus {
        NOT_SUBMITTED,
        SUBMITTED,
        VERIFIED,
        REJECTED
    }

    enum VisaStatus {
        NOT_STARTED,
        DOCUMENTS_PENDING,
        UNDER_REVIEW,
        ADDITIONAL_DOCUMENTS_REQUIRED,
        APPROVED,
        REJECTED
    }

    struct Document {
        string documentHash;
        VerificationStatus status;
        address verifiedBy;
        uint256 timestamp;
        string comments;
    }

    struct Application {
        address applicant;
        mapping(DocumentType => Document) documents;
        VisaStatus status;
        uint256 createdAt;
        uint256 updatedAt;
        string universityId;
        uint256 expectedEnrollmentDate;
    }

    mapping(address => Application) public applications;
    mapping(address => bool) public hasApplication;

    event ApplicationCreated(address indexed applicant, uint256 timestamp);
    event DocumentSubmitted(address indexed applicant, DocumentType docType, string documentHash);
    event DocumentVerified(address indexed applicant, DocumentType docType, address verifier);
    event DocumentRejected(address indexed applicant, DocumentType docType, address verifier, string reason);
    event ApplicationStatusUpdated(address indexed applicant, VisaStatus status);
    event ApplicationRejected(address indexed applicant, string reason);
    event TimelineCritical(address indexed applicant, uint256 daysUntilEnrollment);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    //Modifiers
    modifier onlyApplicant() {
        require(hasApplication[msg.sender], "No application exists");
        _;
    }

    //////////////
    //Functions //
    //////////////

    //////////////////////////
    /// External Functions ///
    //////////////////////////

    function createApplication(string calldata universityId, uint256 enrollmentDate) external {
        require(!hasApplication[msg.sender], "Application already exists");
        require(enrollmentDate > block.timestamp, "Enrollment date must be in the future");

        Application storage app = applications[msg.sender];
        app.applicant = msg.sender;
        app.status = VisaStatus.DOCUMENTS_PENDING;
        app.createdAt = block.timestamp;
        app.updatedAt = block.timestamp;
        app.universityId = universityId;
        app.expectedEnrollmentDate = enrollmentDate;

        hasApplication[msg.sender] = true;

        emit ApplicationCreated(msg.sender, block.timestamp);
    }

    function submitDocument(DocumentType docType, string calldata documentHash) external onlyApplicant {
        require(bytes(documentHash).length > 0, "Empty document hash");

        Application storage app = applications[msg.sender];

        require(app.status != VisaStatus.APPROVED, "Application already approved");
        require(app.status != VisaStatus.REJECTED, "Application already rejected");

        Document storage doc = app.documents[docType];
        doc.documentHash = documentHash;
        doc.status = VerificationStatus.SUBMITTED;
        doc.timestamp = block.timestamp;

        app.updatedAt = block.timestamp;

        emit DocumentSubmitted(msg.sender, docType, documentHash);

        _checkTimelineCritical(msg.sender);
    }

    function resubmitDocument(DocumentType docType, string calldata newHash) external onlyApplicant {
        Application storage app = applications[msg.sender];
        require(app.status == VisaStatus.ADDITIONAL_DOCUMENTS_REQUIRED, "Not in resubmission");
        require(bytes(newHash).length > 0, "Empty document hash");

        Document storage doc = app.documents[docType];
        require(doc.status == VerificationStatus.REJECTED, "Document not rejected");

        doc.documentHash = newHash;
        doc.status = VerificationStatus.SUBMITTED;
        doc.comments = "";
        app.updatedAt = block.timestamp;

        emit DocumentSubmitted(msg.sender, docType, newHash);
    }

    function verifyDocument(address applicant, DocumentType docType) external {
        require(
            hasRole(UNIVERSITY_ROLE, msg.sender) || hasRole(EMBASSY_ROLE, msg.sender) || hasRole(BANK_ROLE, msg.sender),
            "Not authorized to verify documents"
        );

        require(hasApplication[applicant], "Application does not exist");

        Application storage app = applications[applicant];
        Document storage doc = app.documents[docType];

        require(doc.status == VerificationStatus.SUBMITTED, "Document not submitted or already verified");

        doc.status = VerificationStatus.VERIFIED;
        doc.verifiedBy = msg.sender;
        doc.timestamp = block.timestamp;

        app.updatedAt = block.timestamp;

        emit DocumentVerified(applicant, docType, msg.sender);

        _checkAllDocumentsVerified(applicant);
    }

    function rejectDocument(address applicant, DocumentType docType, string calldata reason) external {
        require(
            hasRole(UNIVERSITY_ROLE, msg.sender) || hasRole(EMBASSY_ROLE, msg.sender) || hasRole(BANK_ROLE, msg.sender),
            "Not authorized to reject documents"
        );

        require(hasApplication[applicant], "Application does not exist");

        Application storage app = applications[applicant];
        Document storage doc = app.documents[docType];

        require(doc.status == VerificationStatus.SUBMITTED, "Document not submitted or already processed");

        doc.status = VerificationStatus.REJECTED;
        doc.verifiedBy = msg.sender;
        doc.timestamp = block.timestamp;
        doc.comments = reason;

        app.status = VisaStatus.ADDITIONAL_DOCUMENTS_REQUIRED;
        app.updatedAt = block.timestamp;

        emit DocumentRejected(applicant, docType, msg.sender, reason);
        emit ApplicationStatusUpdated(applicant, VisaStatus.ADDITIONAL_DOCUMENTS_REQUIRED);
    }

    function _checkAllDocumentsVerified(address applicant) internal {
        Application storage app = applications[applicant];

        bool allVerified = app.documents[DocumentType.PASSPORT].status == VerificationStatus.VERIFIED
            && app.documents[DocumentType.ACADEMIC_RECORDS].status == VerificationStatus.VERIFIED
            && app.documents[DocumentType.FINANCIAL_PROOF].status == VerificationStatus.VERIFIED
            && app.documents[DocumentType.ACCEPTANCE_LETTER].status == VerificationStatus.VERIFIED
            && app.documents[DocumentType.BACKGROUND_CHECK].status == VerificationStatus.VERIFIED;

        // Check if all required documents are verified
        if (allVerified) {
            app.status = VisaStatus.UNDER_REVIEW;
            emit ApplicationStatusUpdated(applicant, VisaStatus.UNDER_REVIEW);
        }
    }

    function _checkTimelineCritical(address applicant) internal {
        Application storage app = applications[applicant];

        uint256 daysUntilEnrollment = (app.expectedEnrollmentDate - block.timestamp) / 1 days;

        if (daysUntilEnrollment <= 30) {
            emit TimelineCritical(applicant, daysUntilEnrollment);
        }
    }

    function approveVisa(address applicant) external {
        require(hasRole(EMBASSY_ROLE, msg.sender), "Only embassy can approve visa");
        require(hasApplication[applicant], "Application does not exist");

        Application storage app = applications[applicant];
        require(app.status == VisaStatus.UNDER_REVIEW, "Application not under review");

        app.status = VisaStatus.APPROVED;
        app.updatedAt = block.timestamp;

        emit ApplicationStatusUpdated(applicant, VisaStatus.APPROVED);
    }

    function rejectVisa(address applicant, string calldata reason) external {
        require(hasRole(EMBASSY_ROLE, msg.sender), "Only embassy can reject visa");
        require(hasApplication[applicant], "Application does not exist");

        Application storage app = applications[applicant];
        require(app.status != VisaStatus.APPROVED && app.status != VisaStatus.REJECTED, "Application already processed");

        app.status = VisaStatus.REJECTED;
        app.updatedAt = block.timestamp;

        emit ApplicationStatusUpdated(applicant, VisaStatus.REJECTED);
        emit ApplicationRejected(applicant, reason);
    }

    function getDocumentStatus(address applicant, DocumentType docType) external view returns (VerificationStatus) {
        require(hasApplication[applicant], "Application does not exist");
        return applications[applicant].documents[docType].status;
    }

    function getApplicationStatus(address applicant) external view returns (VisaStatus) {
        require(hasApplication[applicant], "Application does not exist");
        return applications[applicant].status;
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}
