// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {StudentVisaSystem} from "../src/StudentVisaSystem.sol";
import {EmbassyGateway} from "../src/EmbassyGateway.sol";
import {FeeManager} from "../src/FeeManager.sol";
import {TimelineEnhancer} from "../src/TimelineEnhancer.sol";
import {UniversityHandler} from "../src/UniversityHandler.sol";
import {VerificationHub} from "../src/VerificationHub.sol";
import {DeploySVS} from "./DeploySVS.s.sol";

contract DeploySVS is Script {
    address treasury = 0x76b1e60A5Bdd0954C951Ff91Ce40675c87F74507;

    function run()
        external
        returns (StudentVisaSystem, EmbassyGateway, FeeManager, TimelineEnhancer, UniversityHandler, VerificationHub)
    {
        // vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        vm.startBroadcast();
        StudentVisaSystem svs = new StudentVisaSystem();

        EmbassyGateway embassyGateway = new EmbassyGateway(address(svs));
        FeeManager feeManager = new FeeManager(address(treasury));
        TimelineEnhancer timelineEnhancer = new TimelineEnhancer(address(svs));
        UniversityHandler universityHandler = new UniversityHandler(address(svs));
        VerificationHub verificationHub = new VerificationHub(address(svs));

        StudentVisaSystem(address(svs)).initializeDependencies(
            address(universityHandler), address(verificationHub), address(feeManager), address(timelineEnhancer)
        );

        vm.stopBroadcast();
        return (svs, embassyGateway, feeManager, timelineEnhancer, universityHandler, verificationHub);
    }
}
