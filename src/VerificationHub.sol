// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IStudentVisaSystem} from "./interface/IStudentVisaSystem.sol";
import {IVerificationHub} from "./interface/IVerificationHub.sol";
import {SharedTypes} from "./interface/SharedTypes.sol";

contract VerificationHub is AccessControl, IVerificationHub {
    error VerificationHub__RequestAlreadyProcessed();
    error VerificationHub__InvalidApplicant();

    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    bytes32 public constant VERIFICATION_HUB_ROLE = keccak256("VERIFICATION_HUB_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IStudentVisaSystem public visaSystem;

    // Using the VerificationType from interface for consistency
    struct VerificationRequest {
        address applicant;
        VerificationType vType;
        string proof;
        bool completed;
        address verifier;
    }

    struct VerifierProfile {
        string credentials;
        uint256 totalVerifications;
        uint256 successfulVerifications;
        uint256 lastActivity;
    }

    // Reuse VerificationResult from interface instead of redefining
    // using IVerificationHub.VerificationResult;

    // Mappings
    mapping(bytes32 => VerificationRequest) public verificationRequests;
    mapping(address => VerifierProfile) public verifiers;
    mapping(address => mapping(VerificationType => VerificationResult[])) public verificationRecords;

    // Events
    event VerificationRequested(bytes32 requestId, address applicant, VerificationType vType);
    event VerificationCompleted(bytes32 requestId, bool result);
    event VerifierRegistered(address verifier);
    event VisaSystemUpdated(address oldSystem, address newSystem);

    constructor(address _visaSystem) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        visaSystem = IStudentVisaSystem(_visaSystem);
    }

    /// @notice Update the visa system address
    function setVisaSystem(address _visaSystem) external onlyRole(ADMIN_ROLE) {
        address oldSystem = address(visaSystem);
        visaSystem = IStudentVisaSystem(_visaSystem);
        emit VisaSystemUpdated(oldSystem, _visaSystem);
    }

    /// @notice Initial role setup must be called after deployment
    function initializeRoles() external onlyRole(ADMIN_ROLE) {
        // We can't automatically request roles from StudentVisaSystem
        // The StudentVisaSystem admin must grant this contract the VERIFICATION_HUB_ROLE
        // This function can be used for any local role initialization
        _grantRole(VERIFICATION_HUB_ROLE, address(this));
    }

    /// @notice Create a new verification request
    /// @dev Changed role check to use local role for now to avoid circular dependency
    function requestVerification(address applicant, uint8 vType, string calldata proof) external override {
        // Allow StudentVisaSystem contract or anyone with VERIFICATION_HUB_ROLE to call this
        if (msg.sender != address(visaSystem) && !hasRole(VERIFICATION_HUB_ROLE, msg.sender)) {
            revert("VerificationHub: Unauthorized");
        }

        bytes32 requestId = keccak256(abi.encodePacked(applicant, vType, proof, block.timestamp));
        verificationRequests[requestId] = VerificationRequest({
            applicant: applicant,
            vType: VerificationType(vType), // Convert uint8 to enum type here
            proof: proof,
            completed: false,
            verifier: address(0)
        });
        emit VerificationRequested(requestId, applicant, VerificationType(vType));
    }

    /// @notice Process verification request (called by verifiers)
    function processVerification(bytes32 requestId, bool isValid) external override onlyRole(VERIFIER_ROLE) {
        VerificationRequest storage request = verificationRequests[requestId];
        if (request.completed) revert VerificationHub__RequestAlreadyProcessed();
        if (!visaSystem.hasApplication(request.applicant)) revert VerificationHub__InvalidApplicant();

        // Update verification records
        verificationRecords[request.applicant][request.vType].push(
            VerificationResult({
                verifier: msg.sender,
                timestamp: block.timestamp,
                isValid: isValid,
                proof: request.proof
            })
        );

        // Update verifier stats
        VerifierProfile storage profile = verifiers[msg.sender];
        profile.totalVerifications++;
        if (isValid) profile.successfulVerifications++;
        profile.lastActivity = block.timestamp;

        // Update credibility score
        int8 scoreChange = isValid ? int8(5) : int8(-3);
        visaSystem.updateCredibilityScore(request.applicant, scoreChange);

        // Mark request as completed
        request.completed = true;
        request.verifier = msg.sender;
        emit VerificationCompleted(requestId, isValid);
    }

    /// @notice Admin function to register new verifiers
    function registerVerifier(address verifier, string calldata credentials) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(VERIFIER_ROLE, verifier);
        verifiers[verifier] = VerifierProfile({
            credentials: credentials,
            totalVerifications: 0,
            successfulVerifications: 0,
            lastActivity: block.timestamp
        });
        emit VerifierRegistered(verifier);
    }

    /// @notice Get verification history for an applicant
    function getVerificationHistory(address applicant) external view override returns (VerificationResult[] memory) {
        VerificationResult[] memory allResults = new VerificationResult[](0);

        for (uint8 vType = 0; vType < uint8(type(VerificationType).max); vType++) {
            VerificationResult[] memory typeResults = verificationRecords[applicant][VerificationType(vType)];
            allResults = concatArrays(allResults, typeResults);
        }
        return allResults;
    }

    /// @notice Calculate verifier trust score
    function calculateTrustScore(address verifier) public view returns (uint256) {
        VerifierProfile memory profile = verifiers[verifier];
        if (profile.totalVerifications == 0) return 0;

        uint256 successRate = (profile.successfulVerifications * 100) / profile.totalVerifications;
        uint256 activityScore = block.timestamp - profile.lastActivity < 30 days ? 20 : 0;
        return successRate + activityScore;
    }

    /// @dev Helper for array concatenation
    function concatArrays(VerificationResult[] memory a, VerificationResult[] memory b)
        internal
        pure
        returns (VerificationResult[] memory)
    {
        VerificationResult[] memory combined = new VerificationResult[](a.length + b.length);
        uint256 i = 0;
        for (; i < a.length; i++) {
            combined[i] = a[i];
        }
        for (uint256 j = 0; j < b.length; j++) {
            combined[i + j] = b[j];
        }
        return combined;
    }

    /// @dev Simplified verification logic (replace with oracle in production)
    function _performVerification(VerificationType, string calldata) internal pure returns (bool) {
        // Always return true in mock implementation
        return true;
    }

    function grantRole(address account, bytes32 role) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }
}
