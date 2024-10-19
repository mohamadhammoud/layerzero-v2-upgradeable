// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GatewayV1} from "../src/GatewayV1.sol";
import {GatewayV2} from "../src/GatewayV2.sol";
import {EndpointV2} from "../src/EndpointV2.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {MessagingFee} from "../src/OAppSender.sol";

import "openzeppelin-foundry-upgrades/Upgrades.sol";

contract GatewayUpgradeTest is Test {
    GatewayV1 gatewayV1;
    GatewayV2 gatewayV2;

    function setUp() public {
        address endpointProxy = Upgrades.deployTransparentProxy(
            "out/EndpointV2.sol/EndpointV2.json",
            msg.sender,
            abi.encodeCall(EndpointV2.initialize, (uint32(1), address(this)))
        );

        // Deploy a transparent proxy with OAppV1 as the implementation
        address gatewayV1Proxy = Upgrades.deployTransparentProxy(
            "out/GatewayV1.sol/GatewayV1.json",
            msg.sender,
            abi.encodeCall(
                GatewayV1.initialize,
                (address(endpointProxy), msg.sender)
            )
        );

        gatewayV1 = GatewayV1(gatewayV1Proxy);
    }

    function test_initialization() public {
        assertEq(gatewayV1.versionedFunction(), "This is OApp V1");
        assertEq(gatewayV1.lastReceivedMessage(), "");
        assertEq(gatewayV1.lastReceivedSrcEid(), 0);
        assertEq(gatewayV1.lastSender(), 0x00);
    }

    function test_upgradeToV2() public {
        // Get the new implementation address before upgrade
        address implAddrV1 = Upgrades.getImplementationAddress(
            address(gatewayV1)
        );

        // Upgrade the proxy to ContractB
        Upgrades.upgradeProxy(
            address(gatewayV1),
            "out/GatewayV2.sol/GatewayV2.json",
            "",
            msg.sender
        );

        assertEq(gatewayV1.versionedFunction(), "This is OApp V2");

        // Get the new implementation address after upgrade
        address implAddrV2 = Upgrades.getImplementationAddress(
            address(gatewayV1)
        );

        // Verify implementation address has changed
        assertFalse(implAddrV1 == implAddrV2);
    }
}
