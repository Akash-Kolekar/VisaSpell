// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFeeManager {
    function getTotalPaid(address applicant) external view returns (uint256);
    function payWithETH(address applicant) external payable;
    // function payWithToken(address applicant, address token, uint256 amount) external;
}
