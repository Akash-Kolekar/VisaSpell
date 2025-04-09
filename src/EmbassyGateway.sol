// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStudentVisaSystem} from "./interface/IStudentVisaSystem.sol";
import {IEmbassyGateway} from "./interface/IEmbassyGateway.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract EmbassyGateway is IEmbassyGateway, AccessControl {
    error EmbassyGateway__Unauthorized();
    error EmbassyGateway__InvalidApplicant();

    IStudentVisaSystem private visaSystem;
    bytes32 public constant EMBASSY_ROLE = keccak256("EMBASSY_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Track document requests
    mapping(address => string[]) public documentRequests;

    // Track decision history
    struct Decision {
        bool approved;
        string reason;
        uint256 timestamp;
        address embassy;
    }

    mapping(address => Decision[]) public decisionHistory;

    event DocumentsRequested(address applicant, string documents);
    event DecisionOverridden(address applicant, bool approved, string reason);
    event VisaSystemUpdated(address oldSystem, address newSystem);

    constructor(address _visaSystem) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(EMBASSY_ROLE, msg.sender);
        visaSystem = IStudentVisaSystem(_visaSystem);
    }

    modifier onlyEmbassy() {
        if (!visaSystem.hasRole(visaSystem.EMBASSY_ROLE(), msg.sender) && !hasRole(EMBASSY_ROLE, msg.sender)) {
            revert EmbassyGateway__Unauthorized();
        }
        _;
    }

    function requestAdditionalDocuments(address applicant, string calldata docs) external override onlyEmbassy {
        if (!visaSystem.hasApplication(applicant)) revert EmbassyGateway__InvalidApplicant();

        documentRequests[applicant].push(docs); // Store requested docs
        visaSystem.updateApplicationStatus(applicant, IStudentVisaSystem.VisaStatus.ADDITIONAL_DOCUMENTS_REQUIRED);

        emit DocumentsRequested(applicant, docs);
    }

    function overrideDecision(address applicant, bool approve, string calldata reason) external override onlyEmbassy {
        if (!visaSystem.hasApplication(applicant)) revert EmbassyGateway__InvalidApplicant();

        if (approve) {
            visaSystem.approveVisa(applicant);
        } else {
            visaSystem.rejectVisa(applicant, reason);
        }

        // Record decision history
        decisionHistory[applicant].push(
            Decision({approved: approve, reason: reason, timestamp: block.timestamp, embassy: msg.sender})
        );

        emit DecisionOverridden(applicant, approve, reason);
    }

    // Add function to update visa system
    function setVisaSystem(address _visaSystem) external onlyRole(ADMIN_ROLE) {
        address oldSystem = address(visaSystem);
        visaSystem = IStudentVisaSystem(_visaSystem);
        emit VisaSystemUpdated(oldSystem, _visaSystem);
    }

    // Get all document requests for an applicant
    function getDocumentRequests(address applicant) external view returns (string[] memory) {
        // No auth checks to remove, this function is already open
        return documentRequests[applicant];
    }

    // Register an embassy official
    function registerEmbassyOfficial(address official) external onlyRole(ADMIN_ROLE) {
        _grantRole(EMBASSY_ROLE, official);
    }
}
