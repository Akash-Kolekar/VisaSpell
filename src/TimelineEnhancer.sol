// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStudentVisaSystem} from "./interface/IStudentVisaSystem.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract TimelineEnhancer is AccessControl {
    error TimelineEnhancer__VisaSystemNotConfigured();
    error TimelineEnhancer__Unauthorized();

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PREDICTOR_ROLE = keccak256("PREDICTOR_ROLE");

    IStudentVisaSystem private visaSystem;

    struct Prediction {
        uint256 estimatedDays;
        uint256 successProbability;
        uint256 timestamp;
    }

    mapping(address => Prediction[]) public applicantPredictions;

    event PredictionGenerated(address applicant, uint256 estimatedDays, uint256 successProbability);
    event VisaSystemUpdated(address oldSystem, address newSystem);

    constructor(address _visaSystem) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(PREDICTOR_ROLE, msg.sender);
        visaSystem = IStudentVisaSystem(_visaSystem);
    }

    function generatePrediction(address applicant) external onlyRole(PREDICTOR_ROLE) returns (Prediction memory) {
        if (address(visaSystem) == address(0)) revert TimelineEnhancer__VisaSystemNotConfigured();

        // Check if applicant exists
        if (!visaSystem.hasApplication(applicant)) revert TimelineEnhancer__Unauthorized();

        (IStudentVisaSystem.VisaStatus status, uint256 credibility, uint256 created) =
            visaSystem.getApplicationCore(applicant);

        IStudentVisaSystem.Priority priority = visaSystem.getTimelinePriority(applicant);
        uint256 deadlineDate = visaSystem.getTimelineDeadline(applicant);

        Prediction memory newPrediction = Prediction({
            estimatedDays: _calculateProcessingTime(priority, created),
            successProbability: _calculateSuccessProbability(credibility, priority),
            timestamp: block.timestamp
        });

        applicantPredictions[applicant].push(newPrediction);

        emit PredictionGenerated(applicant, newPrediction.estimatedDays, newPrediction.successProbability);
        return newPrediction;
    }

    function setVisaSystem(address _visaSystem) external onlyRole(ADMIN_ROLE) {
        address oldSystem = address(visaSystem);
        visaSystem = IStudentVisaSystem(_visaSystem);
        emit VisaSystemUpdated(oldSystem, _visaSystem);
    }

    // Add this function to allow admin to grant roles
    function grantRole(address account, bytes32 role) external onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    function _calculateProcessingTime(IStudentVisaSystem.Priority priority, uint256 createdAt)
        internal
        view
        returns (uint256)
    {
        if (priority == IStudentVisaSystem.Priority.STANDARD) {
            return visaSystem.standardProcessingTime();
        } else if (priority == IStudentVisaSystem.Priority.EXPEDITED) {
            return visaSystem.expeditedProcessingTime();
        } else {
            return visaSystem.emergencyProcessingTime();
        }
    }

    function _calculateSuccessProbability(uint256 credibility, IStudentVisaSystem.Priority priority)
        internal
        pure
        returns (uint256)
    {
        uint256 base = credibility > 80 ? 90 : 60;
        return base + uint256(priority) * 5; // Add priority bonus
    }
}
