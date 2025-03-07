// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {StudentVisaSystem} from "../src/StudentVisaSystem.sol";
import {EmbassyGateway} from "../src/EmbassyGateway.sol";
import {FeeManager} from "../src/FeeManager.sol";
import {TimelineEnhancer} from "../src/TimelineEnhancer.sol";
import {UniversityHandler} from "../src/UniversityHandler.sol";
import {VerificationHub} from "../src/VerificationHub.sol";
import {Script} from "forge-std/Script.sol";
import {DeploySVS} from "./DeploySVS.s.sol";

contract DeployOtherSC is Script {
    address admin = 0xB58634C4465D93A03801693FD6d76997C797e42A;
    address svs = 0x1221d1F70EE5Df5C0c2b9Efac309156aB541f300;
    address treasury = 0x76b1e60A5Bdd0954C951Ff91Ce40675c87F74507;
    // address svs;

    // constructor(address _svs) {
    //     svs = _svs;
    // }

    function run()
        external
        returns (EmbassyGateway, FeeManager, TimelineEnhancer, UniversityHandler, VerificationHub)
    {
        // vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        vm.startBroadcast();
        EmbassyGateway embassyGateway = new EmbassyGateway(address(svs));
        FeeManager feeManager = new FeeManager(address(treasury));
        TimelineEnhancer timelineEnhancer = new TimelineEnhancer(address(svs));
        UniversityHandler universityHandler = new UniversityHandler(address(svs));
        VerificationHub verificationHub = new VerificationHub(address(svs));

        StudentVisaSystem(address(svs)).initializeDependencies(
            address(universityHandler), address(verificationHub), address(feeManager), address(timelineEnhancer)
        );
        vm.stopBroadcast();

        return (embassyGateway, feeManager, timelineEnhancer, universityHandler, verificationHub);
    }
}
