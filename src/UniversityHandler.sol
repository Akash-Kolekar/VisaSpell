// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {StudentVisaSystem} from "./StudentVisaSystem.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IUniversityHandler} from "./interface/IUniversityHandler.sol";

contract UniversityHandler is AccessControl, IUniversityHandler {
    error UniversityHandler__InvalidProgram();
    error UniversityHandler__ApplicantNotFound();
    
    bytes32 public constant UNIVERSITY_ROLE = keccak256("UNIVERSITY_ROLE");

    StudentVisaSystem private visaSystem;

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
        visaSystem = StudentVisaSystem(_visaSystem);
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
            StudentVisaSystem.DocumentType.ACCEPTANCE_LETTER,
            string(abi.encodePacked(universityId, ":", programId)),
            block.timestamp + 365 days
        );
    }

    function isValidProgram(string calldata universityId, string calldata programId) external view returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(universityId, programId));
        return programs[hash].isActive;
    }
}
