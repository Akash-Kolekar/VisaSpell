// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StudentVisaSystem} from "../../src/StudentVisaSystem.sol";
import {VerificationHub} from "../../src/VerificationHub.sol";
import {EmbassyGateway} from "../../src/EmbassyGateway.sol";
import {UniversityHandler} from "../../src/UniversityHandler.sol";

/**
 * @title Initialize Roles Script
 * @notice Sets up initial roles - Run by admin
 */
contract InitializeRoles is Script {
    // Contract addresses
    address constant SVS_ADDRESS = 0xE57f598BaA132F479862eC7b9AA52E792E3282A7;
    address constant VERIFICATION_HUB_ADDRESS = 0x2b5DF1B6BD26602188497D8F13C45A79932d2a4f;
    address constant EMBASSY_GATEWAY_ADDRESS = 0x611646DE9FF0615249652939E3ee2813D35Eca10;
    address constant UNIVERSITY_HANDLER_ADDRESS = 0x024a9f709e15F9Bd0B4a1535E1c4a740dCa8893D;

    // Entity addresses
    address constant ADMIN_ACCOUNT = 0xB58634C4465D93A03801693FD6d76997C797e42A;
    address constant UNIVERSITY_ADDRESS = 0x04F136a9B269e1efb6eB6E9D24cb2884BdbfFb11;
    address constant EMBASSY_ADDRESS = 0xAF8E81e74bA006134493a92D1EAACb8686e86A93;
    address constant VERIFIER_ADDRESS = 0x781Bd01f97e86278397DA8C762D67E66bc67238E;

    function run() external {
        // Use admin address directly
        vm.startBroadcast(ADMIN_ACCOUNT);

        StudentVisaSystem svs = StudentVisaSystem(SVS_ADDRESS);
        VerificationHub verificationHub = VerificationHub(VERIFICATION_HUB_ADDRESS);
        EmbassyGateway embassyGateway = EmbassyGateway(EMBASSY_GATEWAY_ADDRESS);
        UniversityHandler universityHandler = UniversityHandler(UNIVERSITY_HANDLER_ADDRESS);

        console.log("Admin address: %s", ADMIN_ACCOUNT);
        console.log("Initializing roles...");

        // Grant roles in StudentVisaSystem
        svs.grantRole(svs.UNIVERSITY_ROLE(), UNIVERSITY_ADDRESS);
        svs.grantRole(svs.EMBASSY_ROLE(), EMBASSY_ADDRESS);
        svs.grantRole(svs.BANK_ROLE(), VERIFIER_ADDRESS);

        // Register verifier
        verificationHub.registerVerifier(VERIFIER_ADDRESS, "Official Document Verifier");

        // Register embassy official
        embassyGateway.registerEmbassyOfficial(EMBASSY_ADDRESS);

        // Register university
        universityHandler.registerUniversity(ADMIN_ACCOUNT, "Harvard");

        console.log("Roles initialized successfully");

        vm.stopBroadcast();
    }
}
