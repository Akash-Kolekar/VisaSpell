// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStudentVisaSystem {
    enum VisaStatus {
        NOT_STARTED,
        DOCUMENTS_PENDING,
        UNDER_REVIEW,
        ADDITIONAL_DOCUMENTS_REQUIRED,
        CONDITIONALLY_APPROVED,
        APPROVED,
        REJECTED
    }

    enum DocumentType {
        PASSPORT,
        ACADEMIC_RECORDS,
        FINANCIAL_PROOF,
        ACCEPTANCE_LETTER,
        BACKGROUND_CHECK,
        HEALTH_CERTIFICATE,
        LANGUAGE_PROFICIENCY
    }

    enum Priority {
        STANDARD,
        EXPEDITED,
        EMERGENCY
    }

    function updateCredibilityScore(address applicant, int8 change) external;
    function updateApplicationStatus(address applicant, VisaStatus newStatus) external;
    function hasApplication(address applicant) external view returns (bool);
    function hasRole(bytes32 role, address account) external view returns (bool);
    function VERIFICATION_HUB_ROLE() external view returns (bytes32);
    function EMBASSY_ROLE() external view returns (bytes32);
    function submitDocument(address applicant, DocumentType docType, string calldata documentHash, uint256 expiryDate)
        external;
    function approveVisa(address applicant) external;
    function rejectVisa(address applicant, string calldata reason) external;
    function getApplicationCore(address applicant) external view returns (VisaStatus, uint256, uint256);
    function getTimelinePriority(address applicant) external view returns (Priority);
    function getTimelineDeadline(address applicant) external view returns (uint256);
    function standardProcessingTime() external view returns (uint32);
    function expeditedProcessingTime() external view returns (uint32);
    function emergencyProcessingTime() external view returns (uint32);
}
