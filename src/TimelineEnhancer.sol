// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {StudentVisaSystem} from "./StudentVisaSystem.sol";

contract TimelineEnhancer {
    StudentVisaSystem private visaSystem;

    struct Prediction {
        uint256 estimatedDays;
        uint256 successProbability;
        uint256 timestamp;
    }

    mapping(address => Prediction[]) public applicantPredictions;

    constructor(address _visaSystem) {
        visaSystem = StudentVisaSystem(_visaSystem);
    }

    function generatePrediction(address applicant) external returns (Prediction memory) {
        require(address(visaSystem) != address(0), "Visa system not configured");

        (StudentVisaSystem.VisaStatus status, uint256 credibility, uint256 created) =
            visaSystem.getApplicationCore(applicant);

        StudentVisaSystem.Priority priority = visaSystem.getTimelinePriority(applicant);
        uint256 deadlineDate = visaSystem.getTimelineDeadline(applicant);

        Prediction memory newPrediction = Prediction({
            estimatedDays: _calculateProcessingTime(priority, created),
            successProbability: _calculateSuccessProbability(credibility, priority),
            timestamp: block.timestamp
        });

        applicantPredictions[applicant].push(newPrediction);
        return newPrediction;
    }

    function _calculateProcessingTime(StudentVisaSystem.Priority priority, uint256 createdAt)
        internal
        view
        returns (uint256)
    {
        if (priority == StudentVisaSystem.Priority.STANDARD) {
            return visaSystem.standardProcessingTime();
        } else if (priority == StudentVisaSystem.Priority.EXPEDITED) {
            return visaSystem.expeditedProcessingTime();
        } else {
            return visaSystem.emergencyProcessingTime();
        }
    }

    function _calculateSuccessProbability(uint256 credibility, StudentVisaSystem.Priority priority)
        internal
        pure
        returns (uint256)
    {
        uint256 base = credibility > 80 ? 90 : 60;
        return base + uint256(priority) * 5; // Add priority bonus
    }
}
