// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {UniversityHandler} from "../../src/UniversityHandler.sol";

/**
 * @title Register Program Script
 * @notice Registers a university program - Run by university
 */
contract RegisterProgram is Script {
    // Contract addresses
    address constant ADMIN_ACCOUNT = 0xB58634C4465D93A03801693FD6d76997C797e42A;

    address constant UNIVERSITY_HANDLER_ADDRESS = 0x024a9f709e15F9Bd0B4a1535E1c4a740dCa8893D;
    address constant UNIVERSITY_ACCOUNT = 0x04F136a9B269e1efb6eB6E9D24cb2884BdbfFb11;
    // Program details
    string programId = "CS101";

    function run() external {
        // This broadcasts as the specified address directly
        vm.startBroadcast(ADMIN_ACCOUNT);

        UniversityHandler universityHandler = UniversityHandler(UNIVERSITY_HANDLER_ADDRESS);

        console.log("University address: %s", UNIVERSITY_ACCOUNT);
        console.log("Registering program: %s", programId);

        // Register program
        universityHandler.registerProgram(programId);

        console.log("Program registered successfully");

        vm.stopBroadcast();
    }
}
