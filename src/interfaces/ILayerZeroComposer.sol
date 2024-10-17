// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @title ILayerZeroComposer
 * @dev Interface for composing LayerZero messages by an OApp. This interface facilitates the creation and execution of composed messages within the LayerZero framework.
 */
interface ILayerZeroComposer {
    /**
     * @notice Composes and executes a LayerZero message from an Omnichain Application (OApp).
     * @dev This function is called to compose a message after it has been received and processed by the OApp.
     *      The composed message might not necessarily be the same as the one received by the OApp.
     * @param _from The address of the OApp that is initiating the message composition, typically the OApp that received the `lzReceive` call.
     * @param _guid The unique identifier (GUID) for the corresponding LayerZero transaction (source and destination).
     * @param _message The composed message payload in bytes. This is the content of the message being composed and passed to the destination.
     * @param _executor The address responsible for executing the composed message.
     * @param _extraData Additional arbitrary data provided by the entity executing the composed message, passed along for custom logic or verification.
     */
    function lzCompose(
        address _from,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable;
}
