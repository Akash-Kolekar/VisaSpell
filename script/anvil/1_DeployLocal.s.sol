// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {StudentVisaSystem} from "../../src/StudentVisaSystem.sol";
import {EmbassyGateway} from "../../src/EmbassyGateway.sol";
import {FeeManager} from "../../src/FeeManager.sol";
import {TimelineEnhancer} from "../../src/TimelineEnhancer.sol";
import {UniversityHandler} from "../../src/UniversityHandler.sol";
import {VerificationHub} from "../../src/VerificationHub.sol";

contract DeployLocal is Script {
    // Anvil's default accounts with 10000 ETH each
    address constant ADMIN = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // Account #0
    address constant UNIVERSITY = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8; // Account #1
    address constant EMBASSY = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // Account #2
    address constant VERIFIER = 0x90F79bf6EB2c4f870365E785982E1f101E93b906; // Account #3
    address constant APPLICANT = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65; // Account #4
    address constant TREASURY = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc; // Account #5

    function run()
        external
        returns (
            StudentVisaSystem svs,
            EmbassyGateway embassyGateway,
            FeeManager feeManager,
            TimelineEnhancer timelineEnhancer,
            UniversityHandler universityHandler,
            VerificationHub verificationHub
        )
    {
        vm.startBroadcast(ADMIN);

        // 1. Deploy core contracts
        svs = new StudentVisaSystem();
        feeManager = new FeeManager(TREASURY);

        // 2. Deploy supporting contracts
        verificationHub = new VerificationHub(address(svs));
        universityHandler = new UniversityHandler(address(svs));
        timelineEnhancer = new TimelineEnhancer(address(svs));
        embassyGateway = new EmbassyGateway(address(svs));

        // 3. Initialize dependencies
        svs.initializeDependencies(
            address(universityHandler), address(verificationHub), address(feeManager), address(timelineEnhancer)
        );

        // 4. Set up cross-contract communication
        svs.grantRole(address(verificationHub), svs.VERIFICATION_HUB_ROLE());
        verificationHub.initializeRoles();
        svs.grantRole(address(embassyGateway), svs.EMBASSY_ROLE());
        feeManager.grantRole(address(svs), feeManager.VISA_SYSTEM_ROLE());
        svs.grantRole(address(universityHandler), svs.UNIVERSITY_ROLE());
        timelineEnhancer.grantRole(address(svs), timelineEnhancer.PREDICTOR_ROLE());

        // 5. Grant roles to Anvil accounts
        svs.grantRole(svs.UNIVERSITY_ROLE(), UNIVERSITY);
        svs.grantRole(svs.EMBASSY_ROLE(), EMBASSY);
        svs.grantRole(svs.BANK_ROLE(), VERIFIER);

        // 6. Register entities
        universityHandler.registerUniversity(UNIVERSITY, "Harvard");
        verificationHub.registerVerifier(VERIFIER, "Official Verifier");
        embassyGateway.registerEmbassyOfficial(EMBASSY);

        console.log("Deployment complete. Contract addresses:");
        console.log("StudentVisaSystem:", address(svs));
        console.log("EmbassyGateway:", address(embassyGateway));
        console.log("FeeManager:", address(feeManager));
        console.log("TimelineEnhancer:", address(timelineEnhancer));
        console.log("UniversityHandler:", address(universityHandler));
        console.log("VerificationHub:", address(verificationHub));

        vm.stopBroadcast();

        return (svs, embassyGateway, feeManager, timelineEnhancer, universityHandler, verificationHub);
    }
}
