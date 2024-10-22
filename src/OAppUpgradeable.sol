// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {OAppSenderUpgradeable, MessagingFee, MessagingReceipt} from "./OAppSenderUpgradeable.sol";
import {OAppReceiverUpgradeable, Origin} from "./OAppReceiverUpgradeable.sol";

/**
 * @title OApp
 * @dev Abstract contract serving as the base for OApp implementation, combining OAppSenderUpgradeable and OAppReceiverUpgradeable functionality.
 *      Inherits from OAppSenderUpgradeable and OAppReceiverUpgradeable to enable both sending and receiving messages.
 */
abstract contract OAppUpgradeable is
    OAppSenderUpgradeable,
    OAppReceiverUpgradeable
{
    /**
     * @dev Initializes the OApp with the provided endpoint and delegate.
     * @param _endpoint The address of the LOCAL LayerZero endpoint.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     */
    function __OApp_init(
        address _endpoint,
        address _delegate
    ) public initializer {
        __OAppCoreUpgradeable_init(_endpoint, _delegate); // Initialize the parent OAppCore contract
    }

    /**
     * @notice Retrieves the OApp version information.
     * @return senderVersion The version of the OAppSender.sol implementation.
     * @return receiverVersion The version of the OAppReceiver.sol implementation.
     */
    function oAppVersion()
        public
        pure
        virtual
        override(OAppSenderUpgradeable, OAppReceiverUpgradeable)
        returns (uint64 senderVersion, uint64 receiverVersion)
    {
        return (SENDER_VERSION, RECEIVER_VERSION);
    }
}
