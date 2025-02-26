// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract VisaDocument is AccessControl, Pausable {
    using SafeERC20 for IERC20;

    // Roles
    bytes32 public constant UNIVERSITY_ROLE = keccak256("UNIVERSITY_ROLE");
    bytes32 public constant EMBASSY_ROLE = keccak256("EMBASSY_ROLE");
    bytes32 public constant BANK_ROLE = keccak256("BANK_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Fees
    uint256 public constant APPLICATION_FEE = 0.1 ether;
    uint256 public constant VISA_FEE = 0.5 ether;
    address public feeRecipient; // Secure wallet for fee collection

    // Document and Status Enums
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

    // Application Structure
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
        bool applicationFeePaid;
        bool visaFeePaid;
    }

    // State Variables
    mapping(address => Application) public applications;
    mapping(address => bool) public hasApplication;

    // Events
    event ApplicationCreated(address indexed applicant, uint256 timestamp);
    event DocumentSubmitted(address indexed applicant, DocumentType docType, string documentHash);
    event DocumentVerified(address indexed applicant, DocumentType docType, address verifier);
    event DocumentRejected(address indexed applicant, DocumentType docType, address verifier, string reason);
    event ApplicationStatusUpdated(address indexed applicant, VisaStatus status);
    event ApplicationRejected(address indexed applicant, string reason);
    event TimelineCritical(address indexed applicant, uint256 daysUntilEnrollment);
    event FeesUpdated(uint256 newApplicationFee, uint256 newVisaFee);
    event FeesPaid(address indexed applicant, uint256 amount, bool isVisaFee);

    constructor(address _feeRecipient) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        feeRecipient = _feeRecipient;
    }

    // Modifiers
    modifier onlyApplicant() {
        require(hasApplication[msg.sender], "No application exists");
        _;
    }

    // Core Functions
    function createApplication(string calldata universityId, uint256 enrollmentDate) external payable {
        require(!hasApplication[msg.sender], "Application exists");
        require(enrollmentDate > block.timestamp, "Invalid enrollment date");
        require(msg.value == APPLICATION_FEE, "Incorrect application fee");

        Application storage app = applications[msg.sender];
        app.applicant = msg.sender;
        app.status = VisaStatus.DOCUMENTS_PENDING;
        app.createdAt = block.timestamp;
        app.updatedAt = block.timestamp;
        app.universityId = universityId;
        app.expectedEnrollmentDate = enrollmentDate;
        app.applicationFeePaid = true;

        hasApplication[msg.sender] = true;
        _safeTransferETH(msg.value);

        emit ApplicationCreated(msg.sender, block.timestamp);
    }

    function submitDocument(DocumentType docType, string calldata documentHash) external onlyApplicant {
        require(bytes(documentHash).length > 0, "Empty document hash");

        Application storage app = applications[msg.sender];
        require(app.status != VisaStatus.APPROVED, "Application approved");
        require(app.status != VisaStatus.REJECTED, "Application rejected");

        Document storage doc = app.documents[docType];
        doc.documentHash = documentHash;
        doc.status = VerificationStatus.SUBMITTED;
        doc.timestamp = block.timestamp;
        app.updatedAt = block.timestamp;

        emit DocumentSubmitted(msg.sender, docType, documentHash);
        // _checkTimelineCritical(msg.sender);
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

    // Verification Functions
    function verifyDocument(address applicant, DocumentType docType) external {
        require(
            hasRole(UNIVERSITY_ROLE, msg.sender) || hasRole(EMBASSY_ROLE, msg.sender) || hasRole(BANK_ROLE, msg.sender),
            "Unauthorized"
        );

        Application storage app = applications[applicant];
        Document storage doc = app.documents[docType];

        require(doc.status == VerificationStatus.SUBMITTED, "Document not submitted");

        doc.status = VerificationStatus.VERIFIED;
        doc.verifiedBy = msg.sender;
        doc.timestamp = block.timestamp;
        app.updatedAt = block.timestamp;

        emit DocumentVerified(applicant, docType, msg.sender);
        _checkAllDocumentsVerified(applicant);
    }

    // Fee Payment Functions
    function payVisaFee() external payable onlyApplicant {
        Application storage app = applications[msg.sender];
        require(app.status == VisaStatus.APPROVED, "Visa not approved");
        require(msg.value == VISA_FEE, "Incorrect visa fee");

        app.visaFeePaid = true;
        _safeTransferETH(msg.value);
        emit FeesPaid(msg.sender, msg.value, true);
    }

    // View Functions
    function getDocumentHashes(address applicant) external view returns (string[5] memory) {
        require(hasApplication[applicant], "No application");
        Application storage app = applications[applicant];

        return [
            app.documents[DocumentType.PASSPORT].documentHash,
            app.documents[DocumentType.ACADEMIC_RECORDS].documentHash,
            app.documents[DocumentType.FINANCIAL_PROOF].documentHash,
            app.documents[DocumentType.ACCEPTANCE_LETTER].documentHash,
            app.documents[DocumentType.BACKGROUND_CHECK].documentHash
        ];
    }

    // Internal Functions
    function _checkAllDocumentsVerified(address applicant) internal {
        Application storage app = applications[applicant];

        bool allVerified = app.documents[DocumentType.PASSPORT].status == VerificationStatus.VERIFIED
            && app.documents[DocumentType.ACADEMIC_RECORDS].status == VerificationStatus.VERIFIED
            && app.documents[DocumentType.FINANCIAL_PROOF].status == VerificationStatus.VERIFIED
            && app.documents[DocumentType.ACCEPTANCE_LETTER].status == VerificationStatus.VERIFIED
            && app.documents[DocumentType.BACKGROUND_CHECK].status == VerificationStatus.VERIFIED;

        if (allVerified) {
            app.status = VisaStatus.UNDER_REVIEW;
            emit ApplicationStatusUpdated(applicant, VisaStatus.UNDER_REVIEW);
        }
    }

    function _safeTransferETH(uint256 amount) internal {
        (bool success,) = feeRecipient.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    // Admin Functions
    function updateFees(uint256 newAppFee, uint256 newVisaFee) external onlyRole(ADMIN_ROLE) {
        // APPLICATION_FEE = newAppFee;
        // VISA_FEE = newVisaFee;
        emit FeesUpdated(newAppFee, newVisaFee);
    }

    function emergencyWithdraw() external onlyRole(ADMIN_ROLE) {
        payable(feeRecipient).transfer(address(this).balance);
    }
}
