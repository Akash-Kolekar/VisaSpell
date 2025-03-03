// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {StudentVisaSystem} from "./StudentVisaSystem.sol";
import {IEmbassyGateway} from "./interface/IEmbassyGateway.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract EmbassyGateway is IEmbassyGateway, AccessControl {
    StudentVisaSystem private visaSystem;

    bytes32 public constant EMBASSY_ROLE = keccak256("EMBASSY_ROLE");

    // Track document requests
    mapping(address => string[]) public documentRequests;

    constructor(address _visaSystem) {
        visaSystem = StudentVisaSystem(_visaSystem);
    }

    function requestAdditionalDocuments(address applicant, string calldata docs) external override {
        require(visaSystem.hasRole(visaSystem.EMBASSY_ROLE(), msg.sender), "Unauthorized: Caller lacks EMBASSY_ROLE");

        documentRequests[applicant].push(docs); // Store requested docs
        visaSystem.updateApplicationStatus(applicant, StudentVisaSystem.VisaStatus.ADDITIONAL_DOCUMENTS_REQUIRED);
    }

    function overrideDecision(address applicant, bool approve, string calldata reason) external override {
        require(visaSystem.hasRole(visaSystem.EMBASSY_ROLE(), msg.sender), "Unauthorized: Caller lacks EMBASSY_ROLE");

        if (approve) {
            visaSystem.approveVisa(applicant);
        } else {
            visaSystem.rejectVisa(applicant, reason); // Use provided reason
        }
    }
}
