// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVerificationHub {
    // Define the VerificationResult struct in the interface
    struct VerificationResult {
        address verifier;
        uint256 timestamp;
        bool isValid;
        string proof;
    }

    enum VerificationType {
        DOCUMENT,
        BIOMETRIC,
        BACKGROUND_CHECK
    }

    // Function declarations must match implementations exactly
    function getVerificationHistory(address applicant) external view returns (VerificationResult[] memory);

    function requestVerification(address applicant, uint8 vType, string calldata proof) external;

    function processVerification(bytes32 requestId, bool isValid) external;
}
