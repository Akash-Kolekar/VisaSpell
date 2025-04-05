// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {StudentVisaSystem} from "../src/StudentVisaSystem.sol";
import {EmbassyGateway} from "../src/EmbassyGateway.sol";
import {FeeManager} from "../src/FeeManager.sol";
import {TimelineEnhancer} from "../src/TimelineEnhancer.sol";
import {UniversityHandler} from "../src/UniversityHandler.sol";
import {VerificationHub} from "../src/VerificationHub.sol";

contract DeploySVS is Script {
    address admin = 0xB58634C4465D93A03801693FD6d76997C797e42A;
    address treasury = 0x76b1e60A5Bdd0954C951Ff91Ce40675c87F74507;

    // Add a flag for test mode
    bool internal testMode = false;

    // Allow test mode to be set
    function setTestMode(bool _testMode) public {
        testMode = _testMode;
    }

    function run()
        external
        returns (StudentVisaSystem, EmbassyGateway, FeeManager, TimelineEnhancer, UniversityHandler, VerificationHub)
    {
        // Only use broadcasting if not in test mode
        if (!testMode) {
            vm.startBroadcast(admin);
        }

        // 1. Deploy core contracts
        StudentVisaSystem svs = new StudentVisaSystem();
        FeeManager feeManager = new FeeManager(treasury);

        // 2. Deploy supporting contracts with StudentVisaSystem address
        VerificationHub verificationHub = new VerificationHub(address(svs));
        UniversityHandler universityHandler = new UniversityHandler(address(svs));
        TimelineEnhancer timelineEnhancer = new TimelineEnhancer(address(svs));
        EmbassyGateway embassyGateway = new EmbassyGateway(address(svs));

        // 3. Initialize dependencies in StudentVisaSystem
        svs.initializeDependencies(
            address(universityHandler), address(verificationHub), address(feeManager), address(timelineEnhancer)
        );

        // 4. Grant necessary roles for cross-contract communication

        // Setup roles for VerificationHub
        svs.grantRole(address(verificationHub), svs.VERIFICATION_HUB_ROLE());
        verificationHub.initializeRoles(); // This grants the VERIFICATION_HUB_ROLE to itself internally

        // Setup roles for EmbassyGateway
        svs.grantRole(address(embassyGateway), svs.EMBASSY_ROLE());

        // Setup roles for FeeManager
        feeManager.grantRole(address(svs), feeManager.VISA_SYSTEM_ROLE());

        // Setup roles for UniversityHandler
        svs.grantRole(address(universityHandler), svs.UNIVERSITY_ROLE());

        // Setup roles for TimelineEnhancer
        timelineEnhancer.grantRole(address(svs), timelineEnhancer.PREDICTOR_ROLE());

        // 5. Register test entities (optional for testing)
        // Register a test university
        universityHandler.registerUniversity(admin, "TestUniversity");

        // Register a test verifier
        verificationHub.registerVerifier(admin, "Test Credentials");

        if (!testMode) {
            vm.stopBroadcast();
        }

        return (svs, embassyGateway, feeManager, timelineEnhancer, universityHandler, verificationHub);
    }
}
