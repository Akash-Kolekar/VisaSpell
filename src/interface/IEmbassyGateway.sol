// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEmbassyGateway {
    function requestAdditionalDocuments(address applicant, string calldata docs) external;
    function overrideDecision(address applicant, bool approve, string calldata reason) external;
}
