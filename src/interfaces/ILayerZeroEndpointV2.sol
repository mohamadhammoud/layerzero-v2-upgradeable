// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {IMessageLibManager} from "./IMessageLibManager.sol";
import {IMessagingComposer} from "./IMessagingComposer.sol";
import {IMessagingChannel} from "./IMessagingChannel.sol";
import {IMessagingContext} from "./IMessagingContext.sol";

/// @title ILayerZeroEndpointV2 Interface for LayerZero Endpoint
/// @notice This interface handles message sending, receiving, and verification in the LayerZero V2 protocol. It manages fees, options, and library integrations.
/// @dev Extends multiple interfaces to cover message management, composing, and context within LayerZero.
interface ILayerZeroEndpointV2 is
    IMessageLibManager,
    IMessagingComposer,
    IMessagingChannel,
    IMessagingContext
{
    /// @notice Struct for specifying message parameters for sending messages across chains.
    /// @param dstEid The destination environment ID (chain ID).
    /// @param receiver The address of the receiver on the destination chain.
    /// @param message The actual message payload.
    /// @param options Additional options for the message, such as settings for gas or security.
    /// @param payInLzToken Boolean indicating whether to pay fees in LayerZero (LZ) tokens or native tokens.
    struct MessagingParams {
        uint32 dstEid;
        bytes32 receiver;
        bytes message;
        bytes options;
        bool payInLzToken;
    }

    /// @notice Struct for storing details about a sent message receipt.
    /// @param guid A globally unique identifier (GUID) for the message.
    /// @param nonce The nonce associated with the message.
    /// @param fee The fees (native and LZ token fees) associated with the message.
    struct MessagingReceipt {
        bytes32 guid;
        uint64 nonce;
        MessagingFee fee;
    }

    /// @notice Struct for specifying the fees associated with sending a message.
    /// @param nativeFee The fee paid in the native token for sending the message.
    /// @param lzTokenFee The fee paid in LayerZero (LZ) tokens for sending the message.
    struct MessagingFee {
        uint256 nativeFee;
        uint256 lzTokenFee;
    }

    /// @notice Struct for specifying the origin details of a message.
    /// @param srcEid The source environment ID (chain ID) from which the message originates.
    /// @param sender The address of the sender on the source chain.
    /// @param nonce The nonce associated with the message.
    struct Origin {
        uint32 srcEid;
        bytes32 sender;
        uint64 nonce;
    }

    /// @notice Emitted when a packet is sent.
    /// @param encodedPayload The payload of the packet that was sent.
    /// @param options Additional options included in the packet (e.g., gas settings).
    /// @param sendLibrary The address of the library used to send the packet.
    event PacketSent(bytes encodedPayload, bytes options, address sendLibrary);

    /// @notice Emitted when a packet is successfully verified on the destination chain.
    /// @param origin The origin data of the packet, including source chain and sender details.
    /// @param receiver The address of the receiver on the destination chain.
    /// @param payloadHash The hash of the payload that was verified.
    event PacketVerified(Origin origin, address receiver, bytes32 payloadHash);

    /// @notice Emitted when a packet is successfully delivered to the receiver on the destination chain.
    /// @param origin The origin data of the packet, including source chain and sender details.
    /// @param receiver The address of the receiver on the destination chain.
    event PacketDelivered(Origin origin, address receiver);

    /// @notice Emitted when there is an alert in LayerZero due to an issue with message reception.
    /// @param receiver The address of the receiver.
    /// @param executor The address of the entity executing the message delivery.
    /// @param origin The origin data of the packet, including source chain and sender details.
    /// @param guid A globally unique identifier (GUID) for the message.
    /// @param gas The amount of gas used for processing the message.
    /// @param value The value (in wei) sent with the message.
    /// @param message The payload of the message that was processed.
    /// @param extraData Additional data attached to the message.
    /// @param reason The reason for the alert (e.g., an error message or a gas limit issue).
    event LzReceiveAlert(
        address indexed receiver,
        address indexed executor,
        Origin origin,
        bytes32 guid,
        uint256 gas,
        uint256 value,
        bytes message,
        bytes extraData,
        bytes reason
    );

    /// @notice Emitted when the LayerZero token (LZ) is set.
    /// @param token The address of the LZ token contract.
    event LzTokenSet(address token);

    /// @notice Emitted when a delegate is set for a sender to handle messages on their behalf.
    /// @param sender The address of the sender delegating the message handling.
    /// @param delegate The address of the delegate.
    event DelegateSet(address sender, address delegate);

    /// @notice Provides a quote for the cost (fees) of sending a message with the given parameters.
    /// @param _params The parameters of the message being sent.
    /// @param _sender The address of the sender initiating the message.
    /// @return fee The fees (in native and LZ tokens) required to send the message.
    function quote(
        MessagingParams calldata _params,
        address _sender
    ) external view returns (MessagingFee memory);

    /// @notice Sends a message with the specified parameters and refund address.
    /// @param _params The parameters of the message being sent.
    /// @param _refundAddress The address to which any unused funds will be refunded.
    /// @return receipt The receipt containing details of the message sent, including GUID and fees.
    function send(
        MessagingParams calldata _params,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory);

    /// @notice Verifies the authenticity of a received packet by checking its payload hash.
    /// @param _origin The origin data of the packet, including source chain and sender details.
    /// @param _receiver The address of the receiver on the destination chain.
    /// @param _payloadHash The hash of the payload to verify.
    function verify(
        Origin calldata _origin,
        address _receiver,
        bytes32 _payloadHash
    ) external;

    /// @notice Checks if a message can be verified for a specific origin and receiver.
    /// @param _origin The origin data of the packet, including source chain and sender details.
    /// @param _receiver The address of the receiver on the destination chain.
    /// @return A boolean indicating whether the message is verifiable (`true`) or not (`false`).
    function verifiable(
        Origin calldata _origin,
        address _receiver
    ) external view returns (bool);

    /// @notice Checks if a message can be initialized for a specific origin and receiver.
    /// @param _origin The origin data of the packet, including source chain and sender details.
    /// @param _receiver The address of the receiver on the destination chain.
    /// @return A boolean indicating whether the message is initializable (`true`) or not (`false`).
    function initializable(
        Origin calldata _origin,
        address _receiver
    ) external view returns (bool);

    /// @notice Receives and processes a LayerZero message on the destination chain.
    /// @dev This function handles the execution of the message, using the provided origin, message, and extra data.
    /// @param _origin The origin data of the packet, including source chain and sender details.
    /// @param _receiver The address of the receiver on the destination chain.
    /// @param _guid A globally unique identifier (GUID) for the message.
    /// @param _message The payload of the message being received.
    /// @param _extraData Additional data required for processing the message.
    function lzReceive(
        Origin calldata _origin,
        address _receiver,
        bytes32 _guid,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable;

    /// @notice Allows an OApp (Off-chain Application) to clear a message if verified, with its own business logic.
    /// @param _oapp The address of the OApp responsible for clearing the message.
    /// @param _origin The origin data of the packet, including source chain and sender details.
    /// @param _guid A globally unique identifier (GUID) for the message.
    /// @param _message The payload of the message being cleared.
    function clear(
        address _oapp,
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message
    ) external;

    /// @notice Sets the LayerZero token (LZ) to be used for message payments.
    /// @param _lzToken The address of the LZ token contract.
    function setLzToken(address _lzToken) external;

    /// @notice Retrieves the address of the LayerZero (LZ) token currently set.
    /// @return The address of the LZ token contract.
    function lzToken() external view returns (address);

    /// @notice Retrieves the address of the native token used for payments in the protocol.
    /// @return The address of the native token contract.
    function nativeToken() external view returns (address);

    /// @notice Sets a delegate to act on behalf of the sender for message handling.
    /// @param _delegate The address of the delegate.
    function setDelegate(address _delegate) external;
}
