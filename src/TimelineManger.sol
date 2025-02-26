// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/// @title TimelineManager
/// @notice Manages deadlines and priority processing for visa applications
contract TimelineManager is AccessControl, Pausable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant TIMELINE_MANAGER_ROLE = keccak256("TIMELINE_MANAGER_ROLE");
    bytes32 public constant VISA_CONTRACT_ROLE = keccak256("VISA_CONTRACT_ROLE");

    enum PriorityLevel {
        STANDARD,
        EXPEDITED,
        CRITICAL
    }

    enum ProcessStage {
        DOCUMENT_COLLECTION,
        VERIFICATION,
        REVIEW,
        DECISION
    }

    struct ApplicationTimeline {
        address applicant;
        uint256 enrollmentDate;
        uint256 applicationDate;
        uint256 expectedCompletionDate;
        PriorityLevel priority;
        ProcessStage currentStage;
        mapping(ProcessStage => uint256) stageDueDates;
        mapping(ProcessStage => bool) stageCompleted;
        bool isCompleted;
    }

    // Configuration for standard processing times (in days)
    uint256 public standardDocumentProcessingDays = 14;
    uint256 public standardVerificationDays = 21;
    uint256 public standardReviewDays = 7;
    uint256 public standardDecisionDays = 3;

    // Expedited times reduction factors (percentage reduction)
    uint256 public expeditedReductionPercent = 50; // 50% faster
    uint256 public criticalReductionPercent = 75; // 75% faster

    // Alert thresholds (in days)
    uint256 public warningThresholdDays = 5;
    uint256 public criticalThresholdDays = 2;

    mapping(address => ApplicationTimeline) public applicationTimelines;
    mapping(address => bool) public hasTimeline;

    // Array to track all applications for batch processing
    address[] public allApplications;

    // Indices of applications approaching deadlines
    address[] public urgentApplications;

    event TimelineCreated(address indexed applicant, uint256 enrollmentDate, PriorityLevel priority);
    event StageAdvanced(address indexed applicant, ProcessStage newStage);
    event PriorityUpdated(address indexed applicant, PriorityLevel newPriority);
    event ApplicationCompleted(address indexed applicant);
    event DeadlineApproaching(address indexed applicant, ProcessStage stage, uint256 daysRemaining);
    event DeadlineMissed(address indexed applicant, ProcessStage stage);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(TIMELINE_MANAGER_ROLE, msg.sender);
    }

    /// @notice Create a new application timeline
    function createTimeline(address applicant, uint256 enrollmentDate, PriorityLevel priority)
        external
        onlyRole(VISA_CONTRACT_ROLE)
    {
        require(!hasTimeline[applicant], "Timeline already exists");
        require(enrollmentDate > block.timestamp, "Enrollment date must be in the future");

        ApplicationTimeline storage timeline = applicationTimelines[applicant];
        timeline.applicant = applicant;
        timeline.enrollmentDate = enrollmentDate;
        timeline.applicationDate = block.timestamp;
        timeline.priority = priority;
        timeline.currentStage = ProcessStage.DOCUMENT_COLLECTION;
        timeline.isCompleted = false;

        // Calculate stage deadlines
        _calculateStageDeadlines(applicant, priority);

        // Calculate expected completion date
        timeline.expectedCompletionDate = _calculateExpectedCompletionDate(applicant);

        hasTimeline[applicant] = true;
        allApplications.push(applicant);

        emit TimelineCreated(applicant, enrollmentDate, priority);
    }

    /// @notice Update priority level for an application
    function updatePriority(address applicant, PriorityLevel newPriority) external onlyRole(TIMELINE_MANAGER_ROLE) {
        require(hasTimeline[applicant], "No timeline exists");
        require(!applicationTimelines[applicant].isCompleted, "Application already completed");

        applicationTimelines[applicant].priority = newPriority;

        // Recalculate deadlines based on new priority
        _calculateStageDeadlines(applicant, newPriority);
        applicationTimelines[applicant].expectedCompletionDate = _calculateExpectedCompletionDate(applicant);

        emit PriorityUpdated(applicant, newPriority);
    }

    /// @notice Advance application to the next stage
    function advanceStage(address applicant) external onlyRole(VISA_CONTRACT_ROLE) {
        require(hasTimeline[applicant], "No timeline exists");
        require(!applicationTimelines[applicant].isCompleted, "Application already completed");

        ApplicationTimeline storage timeline = applicationTimelines[applicant];

        // Mark current stage as completed
        timeline.stageCompleted[timeline.currentStage] = true;

        // Advance to next stage
        if (timeline.currentStage == ProcessStage.DOCUMENT_COLLECTION) {
            timeline.currentStage = ProcessStage.VERIFICATION;
        } else if (timeline.currentStage == ProcessStage.VERIFICATION) {
            timeline.currentStage = ProcessStage.REVIEW;
        } else if (timeline.currentStage == ProcessStage.REVIEW) {
            timeline.currentStage = ProcessStage.DECISION;
        } else if (timeline.currentStage == ProcessStage.DECISION) {
            timeline.isCompleted = true;
            emit ApplicationCompleted(applicant);
            return;
        }

        emit StageAdvanced(applicant, timeline.currentStage);
    }

    /// @notice Mark application as completed
    function completeApplication(address applicant) external onlyRole(VISA_CONTRACT_ROLE) {
        require(hasTimeline[applicant], "No timeline exists");
        require(!applicationTimelines[applicant].isCompleted, "Application already completed");

        ApplicationTimeline storage timeline = applicationTimelines[applicant];
        timeline.isCompleted = true;

        // Mark all stages as complete
        timeline.stageCompleted[ProcessStage.DOCUMENT_COLLECTION] = true;
        timeline.stageCompleted[ProcessStage.VERIFICATION] = true;
        timeline.stageCompleted[ProcessStage.REVIEW] = true;
        timeline.stageCompleted[ProcessStage.DECISION] = true;

        emit ApplicationCompleted(applicant);
    }

    /// @notice Check for approaching deadlines
    function checkDeadlines() external whenNotPaused {
        delete urgentApplications;

        for (uint256 i = 0; i < allApplications.length; i++) {
            address applicant = allApplications[i];

            if (!hasTimeline[applicant] || applicationTimelines[applicant].isCompleted) {
                continue;
            }

            ApplicationTimeline storage timeline = applicationTimelines[applicant];
            ProcessStage currentStage = timeline.currentStage;

            if (timeline.stageCompleted[currentStage]) {
                continue;
            }

            uint256 dueDate = timeline.stageDueDates[currentStage];
            uint256 daysRemaining = 0;

            if (block.timestamp < dueDate) {
                daysRemaining = (dueDate - block.timestamp) / 1 days;

                if (daysRemaining <= warningThresholdDays) {
                    urgentApplications.push(applicant);
                    emit DeadlineApproaching(applicant, currentStage, daysRemaining);
                }
            } else {
                emit DeadlineMissed(applicant, currentStage);
            }
        }
    }

    /// @notice Calculate stage deadlines based on priority
    function _calculateStageDeadlines(address applicant, PriorityLevel priority) internal {
        ApplicationTimeline storage timeline = applicationTimelines[applicant];

        uint256 docDays = standardDocumentProcessingDays;
        uint256 verifyDays = standardVerificationDays;
        uint256 reviewDays = standardReviewDays;
        uint256 decisionDays = standardDecisionDays;

        // Apply reduction based on priority
        if (priority == PriorityLevel.EXPEDITED) {
            docDays = docDays * (100 - expeditedReductionPercent) / 100;
            verifyDays = verifyDays * (100 - expeditedReductionPercent) / 100;
            reviewDays = reviewDays * (100 - expeditedReductionPercent) / 100;
            decisionDays = decisionDays * (100 - expeditedReductionPercent) / 100;
        } else if (priority == PriorityLevel.CRITICAL) {
            docDays = docDays * (100 - criticalReductionPercent) / 100;
            verifyDays = verifyDays * (100 - criticalReductionPercent) / 100;
            reviewDays = reviewDays * (100 - criticalReductionPercent) / 100;
            decisionDays = decisionDays * (100 - criticalReductionPercent) / 100;
        }

        // Ensure minimum 1 day for each stage
        docDays = docDays > 0 ? docDays : 1;
        verifyDays = verifyDays > 0 ? verifyDays : 1;
        reviewDays = reviewDays > 0 ? reviewDays : 1;
        decisionDays = decisionDays > 0 ? decisionDays : 1;

        // Calculate deadlines
        timeline.stageDueDates[ProcessStage.DOCUMENT_COLLECTION] = timeline.applicationDate + (docDays * 1 days);
        timeline.stageDueDates[ProcessStage.VERIFICATION] =
            timeline.stageDueDates[ProcessStage.DOCUMENT_COLLECTION] + (verifyDays * 1 days);
        timeline.stageDueDates[ProcessStage.REVIEW] =
            timeline.stageDueDates[ProcessStage.VERIFICATION] + (reviewDays * 1 days);
        timeline.stageDueDates[ProcessStage.DECISION] =
            timeline.stageDueDates[ProcessStage.REVIEW] + (decisionDays * 1 days);
    }

    /// @notice Calculate expected completion date
    function _calculateExpectedCompletionDate(address applicant) internal view returns (uint256) {
        return applicationTimelines[applicant].stageDueDates[ProcessStage.DECISION];
    }

    /// @notice Get all urgent applications
    function getUrgentApplications() external view returns (address[] memory) {
        return urgentApplications;
    }

    /// @notice Get timeline details
    function getTimelineDetails(address applicant)
        external
        view
        returns (
            uint256 enrollmentDate,
            uint256 expectedCompletionDate,
            PriorityLevel priority,
            ProcessStage currentStage,
            bool isCompleted
        )
    {
        require(hasTimeline[applicant], "No timeline exists");

        ApplicationTimeline storage timeline = applicationTimelines[applicant];
        return (
            timeline.enrollmentDate,
            timeline.expectedCompletionDate,
            timeline.priority,
            timeline.currentStage,
            timeline.isCompleted
        );
    }

    /// @notice Get stage due date
    function getStageDueDate(address applicant, ProcessStage stage) external view returns (uint256) {
        require(hasTimeline[applicant], "No timeline exists");
        return applicationTimelines[applicant].stageDueDates[stage];
    }

    /// @notice Check if stage is completed
    function isStageCompleted(address applicant, ProcessStage stage) external view returns (bool) {
        require(hasTimeline[applicant], "No timeline exists");
        return applicationTimelines[applicant].stageCompleted[stage];
    }

    /// @notice Update standard processing times
    function updateStandardTimes(uint256 docDays, uint256 verifyDays, uint256 reviewDays, uint256 decisionDays)
        external
        onlyRole(ADMIN_ROLE)
    {
        standardDocumentProcessingDays = docDays;
        standardVerificationDays = verifyDays;
        standardReviewDays = reviewDays;
        standardDecisionDays = decisionDays;
    }

    /// @notice Update reduction percentages
    function updateReductionPercentages(uint256 expeditedPercent, uint256 criticalPercent)
        external
        onlyRole(ADMIN_ROLE)
    {
        require(expeditedPercent < 100 && criticalPercent < 100, "Percentage must be < 100");
        expeditedReductionPercent = expeditedPercent;
        criticalReductionPercent = criticalPercent;
    }

    /// @notice Update alert thresholds
    function updateAlertThresholds(uint256 warningDays, uint256 criticalDays) external onlyRole(ADMIN_ROLE) {
        warningThresholdDays = warningDays;
        criticalThresholdDays = criticalDays;
    }

    /// @notice Pause contract
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /// @notice Unpause contract
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}
