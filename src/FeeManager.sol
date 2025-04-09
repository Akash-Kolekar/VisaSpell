// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFeeManager} from "./interface/IFeeManager.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract FeeManager is IFeeManager, AccessControl {
    error FeeManager__NoETHSent();
    error FeeManager__PaymentFailed();
    error FeeManager__Unauthorized();
    error FeeManager__WithdrawalFailed();

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant VISA_SYSTEM_ROLE = keccak256("VISA_SYSTEM_ROLE");

    struct Payment {
        uint256 ethPaid;
        uint256 tokenPaid;
        address tokenAddress;
    }

    // Tracks total payments per applicant
    mapping(address => uint256) public totalPayments;
    address public immutable treasury;

    event PaidInETH(address applicant, uint256 amount);
    event FeesWithdrawn(address treasury, uint256 amount);
    event FeesRefunded(address applicant, uint256 amount);

    constructor(address _treasury) {
        require(_treasury != address(0), "Invalid treasury address");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        treasury = _treasury;
    }

    function getTotalPaid(address applicant) external view returns (uint256) {
        // No auth checks to remove, this function is already open
        return totalPayments[applicant];
    }

    // Modified to restrict who can call for which applicant
    function payWithETH(address applicant) external payable {
        // Only visa system or the applicant themselves can pay
        if (msg.sender != applicant && !hasRole(VISA_SYSTEM_ROLE, msg.sender)) {
            revert FeeManager__Unauthorized();
        }

        if (msg.value == 0) revert FeeManager__NoETHSent();

        (bool sent,) = treasury.call{value: msg.value}("");
        if (!sent) revert FeeManager__PaymentFailed();

        totalPayments[applicant] += msg.value;
        emit PaidInETH(applicant, msg.value);
    }

    // Add function to refund fees (called by admin)
    function refundFees(address payable applicant, uint256 amount) external onlyRole(ADMIN_ROLE) {
        require(amount <= totalPayments[applicant], "Refund exceeds payment");

        (bool sent,) = applicant.call{value: amount}("");
        if (!sent) revert FeeManager__WithdrawalFailed();

        totalPayments[applicant] -= amount;
        emit FeesRefunded(applicant, amount);
    }

    // Add explicit withdraw function with events
    function withdrawFees(address payable recipient, uint256 amount) external onlyRole(ADMIN_ROLE) {
        require(amount <= address(this).balance, "Insufficient balance");

        (bool sent,) = recipient.call{value: amount}("");
        if (!sent) revert FeeManager__WithdrawalFailed();

        emit FeesWithdrawn(recipient, amount);
    }

    // Add this function to allow admin to grant roles
    function grantRole(address account, bytes32 role) external onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }

    // Fallback function must be declared as external.
    fallback() external payable {}

    // Receive is a variant of fallback that is triggered when msg.data is empty
    receive() external payable {}
}
