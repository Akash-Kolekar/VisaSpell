// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {StudentVisaSystem} from "./StudentVisaSystem.sol";
import {IEmbassyGateway} from "./interface/IEmbassyGateway.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract EmbassyGateway is IEmbassyGateway, AccessControl {
    error EmbassyGateway__Unauthorized();
    
    StudentVisaSystem private visaSystem;

    bytes32 public constant EMBASSY_ROLE = keccak256("EMBASSY_ROLE");

    // Track document requests
    mapping(address => string[]) public documentRequests;

    constructor(address _visaSystem) {
        visaSystem = StudentVisaSystem(_visaSystem);
    }

    function requestAdditionalDocuments(address applicant, string calldata docs) external override {
        if (
            !visaSystem.hasRole(
                visaSystem.EMBASSY_ROLE(),
                msg.sender
            )
        ) revert EmbassyGateway__Unauthorized();

        documentRequests[applicant].push(docs); // Store requested docs
        visaSystem.updateApplicationStatus(applicant, StudentVisaSystem.VisaStatus.ADDITIONAL_DOCUMENTS_REQUIRED);
    }

    function overrideDecision(address applicant, bool approve, string calldata reason) external override {
        if (
            !visaSystem.hasRole(
                visaSystem.EMBASSY_ROLE(),
                msg.sender
            )
        ) revert EmbassyGateway__Unauthorized();

        if (approve) {
            visaSystem.approveVisa(applicant);
        } else {
            visaSystem.rejectVisa(applicant, reason); // Use provided reason
        }
    }
}
