// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {OAppV1} from "../src/OAppV1.sol";
import {OAppV2} from "../src/OAppV2.sol";
import {EndpointV2} from "../src/EndpointV2.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import "openzeppelin-foundry-upgrades/Upgrades.sol";

/**
 * @title OAppUpgradeTest
 * @dev Test suite for upgrading OAppV1 to OAppV2 using TransparentUpgradeableProxy.
 */
contract OAppUpgradeTest is Test {
    OAppV1 public oAppV1;
    OAppV2 public oAppV2;
    // TransparentUpgradeableProxy public proxy;
    ProxyAdmin public admin;
    address public owner;
    address public delegate;

    function testTransparent() public {
        address endpointProxy = Upgrades.deployTransparentProxy(
            "out/EndpointV2.sol/EndpointV2.json",
            msg.sender,
            abi.encodeCall(EndpointV2.initialize, (uint32(1), msg.sender))
        );

        // Deploy a transparent proxy with OAppV1 as the implementation
        address proxy = Upgrades.deployTransparentProxy(
            "out/OAppV1.sol/OAppV1.json",
            msg.sender,
            abi.encodeCall(
                OAppV1.initialize,
                (address(endpointProxy), msg.sender)
            )
        );

        assertEq(OAppV1(proxy).versionedFunction(), "This is OApp V1");

        // Get the implementation address of the proxy
        address implAddrV1 = Upgrades.getImplementationAddress(proxy);

        // Get the admin address of the proxy
        address adminAddr = Upgrades.getAdminAddress(proxy);

        // Ensure the admin address is valid
        assertFalse(adminAddr == address(0));

        // Log the initial version
        console.log("----------------------------------");
        console.log(
            "Value before upgrade --> ",
            OAppV1(proxy).versionedFunction()
        );
        console.log("----------------------------------");

        // Upgrade the proxy to ContractB
        Upgrades.upgradeProxy(
            proxy,
            "out/OAppV2.sol/OAppV2.json",
            "",
            msg.sender
        );

        assertEq(OAppV1(proxy).versionedFunction(), "This is OApp V2");

        // Get the new implementation address after upgrade
        address implAddrV2 = Upgrades.getImplementationAddress(proxy);

        // Verify implementation address has changed
        assertFalse(implAddrV1 == implAddrV2);

        // Log and verify the updated value
        console.log("----------------------------------");
        console.log(
            "Value after upgrade --> ",
            OAppV1(proxy).versionedFunction()
        );
        console.log("----------------------------------");
    }
}
