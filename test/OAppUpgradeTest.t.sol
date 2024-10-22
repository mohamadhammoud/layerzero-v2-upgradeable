// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GatewayV1} from "../src/GatewayV1.sol";
import {GatewayV2} from "../src/GatewayV2.sol";
import {EndpointV2Upgradeable} from "../src/EndpointV2Upgradeable.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {MessagingFee} from "../src/OAppSenderUpgradeable.sol";

import "openzeppelin-foundry-upgrades/Upgrades.sol";

contract GatewayUpgradeTest is Test {
    GatewayV1 gatewayV1;
    GatewayV1 gatewayV1A;
    GatewayV1 gatewayV1B;
    EndpointV2Upgradeable endpointv2A;
    EndpointV2Upgradeable endpointv2B;

    uint32 constant eidA = 1;
    uint32 constant eidB = 2;

    // Setup function that runs before each test
    function setUp() public {
        // Deploy endpoints
        endpointv2A = deployEndpoint(eidA);
        endpointv2B = deployEndpoint(eidB);

        // Deploy gateways
        gatewayV1 = deployGateway(address(endpointv2A));
        gatewayV1A = deployGateway(address(endpointv2A));
        gatewayV1B = deployGateway(address(endpointv2B));
    }

    // Function to deploy an EndpointV2
    function deployEndpoint(
        uint32 eid
    ) internal returns (EndpointV2Upgradeable) {
        address endpointProxy = Upgrades.deployTransparentProxy(
            "out/EndpointV2Upgradeable.sol/EndpointV2Upgradeable.json",
            msg.sender,
            abi.encodeCall(
                EndpointV2Upgradeable.initialize,
                (eid, address(this))
            )
        );
        return EndpointV2Upgradeable(endpointProxy);
    }

    // Function to deploy a GatewayV1
    function deployGateway(address endpoint) internal returns (GatewayV1) {
        address gatewayProxy = Upgrades.deployTransparentProxy(
            "out/GatewayV1.sol/GatewayV1.json",
            msg.sender,
            abi.encodeCall(GatewayV1.initialize, (endpoint, msg.sender))
        );
        return GatewayV1(gatewayProxy);
    }

    // Test to verify the initial state of the GatewayV1
    function test_initialization() public {
        // Check if the contract is properly initialized
        assertEq(gatewayV1.versionedFunction(), "This is OApp V1");
        assertEq(gatewayV1.lastReceivedMessage(), "");
        assertEq(gatewayV1.lastReceivedSrcEid(), 0);
        assertEq(gatewayV1.lastSender(), (0x00));
    }

    // Test the upgrade from GatewayV1 to GatewayV2
    function test_upgradeToV2() public {
        // Get initial implementation address (before upgrade)
        address implAddrV1 = Upgrades.getImplementationAddress(
            address(gatewayV1)
        );

        // Upgrade the proxy to GatewayV2
        Upgrades.upgradeProxy(
            address(gatewayV1),
            "out/GatewayV2.sol/GatewayV2.json",
            "",
            msg.sender
        );

        // Check if the contract is now using the upgraded version
        assertEq(gatewayV1.versionedFunction(), "This is OApp V2");

        // Get new implementation address (after upgrade)
        address implAddrV2 = Upgrades.getImplementationAddress(
            address(gatewayV1)
        );

        // Verify that the implementation address has changed after the upgrade
        assertFalse(implAddrV1 == implAddrV2);
    }
}
