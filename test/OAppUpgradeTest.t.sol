// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {GatewayV1} from "../src/GatewayV1.sol";
import {GatewayV2} from "../src/GatewayV2.sol";
import {EndpointV2Upgradeable} from "../src/EndpointV2Upgradeable.sol";
import {MessagingFee} from "../src/OAppSenderUpgradeable.sol";

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title GatewayUpgradeTest
/// @notice Test suite for deploying and upgrading Gateway contracts using OpenZeppelin proxy
contract GatewayUpgradeTest is Test {
    ProxyAdmin public proxyAdmin;
    TransparentUpgradeableProxy public gatewayProxy;

    GatewayV1 public gatewayV1;
    GatewayV1 public gatewayV1A;
    GatewayV1 public gatewayV1B;

    EndpointV2Upgradeable public endpointA;
    EndpointV2Upgradeable public endpointB;

    uint32 constant eidA = 1;
    uint32 constant eidB = 2;

    /// @notice Deploys ProxyAdmin and necessary endpoints before each test
    function setUp() public {
        endpointA = _deployEndpoint(eidA);
        endpointB = _deployEndpoint(eidB);

        gatewayV1 = _deployGatewayV1(address(endpointA));
        gatewayV1A = _deployGatewayV1(address(endpointA));
        gatewayV1B = _deployGatewayV1(address(endpointB));
    }

    /// @notice Deploys an EndpointV2Upgradeable using ERC1967 proxy
    /// @param eid The unique identifier for the endpoint
    /// @return The deployed EndpointV2Upgradeable proxy instance
    function _deployEndpoint(
        uint32 eid
    ) internal returns (EndpointV2Upgradeable) {
        EndpointV2Upgradeable endpoint = EndpointV2Upgradeable(
            address(
                new ERC1967Proxy(
                    address(new EndpointV2Upgradeable()),
                    abi.encodeCall(
                        EndpointV2Upgradeable.initialize,
                        (eid, address(this))
                    )
                )
            )
        );
        return endpoint;
    }

    /// @notice Deploys a GatewayV1 contract using ERC1967 proxy and initializes it
    /// @param endpoint The address of the endpoint associated with the GatewayV1 contract
    /// @return The deployed GatewayV1 proxy instance
    function _deployGatewayV1(address endpoint) internal returns (GatewayV1) {
        GatewayV1 gateway = GatewayV1(
            address(
                new ERC1967Proxy(
                    address(new GatewayV1()),
                    abi.encodeCall(
                        GatewayV1.initialize,
                        (endpoint, address(this))
                    )
                )
            )
        );
        return gateway;
    }

    /// @notice Verifies the initial state of the deployed GatewayV1 contract
    function test_initialization() public {
        assertEq(gatewayV1.versionedFunction(), "This is OApp V1");
        assertEq(gatewayV1.lastReceivedMessage(), "");
        assertEq(gatewayV1.lastReceivedSrcEid(), 0);
        assertEq(gatewayV1.lastSender(), bytes32(0));
    }

    /// @notice Tests the upgrade process from GatewayV1 to GatewayV2
    function test_upgradeToV2() public {
        GatewayV2 gatewayV2 = new GatewayV2();
        address gatewayV2Address = address(gatewayV2);
        bytes memory data = abi.encodeCall(gatewayV2.versionedFunction, ());

        GatewayV1(gatewayV1).upgradeToAndCall(gatewayV2Address, data);
        assertEq(gatewayV1.versionedFunction(), "This is OApp V2");
    }
}
