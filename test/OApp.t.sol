// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {TestHelper} from "@layerzerolabs/lz-evm-oapp-v2/test/TestHelper.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {GatewayV1} from "../src/GatewayV1.sol";
import {GatewayV2} from "../src/GatewayV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {MessagingFee} from "../src/interfaces/ILayerZeroEndpointV2.sol";
import {EndpointV2Upgradeable} from "../src/EndpointV2Upgradeable.sol";

contract OAppUpgradeableTest is TestHelper {
    using OptionsBuilder for bytes;

    EndpointV2Upgradeable public endpointA;
    EndpointV2Upgradeable public endpointB;

    GatewayV1 public gatewayA;
    GatewayV1 public gatewayB;
    ProxyAdmin public proxyAdmin; // Admin to manage the proxies

    uint32 aEid = 1;
    uint32 bEid = 2;

    // Setup function to deploy upgradeable OApps using setupUpgradeableOApps
    function setUp() public virtual override {
        super.setUp();

        setUpEndpoints(2, LibraryType.UltraLightNode);

        // Use the new setupUpgradeableOApps to deploy upgradeable contracts
        address[] memory deployedGateways = setupUpgradeableOApps(
            type(GatewayV1).creationCode,
            uint8(aEid),
            uint8(bEid)
        );

        // Assign proxies as GatewayV1 contracts
        gatewayA = GatewayV1(payable(deployedGateways[0]));
        gatewayB = GatewayV1(payable(deployedGateways[1]));

        // Set up peers for cross-chain communication
        gatewayA.setPeer(bEid, addressToBytes32(address(gatewayB)));
        gatewayB.setPeer(aEid, addressToBytes32(address(gatewayA)));
    }

    // Test cross-chain message passing from A to B
    function test_sendMessageFromAToB() public {
        string memory message = "Hello from A to B";

        // Prepare options for the message
        bytes memory options = OptionsBuilder
            .newOptions()
            .addExecutorLzReceiveOption(200000, 0);

        // Get the MessagingFee struct
        MessagingFee memory fee = gatewayA.quote(bEid, message, options, false);

        // Send the message from A to B, using the `native` field of the MessagingFee struct
        gatewayA.send{value: fee.nativeFee}(bEid, message, options);

        // At this point, the message is sent but not processed by B. So, B's state should be unchanged.
        assertEq(gatewayB.lastReceivedMessage(), "");

        // Simulate the packet being verified on chain B
        verifyPackets(bEid, address(gatewayB));

        // Now, after verifying, B should have received the message
        assertEq(gatewayB.lastReceivedMessage(), message);
    }

    // Test upgrading the GatewayV1 proxy to GatewayV2
    function test_upgradeToGatewayV2() public {
        GatewayV2 newImplementation = new GatewayV2();

        address gatewayV2Address = address(newImplementation);

        bytes memory data = abi.encodeCall(
            newImplementation.versionedFunction,
            ()
        );

        GatewayV1(gatewayA).upgradeToAndCall(gatewayV2Address, data);
        assertEq(GatewayV1(gatewayA).versionedFunction(), "This is OApp V2");
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

    /**
     * @notice Sets up upgradeable OApp contracts using proxies for testing.
     * @param _oappCreationCode The bytecode for creating OApp contracts.
     * @param _startEid The starting endpoint ID for OApp setup.
     * @param _oappNum The number of OApps to set up.
     * @return oapps An array of addresses for the deployed upgradeable OApp proxies.
     */
    function setupUpgradeableOApps(
        bytes memory _oappCreationCode,
        uint8 _startEid,
        uint8 _oappNum
    ) public returns (address[] memory oapps) {
        oapps = new address[](_oappNum);

        for (uint8 eid = _startEid; eid < _startEid + _oappNum; eid++) {
            // Step 1: Deploy the OApp implementation
            address oappImplementation = _deployOApp(
                _oappCreationCode,
                abi.encode(address(endpoints[eid]), address(this), true)
            );

            // Step 2: Deploy an ERC1967Proxy with the OApp implementation
            ERC1967Proxy proxy = new ERC1967Proxy(
                oappImplementation,
                abi.encodeWithSignature(
                    "initialize(address,address)",
                    address(endpoints[eid]),
                    address(this)
                )
            );

            // Step 3: Store the proxy address
            oapps[eid - _startEid] = address(proxy);
        }

        // Step 4: Configure the peers (if applicable)
        wireOApps(oapps);
    }
}
