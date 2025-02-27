// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import {UniversityRegistry} from "../../src/UniversityRegistry.sol";
import {DeployUniversityRegistry} from "../../script/UniversityRegistry.s.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";

contract UniversityRegistryTest is Test {

    UniversityRegistry uniRegistry;

    address Manager = makeAddr("Manager");

    function setUp() public {
        DeployUniversityRegistry deploy = new DeployUniversityRegistry();
        uniRegistry = deploy.run();
    }

    /*//////////////////////////////////////////////////////////////
                              Failure Test
    //////////////////////////////////////////////////////////////*/

    function test_registerUniversity_revert() public {
        // 1. this function can only be called by manager (person with specific role)
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector, 
                address(this), // msg.sender
                keccak256("REGISTRY_MANAGER_ROLE") // role should have
            )
        );
        uniRegistry.registerUniversity("MB-1", "MafiaBoss", "MyHouse", "No-ID");

        // 2. no duplication university is to be registered
        vm.prank(Manager);
        uniRegistry.registerUniversity("GOD", "GOD_UNI", "Heaven", "HI");

        vm.expectRevert(
            abi.encodePacked(
                "University ID already exists"
            )
        );
        vm.prank(Manager);
        uniRegistry.registerUniversity("GOD", "GOD_UNI", "Heaven", "HI");

    }

    /*//////////////////////////////////////////////////////////////
                          test register a uni
    //////////////////////////////////////////////////////////////*/

    function test_can_register_university() public {

        // expected log
        vm.expectEmit(false, false, false, true);
        emit UniversityRegistry.UniversityRegistered("U-1", "Harward", "Malaysia");
        
        // call function
        vm.prank(Manager);
        uniRegistry.registerUniversity(
            "U-1", // uni id
            "Harward", // uni name
            "Malaysia", // country
            "A-1" // accreditation id
        );

        // call getter
        address[] memory ExpectedAuthorizedSigners = new address[](0);
        (
            string memory name,
            string memory country,
            string memory accreditationId,
            bool isVerified,
            bool isActive,
            uint registeredAt,
            uint lastUpdated,
            address[] memory authorizedSigners 
        ) = uniRegistry.getUniversityDetails("U-1");

        // check assertion with getter called
        assertEq(name, "Harward");
        assertEq(country, "Malaysia");
        assertEq(accreditationId, "A-1");
        assertEq(isVerified, false);
        assertEq(isActive, true);
        assertEq(registeredAt, block.timestamp);
        assertEq(lastUpdated, block.timestamp);
        assertEq(authorizedSigners, ExpectedAuthorizedSigners);

    }

}
