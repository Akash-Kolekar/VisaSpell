// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IVerificationHub {
    struct VerificationResult {
        address verifier;
        uint256 timestamp;
        bool isValid;
        string proof;
    }

    function registerVerifier(address verifier, string calldata credentials) external;
    function getVerificationHistory(address applicant) external view returns (VerificationResult[] memory);
    function calculateTrustScore(address verifier) external view returns (uint256);
}
