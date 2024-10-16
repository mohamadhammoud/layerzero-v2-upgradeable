// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/// @title IMessagingContext Interface for Messaging Context in LayerZero
/// @notice This interface provides context about whether a message is currently being sent and retrieves the context of the sender and destination.
/// @dev This interface supports checking the messaging status and retrieving context details such as the sender and destination environment ID (eid).
interface IMessagingContext {
    /// @notice Checks whether a message is currently being sent.
    /// @dev Useful for determining the active state of message transmission.
    /// @return A boolean indicating whether a message is being sent (`true`) or not (`false`).
    function isSendingMessage() external view returns (bool);

    /// @notice Retrieves the context of the message being sent, including destination chain information and the sender's address.
    /// @dev Returns the destination environment ID and the address of the sender currently sending the message.
    /// @return dstEid The destination environment ID (chain ID) where the message is being sent.
    /// @return sender The address of the sender currently sending the message.
    function getSendContext()
        external
        view
        returns (uint32 dstEid, address sender);
}
