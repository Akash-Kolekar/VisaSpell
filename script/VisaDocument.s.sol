// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {VisaDocument} from "../src/VisaDocument.sol";

contract DeployVisaDocument is Script {

    address Admin = makeAddr("Admin");
    
    function run() external returns(VisaDocument) {

        vm.startBroadcast(Admin);
        VisaDocument visa = new VisaDocument();
        vm.stopBroadcast();

        return visa;

    }

}
