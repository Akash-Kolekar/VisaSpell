// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IUniversityHandler} from "./UniversityHandler.sol";
import {VerificationHub} from "./VerificationHub.sol";
import {TimelineEnhancer} from "./TimelineEnhancer.sol";
import {IFeeManager} from "./interface/IFeeManager.sol";

/// @title Student Visa System
/// @author Akash Kolekar
/// @notice This is the main contract for the Student Visa System
/// @dev This contract is used to manage the student visa application process
contract StudentVisaSystem is AccessControl, Pausable, ReentrancyGuard {
    error StudentVisaSystem__ApplicationAlreadyExists();
    error StudentVisaSystem__EnrollmentDateMustBeInFuture();
    error StudentVisaSystem__EnrollmentDateTooFar();
    error StudentVisaSystem__InvalidProgram();
    error StudentVisaSystem__InsufficientFeePaid();

    error StudentVisaSystem__ApplicationNotFound();
    error StudentVisaSystem__Unauthorized();

    error StudentVisaSystem__BiometricsVerified();
    error StudentVisaSystem__ApplicationNotUnderReview();
    error StudentVisaSystem__ReviewAlreadyAuthorized();

    error StudentVisaSystem__OnlyUpgradePriority();
    error StudentVisaSystem__InsufficientAdditionalFee();
    error StudentVisaSystem__ApplicationNotUnderApproval();

    error StudentVisaSystem__ApplicationAlreadyProcessed();
    error StudentVisaSystem__WithdrawalFailed();
    error StudentVisaSystem__CannotModifyFinalizedApplication();

    error StudentVisaSystem__InvalidStatusUpdate();
    error StudentVisaSystem__ApplicationNotRejected();

    error StudentVisaSystem__ApplicationAlreadyApproved();
    error StudentVisaSystem__ApplicationAlreadyRejected();

    error StudentVisaSystem__DocumentExpired();
    error StudentVisaSystem__DocumentNotSubmittedNotVerified();

    /////////////////////////////
    ///// State Variables ///////
    /////////////////////////////

    IUniversityHandler public universityHandler;
    VerificationHub public verificationHub;
    IFeeManager public feeManager;
    TimelineEnhancer public timelineEnhancer;

    bytes32 public constant UNIVERSITY_ROLE = keccak256("UNIVERSITY_ROLE");
    bytes32 public constant EMBASSY_ROLE = keccak256("EMBASSY_ROLE");
    bytes32 public constant BANK_ROLE = keccak256("BANK_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VERIFICATION_HUB_ROLE = keccak256("VERIFICATION_HUB_ROLE");

    enum DocumentType {
        PASSPORT,
        ACADEMIC_RECORDS,
        FINANCIAL_PROOF,
        ACCEPTANCE_LETTER,
        BACKGROUND_CHECK,
        HEALTH_CERTIFICATE,
        LANGUAGE_PROFICIENCY
    }

    enum VerificationStatus {
        NOT_SUBMITTED,
        SUBMITTED,
        IN_REVIEW,
        VERIFIED,
        REJECTED
    }

    enum VisaStatus {
        NOT_STARTED,
        DOCUMENTS_PENDING,
        UNDER_REVIEW,
        ADDITIONAL_DOCUMENTS_REQUIRED,
        CONDITIONALLY_APPROVED,
        APPROVED,
        REJECTED
    }

    /// @dev
    // This Priority enum is used to determine the priority of the visa application
    // This is the very important feature of the system

    enum Priority {
        STANDARD,
        EXPEDITED,
        EMERGENCY
    }

    struct Document {
        string documentHash;
        VerificationStatus status;
        address verifiedBy;
        uint256 timestamp;
        string comments;
        uint256 expiryDate; // When document expires
    }

    struct Verification {
        address verifier;
        uint256 timestamp;
        string verificationProof;
    }

    struct Timeline {
        uint32 targetDate; // Expected enrollment date // timestamp fits in 32 bits until 2106
        uint32 deadlineDate; // Visa processing deadline
        Priority priority;
        bool isExpedited;
    }
    // uint256 lastReminderSent;

    struct Application {
        address applicant;
        mapping(DocumentType => Document) documents;
        VisaStatus status;
        uint256 createdAt;
        uint256 updatedAt;
        string universityId;
        Timeline timeline;
        uint256 credibilityScore;
        mapping(address => bool) authorizedViewers;
        bool isBiometricVerified;
        uint256 applicationFee;
        bool feesPaid;
        string[] previousVisaCountries;
        uint8 attemptCount;
        uint256 paidFees;
        bool isPriorityUpgraded;
    }

    // Reputation system for verifiers
    struct VerifierStats {
        uint256 totalVerifications;
        uint256 averageResponseTime;
        uint256 reputationScore;
        bool isActive;
    }

    mapping(address => Application) public applications;
    mapping(address => bool) public hasApplication;
    mapping(address => VerifierStats) public verifierStats;
    mapping(string => address) public universityRegistry;
    mapping(address => TimelineEnhancer.Prediction[]) public applicantPredictions;

    uint32 public standardProcessingTime = 30 days;
    uint32 public expeditedProcessingTime = 10 days;
    uint32 public emergencyProcessingTime = 3 days;

    uint256 public standardFee = 0.000001 ether;
    uint256 public expeditedFee = 0.000003 ether;
    uint256 public emergencyFee = 0.000005 ether;

    uint256 public totalApplications;
    uint256 public totalApproved;
    uint256 public totalRejected;

    event ApplicationCreated(address indexed applicant, uint256 timestamp, Priority priority);
    event DocumentSubmitted(address indexed applicant, DocumentType docType, string documentHash);
    event DocumentVerified(address indexed applicant, DocumentType docType, address verifier);
    event DocumentRejected(address indexed applicant, DocumentType docType, address verifier, string reason);
    event ApplicationStatusUpdated(address indexed applicant, VisaStatus status);
    event TimelineCritical(address indexed applicant, uint256 daysRemaining);
    event BiometricVerified(address indexed applicant, uint256 timestamp);
    event FeePaid(address indexed applicant, uint256 amount, Priority priority);
    event CredibilityScoreUpdated(address indexed applicant, uint256 newScore);
    event ViewerAuthorized(address indexed applicant, address viewer);
    event ProcessingExpedited(address indexed applicant, Priority newPriority);
    event PredictionGenerated(address applicant, uint256 estimatedDays, uint256 probability);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    ///////////////////////////////
    //// External Functions
    //////////////////////////////
    // Feature 1: Prioritized processing with different fee tiers
    function createApplication(
        string calldata universityId,
        string calldata programId,
        uint32 enrollmentDate,
        Priority priority,
        string[] calldata previousVisaCountries
    ) external payable {
        if (hasApplication[msg.sender]) revert StudentVisaSystem__ApplicationAlreadyExists();
        if (enrollmentDate <= block.timestamp) revert StudentVisaSystem__EnrollmentDateMustBeInFuture();
        if (enrollmentDate >= block.timestamp + 365 days) revert StudentVisaSystem__EnrollmentDateTooFar();
        if (!universityHandler.isValidProgram(universityId, programId)) revert StudentVisaSystem__InvalidProgram();

        // Determine required fee and processing time
        (uint256 requiredFee, uint32 processingTime) = getFeeAndProcessingTime(priority);

        // Process any ETH sent with the transaction
        if (msg.value > 0) {
            feeManager.payWithETH{value: msg.value}(msg.sender);
        }

        // Verify total payments meet requirement
        if (feeManager.getTotalPaid(msg.sender) < requiredFee) revert StudentVisaSystem__InsufficientFeePaid();

        // Initialize application
        Application storage app = applications[msg.sender];
        _initializeApplicationCore(app, universityId);
        _initializeApplicationTimeline(app, enrollmentDate, priority, processingTime);
        _handlePreviousCountries(app, previousVisaCountries);

        // Update state
        hasApplication[msg.sender] = true;
        totalApplications++;

        emit ApplicationCreated(msg.sender, block.timestamp, priority);
        emit FeePaid(msg.sender, requiredFee, priority);
    }

    // Helper function for fee calculation
    function getFeeAndProcessingTime(Priority priority) public view returns (uint256, uint32) {
        if (priority == Priority.STANDARD) {
            return (standardFee, standardProcessingTime);
        } else if (priority == Priority.EXPEDITED) {
            return (expeditedFee, expeditedProcessingTime);
        }
        return (emergencyFee, emergencyProcessingTime);
    }

    // Feature 2: Advanced document handling with expiry dates
    function submitDocument(address applicant, DocumentType docType, string calldata documentHash, uint256 expiryDate)
        external
    {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();
        if (
            applicant != msg.sender && 
            hasRole(UNIVERSITY_ROLE, msg.sender)
        ) revert StudentVisaSystem__Unauthorized();

        Application storage app = applications[applicant];
        _validateDocumentSubmission(app);
        _updateDocument(app.documents[docType], documentHash, expiryDate);

        app.updatedAt = block.timestamp;

        emit DocumentSubmitted(applicant, docType, documentHash);

        _checkTimelineCritical(msg.sender);

        verificationHub.requestVerification(applicant, VerificationHub.VerificationType.DOCUMENT, documentHash);
    }

    // Feature 3: Biometric verification
    function submitBiometricVerification(string calldata biometricHash) external {
        if (!hasApplication[msg.sender]) revert StudentVisaSystem__ApplicationNotFound();

        Application storage app = applications[msg.sender];
        if (app.isBiometricVerified) revert StudentVisaSystem__BiometricsVerified();

        app.isBiometricVerified = true;
        app.updatedAt = block.timestamp;

        // Increase credibility score for biometric verification
        _updateCredibilityScore(msg.sender, 10);

        emit BiometricVerified(msg.sender, block.timestamp);
    }

    // Feature 5: Conditional approval with time-bound requirements
    function conditionallyApproveVisa(address applicant, string calldata conditions, uint32 conditionDeadline)
        external
        onlyRole(EMBASSY_ROLE)
    {
        if (!hasApplication[msg.sender]) revert StudentVisaSystem__ApplicationNotFound();

        Application storage app = applications[applicant];
        if (app.status != VisaStatus.UNDER_REVIEW) revert StudentVisaSystem__ApplicationNotUnderReview();

        app.status = VisaStatus.CONDITIONALLY_APPROVED;
        app.timeline.deadlineDate = conditionDeadline;
        app.updatedAt = block.timestamp;

        emit ApplicationStatusUpdated(applicant, VisaStatus.CONDITIONALLY_APPROVED);
    }

    // Feature 6: Selective disclosure authorization
    function authorizeViewer(address viewer) external {
        if (!hasApplication[msg.sender]) revert StudentVisaSystem__ApplicationNotFound();

        Application storage app = applications[msg.sender];
        if (app.authorizedViewers[viewer]) revert StudentVisaSystem__ReviewAlreadyAuthorized();

        app.authorizedViewers[viewer] = true;

        emit ViewerAuthorized(msg.sender, viewer);
    }

    // Feature 7: Emergency processing upgrade
    function upgradeProcessingPriority(Priority newPriority) external payable {
        if (!hasApplication[msg.sender]) revert StudentVisaSystem__ApplicationNotFound();

        Application storage app = applications[msg.sender];
        if (app.timeline.priority >= newPriority) revert StudentVisaSystem__OnlyUpgradePriority();

        uint256 additionalFee;
        if (newPriority == Priority.EXPEDITED) {
            additionalFee = expeditedFee - standardFee;
        } else if (newPriority == Priority.EMERGENCY) {
            if (app.timeline.priority == Priority.STANDARD) {
                additionalFee = emergencyFee - standardFee;
            } else {
                additionalFee = emergencyFee - expeditedFee;
            }
        }

        if (msg.value < additionalFee) revert StudentVisaSystem__InsufficientAdditionalFee();

        app.timeline.priority = newPriority;
        if (newPriority == Priority.EXPEDITED) {
            app.timeline.deadlineDate = uint32(block.timestamp) + expeditedProcessingTime;
        } else {
            app.timeline.deadlineDate = uint32(block.timestamp) + emergencyProcessingTime;
        }

        app.timeline.isExpedited = true;
        app.applicationFee += msg.value;

        emit ProcessingExpedited(msg.sender, newPriority);
        emit FeePaid(msg.sender, msg.value, newPriority);
    }

    // Feature 9: Verifier reputation system

    function verifyDocument(address applicant, DocumentType docType, string calldata verificationProof) external {
        if (!_isAuthorizedVerifier()) revert StudentVisaSystem__Unauthorized();

        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();

        Application storage app = applications[applicant];
        Document storage doc = app.documents[docType];

        _validateDocumentVerification(doc);
        _updateVerificationState(doc, msg.sender);

        uint256 responseTime = block.timestamp - doc.timestamp;
        updateVerifierStats(msg.sender, responseTime);
        _updateCredibilityIfEarly(app);

        app.updatedAt = block.timestamp;

        emit DocumentVerified(applicant, docType, msg.sender);

        _checkAllDocumentsVerified(applicant);
    }

    function approveVisa(address applicant) external onlyRole(EMBASSY_ROLE) nonReentrant {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();

        Application storage app = applications[applicant];
        if (
            app.status != VisaStatus.UNDER_REVIEW &&
            app.status != VisaStatus.CONDITIONALLY_APPROVED
        ) revert StudentVisaSystem__ApplicationNotUnderApproval();

        app.status = VisaStatus.APPROVED;
        app.updatedAt = block.timestamp;

        totalApproved++;

        emit ApplicationStatusUpdated(applicant, VisaStatus.APPROVED);
    }

    function rejectVisa(address applicant, string calldata reason) external onlyRole(EMBASSY_ROLE) nonReentrant {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();

        Application storage app = applications[applicant];
        if (
            app.status == VisaStatus.APPROVED || 
            app.status != VisaStatus.REJECTED
        ) revert StudentVisaSystem__ApplicationAlreadyProcessed();

        app.status = VisaStatus.REJECTED;
        app.updatedAt = block.timestamp;

        // Update applicant credibility based on rejection
        _updateCredibilityScore(applicant, -10);

        totalRejected++;

        emit ApplicationStatusUpdated(applicant, VisaStatus.REJECTED);
    }

    // Administrative functions
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }   

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Allow withdrawal of fees by admin
    function withdrawFees(address payable recipient, uint256 amount) external onlyRole(ADMIN_ROLE) nonReentrant {
        // @audit: is the checks really necessary? since solidity will revert underflow value
        require(amount <= address(this).balance, "Insufficient balance"); 
        (bool sent, ) = recipient.call{value: amount}("");
        if (!sent) revert StudentVisaSystem__WithdrawalFailed();
        // recipient.transfer(amount);
    }

    function setVerificationHub(address _hub) external onlyRole(ADMIN_ROLE) {
        verificationHub = VerificationHub(_hub);
    }

    function updateCredibilityScore(address applicant, int8 change) external onlyRole(VERIFICATION_HUB_ROLE) {
        _updateCredibilityScore(applicant, change);
    }

    function updateApplicationStatus(address applicant, VisaStatus newStatus) external onlyRole(EMBASSY_ROLE) {
        if (
            !hasApplication[applicant]
        ) revert StudentVisaSystem__ApplicationNotFound();
        if (
            applications[applicant].status == VisaStatus.APPROVED || 
            applications[applicant].status == VisaStatus.REJECTED
        ) revert StudentVisaSystem__CannotModifyFinalizedApplication();
        if (
            newStatus != VisaStatus.ADDITIONAL_DOCUMENTS_REQUIRED && 
            newStatus != VisaStatus.UNDER_REVIEW
        ) revert StudentVisaSystem__InvalidStatusUpdate();

        applications[applicant].status = newStatus;
        applications[applicant].updatedAt = block.timestamp;

        emit ApplicationStatusUpdated(applicant, newStatus);
    }

    function resetApplication() external {
        if (
            applications[msg.sender].status != VisaStatus.REJECTED
        ) revert StudentVisaSystem__ApplicationNotRejected();
        
        delete applications[msg.sender];
        hasApplication[msg.sender] = false;
    }

    function initializeDependencies(
        address _universityHandler,
        address _verificationHub,
        address _feeManager,
        address _timelineEnhancer
    ) external onlyRole(ADMIN_ROLE) {
        universityHandler = IUniversityHandler(_universityHandler);
        verificationHub = VerificationHub(_verificationHub);
        feeManager = IFeeManager(_feeManager);
        timelineEnhancer = TimelineEnhancer(_timelineEnhancer);
    }

    /////////////////////////////////////
    // Internal View and Pure Functions
    /////////////////////////////////////

    function _initializeApplicationCore(Application storage app, string calldata universityId) internal {
        app.applicant = msg.sender;
        app.status = VisaStatus.DOCUMENTS_PENDING;
        app.universityId = universityId;
        app.credibilityScore = 100; // Default score
        app.feesPaid = true;
        app.applicationFee = msg.value;
        app.attemptCount = 1;
        app.createdAt = block.timestamp;
        app.updatedAt = block.timestamp;
    }

    function _initializeApplicationTimeline(
        Application storage app,
        uint32 enrollmentDate,
        Priority priority,
        uint32 processingTime
    ) internal {
        app.timeline = Timeline({
            targetDate: enrollmentDate,
            deadlineDate: uint32(block.timestamp) + processingTime,
            priority: priority,
            isExpedited: (priority != Priority.STANDARD)
        });
    }

    function _handlePreviousCountries(Application storage app, string[] calldata previousVisaCountries) internal {
        for (uint256 i = 0; i < previousVisaCountries.length; i++) {
            app.previousVisaCountries.push(previousVisaCountries[i]);
        }
    }

    function _validateDocumentSubmission(Application storage app) internal view {
        if (app.status == VisaStatus.APPROVED) revert StudentVisaSystem__ApplicationAlreadyApproved();
        if (app.status == VisaStatus.REJECTED) revert StudentVisaSystem__ApplicationAlreadyRejected();
    }

    function _updateDocument(Document storage doc, string calldata hash, uint256 expiryDate) internal {
        if (expiryDate <= block.timestamp) revert StudentVisaSystem__DocumentExpired();
        
        doc.documentHash = hash;
        doc.status = VerificationStatus.SUBMITTED;
        doc.timestamp = block.timestamp;
        doc.expiryDate = expiryDate;
    }

    // Feature 4: Credibility scoring system
    function _updateCredibilityScore(address applicant, int8 change) internal {
        Application storage app = applications[applicant];

        if (change > 0) {
            app.credibilityScore = min(app.credibilityScore + uint8(change), 100);
        } else {
            uint8 absoluteChange = uint8(-change);
            if (app.credibilityScore > absoluteChange) {
                app.credibilityScore -= absoluteChange;
            } else {
                app.credibilityScore = 0;
            }
        }

        emit CredibilityScoreUpdated(applicant, app.credibilityScore);
    }

    function updateVerifierStats(address verifier, uint256 responseTime) internal {
        VerifierStats storage stats = verifierStats[verifier];

        if (stats.totalVerifications == 0) {
            stats.averageResponseTime = responseTime;
        } else {
            stats.averageResponseTime =
                (stats.averageResponseTime * stats.totalVerifications + responseTime) / (stats.totalVerifications + 1);
        }

        stats.totalVerifications++;

        // Update reputation based on response time
        if (responseTime < 1 days) {
            stats.reputationScore = min(stats.reputationScore + 2, 100);
        } else if (responseTime < 3 days) {
            stats.reputationScore = min(stats.reputationScore + 1, 100);
        } else if (responseTime > 7 days) {
            stats.reputationScore = stats.reputationScore > 1 ? stats.reputationScore - 1 : 0;
        }
    }

    function _isAuthorizedVerifier() internal view returns (bool) {
        return
            hasRole(UNIVERSITY_ROLE, msg.sender) || hasRole(EMBASSY_ROLE, msg.sender) || hasRole(BANK_ROLE, msg.sender);
    }

    function _validateDocumentVerification(Document storage doc) internal view {
        if (doc.status != VerificationStatus.SUBMITTED) revert StudentVisaSystem__DocumentNotSubmittedNotVerified();
        if (doc.expiryDate <= block.timestamp) revert StudentVisaSystem__DocumentExpired();
    }

    function _updateVerificationState(Document storage doc, address verifier) internal {
        doc.status = VerificationStatus.VERIFIED;
        doc.verifiedBy = verifier;
        doc.timestamp = block.timestamp;
    }

    function _updateCredibilityIfEarly(Application storage app) internal {
        // Increase credibility score for quick document submission
        if (block.timestamp - app.createdAt < 7 days) {
            _updateCredibilityScore(app.applicant, 5);
        }
    }

    function _checkAllDocumentsVerified(address applicant) internal {
        Application storage app = applications[applicant];

        // Check required documents based on application type
        bool allVerified = true;

        // Basic required documents
        if (
            app.documents[DocumentType.PASSPORT].status != VerificationStatus.VERIFIED
                || app.documents[DocumentType.ACADEMIC_RECORDS].status != VerificationStatus.VERIFIED
                || app.documents[DocumentType.FINANCIAL_PROOF].status != VerificationStatus.VERIFIED
                || app.documents[DocumentType.ACCEPTANCE_LETTER].status != VerificationStatus.VERIFIED
        ) {
            allVerified = false;
        }

        // Additional check for language proficiency
        if (app.previousVisaCountries.length == 0) {
            if (app.documents[DocumentType.LANGUAGE_PROFICIENCY].status != VerificationStatus.VERIFIED) {
                allVerified = false;
            }
        }

        if (allVerified) {
            app.status = VisaStatus.UNDER_REVIEW;
            emit ApplicationStatusUpdated(applicant, VisaStatus.UNDER_REVIEW);
        }
    }

    function _checkTimelineCritical(address applicant) internal {
        if (address(timelineEnhancer) != address(0)) {
            TimelineEnhancer.Prediction memory prediction = timelineEnhancer.generatePrediction(applicant);

            applicantPredictions[applicant].push(prediction);
            emit PredictionGenerated(applicant, prediction.estimatedDays, prediction.successProbability);

            // Auto-extend deadline if probability < 50%
            if (prediction.successProbability < 50) {
                applications[applicant].timeline.deadlineDate += 7 days;
            }
        }

        Application storage app = applications[applicant];

        uint256 daysUntilDeadline = (app.timeline.deadlineDate - block.timestamp) / 1 days;
        uint256 daysUntilEnrollment = (app.timeline.targetDate - block.timestamp) / 1 days;

        if (daysUntilDeadline <= 3 || daysUntilEnrollment <= 14) {
            emit TimelineCritical(applicant, min(daysUntilDeadline, daysUntilEnrollment));
        }
    }

    // Utility function to get minimum of two values
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function grantRole(address account, bytes32 role) external onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    ////////////////////////////////////////////////////////////////////////////
    // External & Public View & Pure Functions
    ////////////////////////////////////////////////////////////////////////////

    // Getters for application information
    function getApplicationStatus(address applicant) external view returns (VisaStatus) {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();
        return applications[applicant].status;
    }

    function getDocumentStatus(address applicant, DocumentType docType) external view returns (VerificationStatus) {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();

        if (
            msg.sender != applicant && 
            !applications[applicant].authorizedViewers[msg.sender]
        ) revert StudentVisaSystem__Unauthorized();

        return applications[applicant].documents[docType].status;
    }

    function getCredibilityScore(address applicant) external view returns (uint256) {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();
        
        if (
            msg.sender != applicant && 
            !applications[applicant].authorizedViewers[msg.sender] &&
            !hasRole(ADMIN_ROLE, msg.sender) && 
            !hasRole(EMBASSY_ROLE, msg.sender)
        ) revert StudentVisaSystem__Unauthorized();

        return applications[applicant].credibilityScore;
    }

    function getApplicationDetails(address applicant)
        external
        view
        returns (
            VisaStatus status,
            uint256 credibilityScore,
            uint256 createdAt,
            uint256 updatedAt,
            Timeline memory timeline
        )
    {
        if (!hasApplication[applicant]) revert StudentVisaSystem__ApplicationNotFound();
        Application storage app = applications[applicant];
        return (app.status, app.credibilityScore, app.createdAt, app.updatedAt, app.timeline);
    }

    function getApplicationCore(address applicant)
        external
        view
        returns (VisaStatus status, uint256 credibilityScore, uint256 createdAt)
    {
        Application storage app = applications[applicant];
        return (app.status, app.credibilityScore, app.createdAt);
    }

    function getTimelinePriority(address applicant) external view returns (Priority) {
        return applications[applicant].timeline.priority;
    }

    function getTimelineDeadline(address applicant) external view returns (uint256) {
        return applications[applicant].timeline.deadlineDate;
    }
}
