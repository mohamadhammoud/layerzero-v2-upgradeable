// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {OAppSender, MessagingFee, MessagingReceipt} from "./OAppSender.sol";
import {OAppReceiver, Origin} from "./OAppReceiver.sol";
import {OAppCore} from "./OAppCore.sol";

/**
 * @title OApp
 * @dev Abstract contract serving as the base for OApp implementation, combining OAppSender and OAppReceiver functionality.
 *      Inherits from OAppSender and OAppReceiver to enable both sending and receiving messages.
 */
abstract contract OApp is OAppSender, OAppReceiver {
    /**
     * @dev Initializes the OApp with the provided endpoint and delegate.
     * @param _endpoint The address of the LOCAL LayerZero endpoint.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     */
    function __OApp_init(
        address _endpoint,
        address _delegate
    ) public initializer {
        __OAppCore_init(_endpoint, _delegate); // Initialize the parent OAppCore contract
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
        override(OAppSender, OAppReceiver)
        returns (uint64 senderVersion, uint64 receiverVersion)
    {
        return (SENDER_VERSION, RECEIVER_VERSION);
    }
}
