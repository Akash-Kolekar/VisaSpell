// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUniversityHandler {
    function registerProgram(string calldata programData) external;
    function verifyAdmission(address applicant, string calldata proof) external;
    function isValidProgram(string calldata universityId, string calldata programId) external view returns (bool);
}
