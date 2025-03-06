// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {StudentVisaSystem} from "../src/StudentVisaSystem.sol";
import {EmbassyGateway} from "../src/EmbassyGateway.sol";
import {FeeManager} from "../src/FeeManager.sol";
import {TimelineEnhancer} from "../src/TimelineEnhancer.sol";
import {UniversityHandler} from "../src/UniversityHandler.sol";
import {VerificationHub} from "../src/VerificationHub.sol";
import {Script} from "forge-std/Script.sol";

contract DeployOtherSC is Script {
    // address svs = 0x1221d1F70EE5Df5C0c2b9Efac309156aB541f300;
    address svs;

    constructor(address _svs) {
        svs = _svs;
    }

    address treasury = 0x76b1e60A5Bdd0954C951Ff91Ce40675c87F74507;

    function run()
        external
        returns (EmbassyGateway, FeeManager, TimelineEnhancer, UniversityHandler, VerificationHub)
    {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        EmbassyGateway embassyGateway = new EmbassyGateway(svs);
        FeeManager feeManager = new FeeManager(treasury);
        TimelineEnhancer timelineEnhancer = new TimelineEnhancer(svs);
        UniversityHandler universityHandler = new UniversityHandler(svs);
        VerificationHub verificationHub = new VerificationHub(svs);

        StudentVisaSystem(svs).initializeDependencies(
            address(universityHandler), address(verificationHub), address(feeManager), address(timelineEnhancer)
        );
        vm.stopBroadcast();

        return (embassyGateway, feeManager, timelineEnhancer, universityHandler, verificationHub);
    }
}
