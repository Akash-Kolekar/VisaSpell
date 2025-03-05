// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test} from "forge-std/Test.sol";
import {DeploySVS} from "../../script/DeploySVS.s.sol";
import {StudentVisaSystem} from "../../src/StudentVisaSystem.sol";
import {VerificationHub} from "../../src/VerificationHub.sol";
import {FeeManager} from "../../src/FeeManager.sol";
import {TimelineEnhancer} from "../../src/TimelineEnhancer.sol";
import {UniversityHandler} from "../../src/UniversityHandler.sol";
import {EmbassyGateway} from "../../src/EmbassyGateway.sol";

contract SVSTest is Test {
    DeploySVS deployer;

    function setUp() public {
        deployer = new DeploySVS();
    }
}
