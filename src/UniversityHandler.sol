// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStudentVisaSystem} from "./interface/IStudentVisaSystem.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IUniversityHandler} from "./interface/IUniversityHandler.sol";

contract UniversityHandler is AccessControl, IUniversityHandler {
    error UniversityHandler__InvalidProgram();
    error UniversityHandler__ApplicantNotFound();

    bytes32 public constant UNIVERSITY_ROLE = keccak256("UNIVERSITY_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    IStudentVisaSystem private visaSystem;

    struct Program {
        string requirements;
        uint256 tuition;
        bool requiresInterview;
        bool isActive;
    }

    mapping(bytes32 => Program) public programs; // programHash => Program
    mapping(address => string) public universityRegistry; // University address => ID

    event ProgramRegistered(string indexed universityId, string programId);

    constructor(address _visaSystem) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(UNIVERSITY_ROLE, msg.sender);
        visaSystem = IStudentVisaSystem(_visaSystem);
    }

    function registerUniversity(address universityAddr, string calldata universityId)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        universityRegistry[universityAddr] = universityId;
        _grantRole(UNIVERSITY_ROLE, universityAddr);
    }

    function registerProgram(string calldata programId) external onlyRole(UNIVERSITY_ROLE) {
        string memory universityId = universityRegistry[msg.sender];
        bytes32 programHash = keccak256(abi.encodePacked(universityId, programId));
        programs[programHash] = Program({requirements: "", tuition: 0, requiresInterview: false, isActive: true});

        emit ProgramRegistered(universityId, programId);
    }

    function verifyAdmission(address applicant, string calldata programId)
        external
        override
        onlyRole(UNIVERSITY_ROLE)
    {
        string memory universityId = universityRegistry[msg.sender];
        bytes32 programHash = keccak256(abi.encodePacked(universityId, programId));

        if (!programs[programHash].isActive) revert UniversityHandler__InvalidProgram();

        if (!visaSystem.hasApplication(applicant)) revert UniversityHandler__ApplicantNotFound();
        visaSystem.submitDocument(
            applicant,
            IStudentVisaSystem.DocumentType.ACCEPTANCE_LETTER,
            string(abi.encodePacked(universityId, ":", programId)),
            block.timestamp + 365 days
        );
    }

    function isValidProgram(string calldata universityId, string calldata programId) external view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(universityId, programId));
        return programs[hash].isActive;
    }

    function grantRole(address account, bytes32 role) external onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    // Add new function to update program details
    function updateProgram(
        string calldata programId,
        string calldata requirements,
        uint256 tuition,
        bool requiresInterview,
        bool isActive
    ) external onlyRole(UNIVERSITY_ROLE) {
        string memory universityId = universityRegistry[msg.sender];
        bytes32 programHash = keccak256(abi.encodePacked(universityId, programId));

        // Ensure the program exists
        require(programs[programHash].isActive || !programs[programHash].isActive, "Program does not exist");

        programs[programHash] = Program({
            requirements: requirements,
            tuition: tuition,
            requiresInterview: requiresInterview,
            isActive: isActive
        });
    }

    // Add function to deactivate program
    function deactivateProgram(string calldata programId) external onlyRole(UNIVERSITY_ROLE) {
        string memory universityId = universityRegistry[msg.sender];
        bytes32 programHash = keccak256(abi.encodePacked(universityId, programId));

        // Ensure the program exists
        require(programs[programHash].isActive || !programs[programHash].isActive, "Program does not exist");

        programs[programHash].isActive = false;
    }
}
