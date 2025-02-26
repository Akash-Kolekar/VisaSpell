// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/// @title UniversityRegistry
/// @notice Manages university records and program details for visa applications
contract UniversityRegistry is AccessControl, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant REGISTRY_MANAGER_ROLE = keccak256("REGISTRY_MANAGER_ROLE");
    bytes32 public constant UNIVERSITY_ADMIN_ROLE = keccak256("UNIVERSITY_ADMIN_ROLE");

    struct University {
        string name;
        string country;
        string accreditationId;
        bool isVerified;
        bool isActive;
        uint256 registeredAt;
        uint256 lastUpdated;
        address[] authorizedSigners;
    }

    struct Program {
        string programId;
        string universityId;
        string name;
        string degreeLevel; // "Bachelors", "Masters", "PhD", etc.
        uint256 durationMonths;
        bool requiresVisa;
        bool isActive;
    }

    // University ID => University
    mapping(string => University) public universities;

    // Program ID => Program
    mapping(string => Program) public programs;

    // Address => University ID
    mapping(address => string) public signerToUniversity;

    // Array of all university IDs
    string[] public universityList;

    // University ID => Program IDs
    mapping(string => string[]) public universityPrograms;

    event UniversityRegistered(string universityId, string name, string country);
    event UniversityUpdated(string universityId);
    event UniversityActivated(string universityId);
    event UniversityDeactivated(string universityId);
    event SignerAuthorized(string universityId, address signer);
    event SignerRemoved(string universityId, address signer);
    event ProgramRegistered(string programId, string universityId, string name);
    event ProgramUpdated(string programId);
    event ProgramActivated(string programId);
    event ProgramDeactivated(string programId);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(REGISTRY_MANAGER_ROLE, msg.sender);
    }

    /// @notice Register a new university
    function registerUniversity(
        string calldata universityId,
        string calldata name,
        string calldata country,
        string calldata accreditationId
    ) external onlyRole(REGISTRY_MANAGER_ROLE) {
        require(bytes(universities[universityId].name).length == 0, "University ID already exists");

        University storage university = universities[universityId];
        university.name = name;
        university.country = country;
        university.accreditationId = accreditationId;
        university.isVerified = false; // Requires verification
        university.isActive = true;
        university.registeredAt = block.timestamp;
        university.lastUpdated = block.timestamp;

        universityList.push(universityId);

        emit UniversityRegistered(universityId, name, country);
    }

    /// @notice Verify a university
    function verifyUniversity(string calldata universityId) external onlyRole(REGISTRY_MANAGER_ROLE) {
        require(bytes(universities[universityId].name).length > 0, "University does not exist");

        universities[universityId].isVerified = true;
        universities[universityId].lastUpdated = block.timestamp;

        emit UniversityUpdated(universityId);
    }

    /// @notice Deactivate a university
    function deactivateUniversity(string calldata universityId) external onlyRole(REGISTRY_MANAGER_ROLE) {
        require(bytes(universities[universityId].name).length > 0, "University does not exist");
        require(universities[universityId].isActive, "University already inactive");

        universities[universityId].isActive = false;
        universities[universityId].lastUpdated = block.timestamp;

        // Deactivate all programs of this university
        string[] storage programIds = universityPrograms[universityId];
        for (uint256 i = 0; i < programIds.length; i++) {
            programs[programIds[i]].isActive = false;
        }

        emit UniversityDeactivated(universityId);
    }

    /// @notice Reactivate a university
    function activateUniversity(string calldata universityId) external onlyRole(REGISTRY_MANAGER_ROLE) {
        require(bytes(universities[universityId].name).length > 0, "University does not exist");
        require(!universities[universityId].isActive, "University already active");

        universities[universityId].isActive = true;
        universities[universityId].lastUpdated = block.timestamp;

        emit UniversityActivated(universityId);
    }

    /// @notice Authorize a new signer for a university
    function authorizeUniversitySigner(string calldata universityId, address signer) external {
        require(bytes(universities[universityId].name).length > 0, "University does not exist");
        require(universities[universityId].isActive, "University is not active");

        // Only admin or existing university admin can add signers
        bool isAuthorized = hasRole(ADMIN_ROLE, msg.sender) || hasRole(REGISTRY_MANAGER_ROLE, msg.sender);

        if (!isAuthorized) {
            string memory signerUniversity = signerToUniversity[msg.sender];
            require(
                keccak256(bytes(signerUniversity)) == keccak256(bytes(universityId)),
                "Not authorized for this university"
            );
            require(hasRole(UNIVERSITY_ADMIN_ROLE, msg.sender), "Not a university admin");
        }

        // Check if signer is already authorized for another university
        require(bytes(signerToUniversity[signer]).length == 0, "Signer already authorized for another university");

        universities[universityId].authorizedSigners.push(signer);
        signerToUniversity[signer] = universityId;

        // Grant university admin role if not already granted
        if (!hasRole(UNIVERSITY_ADMIN_ROLE, signer)) {
            _grantRole(UNIVERSITY_ADMIN_ROLE, signer);
        }

        universities[universityId].lastUpdated = block.timestamp;

        emit SignerAuthorized(universityId, signer);
    }

    /// @notice Remove a signer for a university
    function removeUniversitySigner(string calldata universityId, address signer) external {
        require(bytes(universities[universityId].name).length > 0, "University does not exist");

        // Only admin or existing university admin can remove signers
        bool isAuthorized = hasRole(ADMIN_ROLE, msg.sender) || hasRole(REGISTRY_MANAGER_ROLE, msg.sender);

        if (!isAuthorized) {
            string memory signerUniversity = signerToUniversity[msg.sender];
            require(
                keccak256(bytes(signerUniversity)) == keccak256(bytes(universityId)),
                "Not authorized for this university"
            );
            require(hasRole(UNIVERSITY_ADMIN_ROLE, msg.sender), "Not a university admin");
        }

        // Check if signer is authorized for this university
        require(
            keccak256(bytes(signerToUniversity[signer])) == keccak256(bytes(universityId)),
            "Signer not authorized for this university"
        );

        // Remove signer from authorized signers array
        address[] storage signers = universities[universityId].authorizedSigners;
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }

        delete signerToUniversity[signer];

        // Revoke university admin role if no longer needed
        if (hasRole(UNIVERSITY_ADMIN_ROLE, signer)) {
            _revokeRole(UNIVERSITY_ADMIN_ROLE, signer);
        }

        universities[universityId].lastUpdated = block.timestamp;

        emit SignerRemoved(universityId, signer);
    }

    /// @notice Register a new program
    function registerProgram(
        string calldata programId,
        string calldata universityId,
        string calldata name,
        string calldata degreeLevel,
        uint256 durationMonths,
        bool requiresVisa
    ) external {
        require(bytes(universities[universityId].name).length > 0, "University does not exist");
        require(universities[universityId].isActive, "University is not active");
        require(bytes(programs[programId].name).length == 0, "Program ID already exists");

        // Check if sender is authorized for university
        string memory signerUniversity = signerToUniversity[msg.sender];
        bool isAdmin = hasRole(ADMIN_ROLE, msg.sender) || hasRole(REGISTRY_MANAGER_ROLE, msg.sender);

        require(
            isAdmin
                || (
                    keccak256(bytes(signerUniversity)) == keccak256(bytes(universityId))
                        && hasRole(UNIVERSITY_ADMIN_ROLE, msg.sender)
                ),
            "Not authorized for this university"
        );

        Program storage program = programs[programId];
        program.programId = programId;
        program.universityId = universityId;
        program.name = name;
        program.degreeLevel = degreeLevel;
    }
}
