// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/// @title IMessagingComposer Interface for Composing and Sending Messages
/// @notice This interface defines the functions and events for composing and delivering messages across LayerZero, including alert mechanisms and gas/value tracking.
/// @dev The interface supports message queuing, sending, and logging delivery/alerts for messages.
interface IMessagingComposer {
    /// @notice Emitted when a message composition is sent.
    /// @param from The address of the sender.
    /// @param to The address of the recipient.
    /// @param guid A globally unique identifier (GUID) for the message.
    /// @param index The index of the message in the composition (in case of multi-part messages).
    /// @param message The actual message data that is being sent.
    event ComposeSent(
        address from,
        address to,
        bytes32 guid,
        uint16 index,
        bytes message
    );

    /// @notice Emitted when a composed message has been successfully delivered.
    /// @param from The address of the sender.
    /// @param to The address of the recipient.
    /// @param guid A globally unique identifier (GUID) for the message.
    /// @param index The index of the message in the composition.
    event ComposeDelivered(
        address from,
        address to,
        bytes32 guid,
        uint16 index
    );

    /// @notice Emitted when there is an alert in LayerZero due to an issue with the composed message.
    /// @dev Alerts may occur when gas limits are exceeded, or when the message cannot be processed properly.
    /// @param from The address of the sender.
    /// @param to The address of the recipient.
    /// @param executor The address of the entity executing the message delivery.
    /// @param guid A globally unique identifier (GUID) for the message.
    /// @param index The index of the message in the composition.
    /// @param gas The amount of gas used for processing the message.
    /// @param value The value (in wei) sent with the message.
    /// @param message The actual message data.
    /// @param extraData Additional data attached to the message (e.g., metadata).
    /// @param reason The reason for the alert, such as an error message or a gas limit issue.
    event LzComposeAlert(
        address indexed from,
        address indexed to,
        address indexed executor,
        bytes32 guid,
        uint16 index,
        uint256 gas,
        uint256 value,
        bytes message,
        bytes extraData,
        bytes reason
    );

    /// @notice Returns the hash of a composed message in the queue.
    /// @param _from The address of the sender.
    /// @param _to The address of the recipient.
    /// @param _guid A globally unique identifier (GUID) for the message.
    /// @param _index The index of the message in the composition.
    /// @return messageHash The hash of the message data in the queue.
    function composeQueue(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index
    ) external view returns (bytes32 messageHash);

    /// @notice Sends a composed message to the recipient.
    /// @dev This function allows the sender to send a message to the specified recipient.
    /// @param _to The address of the recipient.
    /// @param _guid A globally unique identifier (GUID) for the message.
    /// @param _index The index of the message in the composition.
    /// @param _message The actual message data being sent.
    function sendCompose(
        address _to,
        bytes32 _guid,
        uint16 _index,
        bytes calldata _message
    ) external;

    /// @notice Composes and sends a LayerZero message along with additional data and payment.
    /// @dev This function is payable, meaning the sender can include value (in wei) to cover message costs.
    /// @param _from The address of the sender.
    /// @param _to The address of the recipient.
    /// @param _guid A globally unique identifier (GUID) for the message.
    /// @param _index The index of the message in the composition.
    /// @param _message The actual message data being sent.
    /// @param _extraData Additional data attached to the message (e.g., metadata or instructions).
    function lzCompose(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable;
}
