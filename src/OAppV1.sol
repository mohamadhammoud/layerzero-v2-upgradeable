// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OAppSender, MessagingFee, MessagingReceipt} from "./OAppSender.sol";
import {OAppReceiver, Origin} from "./OAppReceiver.sol";
import {OApp} from "./OApp.sol";

/**
 * @title OAppV1
 * @dev Inherits functionality from both OAppSender and OAppReceiver for sending and receiving messages.
 */
contract OAppV1 is OApp {
    /**
     * @dev Initializes the OAppV1 with the provided endpoint and delegate.
     * @param _endpoint The address of the LOCAL LayerZero endpoint.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     */
    function initialize(
        address _endpoint,
        address _delegate
    ) public initializer {
        __OApp_init(_endpoint, _delegate); // Initialize the parent OAppCore contract
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
        override(OApp)
        returns (uint64 senderVersion, uint64 receiverVersion)
    {
        return OApp.oAppVersion();
    }

    /**
     * @dev A simple function for V1, this will be updated in V2.
     * @return string Message from V1 contract.
     */
    function versionedFunction() public pure virtual returns (string memory) {
        return "This is OApp V1";
    }

    /**
     * @dev Receives messages from LayerZero. Implements `_lzReceive` from `OAppReceiver`.
     * @param _origin The origin chain and sender details.
     * @param _guid A globally unique identifier for the message.
     * @param _message The message payload.
     * @param _executor The address executing the message.
     * @param _extraData Additional data for execution.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual override {
        // Implement your logic for handling incoming messages here.
    }
}