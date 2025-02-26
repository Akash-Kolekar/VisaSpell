// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

/// @title VerificationRegistry
/// @notice Manages verifier credentials and reputation for the visa application system
contract VerificationRegistry is AccessControl, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant REGISTRY_MANAGER_ROLE = keccak256("REGISTRY_MANAGER_ROLE");

    enum VerifierType {
        UNIVERSITY,
        EMBASSY,
        BANK,
        GOVERNMENT_AGENCY
    }

    struct Verifier {
        string name;
        string identifier; // Official ID or license number
        string countryCode;
        bool isActive;
        uint256 reputationScore; // 0-100
        uint256 verificationCount;
        uint256 registeredAt;
        uint256 lastUpdated;
    }

    struct VerificationRecord {
        address verifier;
        address applicant;
        string documentHash;
        string documentType;
        uint256 timestamp;
        bool approved;
    }

    mapping(address => Verifier) public verifiers;
    mapping(address => VerifierType) public verifierTypes;
    mapping(address => bool) public isRegisteredVerifier;

    // Maps document hash to its verification record
    mapping(string => VerificationRecord) public verificationRecords;

    // Organization reputations
    mapping(string => uint256) public organizationReputations; // organizationIdentifier => reputation

    event VerifierRegistered(address indexed verifier, VerifierType vType, string name);
    event VerifierDeactivated(address indexed verifier);
    event VerifierReactivated(address indexed verifier);
    event VerificationRecorded(address indexed verifier, address indexed applicant, string documentHash);
    event ReputationUpdated(address indexed verifier, uint256 newScore);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(REGISTRY_MANAGER_ROLE, msg.sender);
    }

    /// @notice Register a new verifier in the system
    function registerVerifier(
        address verifierAddress,
        VerifierType vType,
        string calldata name,
        string calldata identifier,
        string calldata countryCode
    ) external onlyRole(REGISTRY_MANAGER_ROLE) {
        require(!isRegisteredVerifier[verifierAddress], "Verifier already registered");

        Verifier storage verifier = verifiers[verifierAddress];
        verifier.name = name;
        verifier.identifier = identifier;
        verifier.countryCode = countryCode;
        verifier.isActive = true;
        verifier.reputationScore = 80; // Start with reasonable trust level
        verifier.registeredAt = block.timestamp;
        verifier.lastUpdated = block.timestamp;

        verifierTypes[verifierAddress] = vType;
        isRegisteredVerifier[verifierAddress] = true;

        emit VerifierRegistered(verifierAddress, vType, name);
    }

    /// @notice Deactivate a verifier
    function deactivateVerifier(address verifierAddress) external onlyRole(REGISTRY_MANAGER_ROLE) {
        require(isRegisteredVerifier[verifierAddress], "Verifier not registered");
        require(verifiers[verifierAddress].isActive, "Verifier already inactive");

        verifiers[verifierAddress].isActive = false;
        verifiers[verifierAddress].lastUpdated = block.timestamp;

        emit VerifierDeactivated(verifierAddress);
    }

    /// @notice Reactivate a verifier
    function reactivateVerifier(address verifierAddress) external onlyRole(REGISTRY_MANAGER_ROLE) {
        require(isRegisteredVerifier[verifierAddress], "Verifier not registered");
        require(!verifiers[verifierAddress].isActive, "Verifier already active");

        verifiers[verifierAddress].isActive = true;
        verifiers[verifierAddress].lastUpdated = block.timestamp;

        emit VerifierReactivated(verifierAddress);
    }

    /// @notice Record a verification performed by a verifier
    function recordVerification(
        address applicant,
        string calldata documentHash,
        string calldata documentType,
        bool approved
    ) external whenNotPaused {
        require(isRegisteredVerifier[msg.sender], "Not a registered verifier");
        require(verifiers[msg.sender].isActive, "Verifier not active");

        VerificationRecord storage record = verificationRecords[documentHash];
        record.verifier = msg.sender;
        record.applicant = applicant;
        record.documentHash = documentHash;
        record.documentType = documentType;
        record.timestamp = block.timestamp;
        record.approved = approved;

        // Update verification count
        verifiers[msg.sender].verificationCount++;
        verifiers[msg.sender].lastUpdated = block.timestamp;

        emit VerificationRecorded(msg.sender, applicant, documentHash);
    }

    /// @notice Update the reputation score of a verifier
    function updateReputationScore(address verifierAddress, uint256 newScore)
        external
        onlyRole(REGISTRY_MANAGER_ROLE)
    {
        require(isRegisteredVerifier[verifierAddress], "Verifier not registered");
        require(newScore <= 100, "Score must be between 0-100");

        verifiers[verifierAddress].reputationScore = newScore;
        verifiers[verifierAddress].lastUpdated = block.timestamp;

        emit ReputationUpdated(verifierAddress, newScore);
    }

    /// @notice Check if an address is an active verifier of a specific type
    function isActiveVerifierOfType(address verifierAddress, VerifierType vType) external view returns (bool) {
        return isRegisteredVerifier[verifierAddress] && verifiers[verifierAddress].isActive
            && verifierTypes[verifierAddress] == vType;
    }

    /// @notice Get verifier details
    function getVerifierDetails(address verifierAddress)
        external
        view
        returns (
            string memory name,
            string memory identifier,
            string memory countryCode,
            bool isActive,
            uint256 reputationScore,
            uint256 verificationCount
        )
    {
        require(isRegisteredVerifier[verifierAddress], "Verifier not registered");

        Verifier storage verifier = verifiers[verifierAddress];
        return (
            verifier.name,
            verifier.identifier,
            verifier.countryCode,
            verifier.isActive,
            verifier.reputationScore,
            verifier.verificationCount
        );
    }

    /// @notice Check document verification status
    function getVerificationStatus(string calldata documentHash)
        external
        view
        returns (address verifier, bool verified, uint256 timestamp)
    {
        VerificationRecord storage record = verificationRecords[documentHash];
        return (record.verifier, record.approved, record.timestamp);
    }

    /// @notice Pause contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause contract
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}
