// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFeeManager} from "./interface/IFeeManager.sol";

contract FeeManager is IFeeManager {
    error FeeManager__NoETHSent();
    error FeeManager__PaymentFailed();

    struct Payment {
        uint256 ethPaid;
        uint256 tokenPaid;
        address tokenAddress;
    }

    // Tracks total payments per applicant
    mapping(address => uint256) public totalPayments;
    address public immutable treasury;

    event PaidInETH(address applicant, uint256 amount);
    // event PaidInToken(address applicant, address token, uint256 amount);

    constructor(address _treasury) {
        treasury = _treasury;
    }

    function getTotalPaid(address applicant) external view returns (uint256) {
        return totalPayments[applicant];
    }

    function payWithETH(address applicant) external payable {
        if (msg.value == 0) revert FeeManager__NoETHSent();
        (bool sent,) = treasury.call{value: msg.value}("");
        if (!sent) revert FeeManager__PaymentFailed();
        totalPayments[applicant] += msg.value;
        emit PaidInETH(applicant, msg.value);
    }

    // function payWithToken(address applicant, address token, uint256 amount) external {
    //     require(amount >= applicationFee, "Insufficient fee");
    //     IERC20(token).transferFrom(msg.sender, treasury, amount);
    //     payments[applicant].tokenPaid += amount;
    //     payments[applicant].tokenAddress = token;
    //     emit PaidInToken(applicant, token, amount);
    // }

    // Fallback function must be declared as external.
    fallback() external payable {}

    // Receive is a variant of fallback that is triggered when msg.data is empty
    receive() external payable {}
}
