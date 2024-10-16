// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {Origin} from "./ILayerZeroEndpointV2.sol";

/// @title ILayerZeroReceiver Interface for LayerZero Message Receiver
/// @notice This interface handles receiving LayerZero messages, verifying paths, and retrieving nonces.
/// @dev This interface supports message receipt, path initialization checks, and nonce tracking for incoming messages.
interface ILayerZeroReceiver {
    /// @notice Checks whether a path initialization from a specific origin is allowed.
    /// @dev This function verifies if the path from a specific origin is authorized for initialization.
    /// @param _origin The origin data containing source environment ID and sender information.
    /// @return A boolean indicating whether the path initialization is allowed (`true`) or denied (`false`).
    function allowInitializePath(
        Origin calldata _origin
    ) external view returns (bool);

    /// @notice Retrieves the next inbound nonce for a specific sender from a given environment ID (chain ID).
    /// @param _eid The environment ID (chain ID) from which the message originates.
    /// @param _sender The address (bytes32) of the sender on the source chain.
    /// @return The next expected inbound nonce for the specified sender and environment.
    function nextNonce(
        uint32 _eid,
        bytes32 _sender
    ) external view returns (uint64);

    /// @notice Receives a LayerZero message, processes it, and executes it on the destination chain.
    /// @dev This function processes an incoming message, performs validation, and ensures proper execution using the specified executor.
    /// @param _origin The origin data containing source environment ID and sender information.
    /// @param _guid A globally unique identifier (GUID) for the message.
    /// @param _message The payload of the incoming message.
    /// @param _executor The address of the executor responsible for processing the message.
    /// @param _extraData Additional data that may be required for executing the message.
    function lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) external payable;
}
