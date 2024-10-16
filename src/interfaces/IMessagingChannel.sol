// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/// @title IMessagingChannel Interface for LayerZero Messaging Channel
/// @notice This interface manages message verification, tracking nonces, and emergency actions like skipping, nilifying, or burning messages.
/// @dev This interface supports handling inbound and outbound messaging packets and includes emergency functions for message recovery.
interface IMessagingChannel {
    /// @notice Emitted when an inbound nonce is skipped due to issues with message verification.
    /// @param srcEid The source environment ID (chain ID) from which the message originated.
    /// @param sender The address (bytes32) of the sender from the source chain.
    /// @param receiver The address of the receiver on the destination chain.
    /// @param nonce The skipped inbound message nonce.
    event InboundNonceSkipped(
        uint32 srcEid,
        bytes32 sender,
        address receiver,
        uint64 nonce
    );

    /// @notice Emitted when a packet is nilified (i.e., invalidated) on the destination chain.
    /// @param srcEid The source environment ID (chain ID) from which the message originated.
    /// @param sender The address (bytes32) of the sender from the source chain.
    /// @param receiver The address of the receiver on the destination chain.
    /// @param nonce The nonce of the packet that was nilified.
    /// @param payloadHash The hash of the packet's payload that was nilified.
    event PacketNilified(
        uint32 srcEid,
        bytes32 sender,
        address receiver,
        uint64 nonce,
        bytes32 payloadHash
    );

    /// @notice Emitted when a packet is burnt (i.e., deleted) on the destination chain.
    /// @param srcEid The source environment ID (chain ID) from which the message originated.
    /// @param sender The address (bytes32) of the sender from the source chain.
    /// @param receiver The address of the receiver on the destination chain.
    /// @param nonce The nonce of the packet that was burnt.
    /// @param payloadHash The hash of the packet's payload that was burnt.
    event PacketBurnt(
        uint32 srcEid,
        bytes32 sender,
        address receiver,
        uint64 nonce,
        bytes32 payloadHash
    );

    /// @notice Returns the environment ID (chain ID) of the current chain.
    /// @return The environment ID (eid) of the current chain.
    function eid() external view returns (uint32);

    /// @notice Skips an inbound nonce if the message cannot be verified or processed.
    /// @dev This is an emergency function to avoid race conditions by providing the next nonce.
    /// @param _oapp The address of the OApp (Off-chain Application) managing the message.
    /// @param _srcEid The environment ID (chain ID) from which the message originated.
    /// @param _sender The address (bytes32) of the sender on the source chain.
    /// @param _nonce The nonce of the message that is being skipped.
    function skip(
        address _oapp,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce
    ) external;

    /// @notice Nilifies (invalidates) an inbound packet on the destination chain.
    /// @dev Used to discard packets that are no longer valid, typically when verification fails.
    /// @param _oapp The address of the OApp (Off-chain Application) managing the message.
    /// @param _srcEid The environment ID (chain ID) from which the message originated.
    /// @param _sender The address (bytes32) of the sender on the source chain.
    /// @param _nonce The nonce of the packet that is being nilified.
    /// @param _payloadHash The hash of the payload of the packet being nilified.
    function nilify(
        address _oapp,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce,
        bytes32 _payloadHash
    ) external;

    /// @notice Burns (deletes) an inbound packet on the destination chain.
    /// @dev Used to completely remove packets, typically for security or emergency purposes.
    /// @param _oapp The address of the OApp (Off-chain Application) managing the message.
    /// @param _srcEid The environment ID (chain ID) from which the message originated.
    /// @param _sender The address (bytes32) of the sender on the source chain.
    /// @param _nonce The nonce of the packet that is being burnt.
    /// @param _payloadHash The hash of the payload of the packet being burnt.
    function burn(
        address _oapp,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce,
        bytes32 _payloadHash
    ) external;

    /// @notice Generates and returns the next unique identifier (GUID) for an outbound message.
    /// @param _sender The address of the OApp (Off-chain Application) that is sending the message.
    /// @param _dstEid The destination environment ID (chain ID) for the outbound message.
    /// @param _receiver The address (bytes32) of the receiver on the destination chain.
    /// @return The next globally unique identifier (GUID) for the outbound message.
    function nextGuid(
        address _sender,
        uint32 _dstEid,
        bytes32 _receiver
    ) external view returns (bytes32);

    /// @notice Returns the current inbound nonce for a specific receiver and source chain.
    /// @param _receiver The address of the OApp (Off-chain Application) receiving the message.
    /// @param _srcEid The source environment ID (chain ID) from which the message originated.
    /// @param _sender The address (bytes32) of the sender on the source chain.
    /// @return The current inbound nonce for the specified receiver and source chain.
    function inboundNonce(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender
    ) external view returns (uint64);

    /// @notice Returns the current outbound nonce for a specific sender and destination chain.
    /// @param _sender The address of the OApp (Off-chain Application) sending the message.
    /// @param _dstEid The destination environment ID (chain ID) for the outbound message.
    /// @param _receiver The address (bytes32) of the receiver on the destination chain.
    /// @return The current outbound nonce for the specified sender and destination chain.
    function outboundNonce(
        address _sender,
        uint32 _dstEid,
        bytes32 _receiver
    ) external view returns (uint64);

    /// @notice Returns the payload hash of a specific inbound message.
    /// @param _receiver The address of the OApp (Off-chain Application) receiving the message.
    /// @param _srcEid The source environment ID (chain ID) from which the message originated.
    /// @param _sender The address (bytes32) of the sender on the source chain.
    /// @param _nonce The nonce of the inbound message.
    /// @return The hash of the payload of the specified inbound message.
    function inboundPayloadHash(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce
    ) external view returns (bytes32);

    /// @notice Returns the next inbound nonce for lazy processing of a message.
    /// @dev Lazy processing means the message may not be processed immediately.
    /// @param _receiver The address of the OApp (Off-chain Application) receiving the message.
    /// @param _srcEid The source environment ID (chain ID) from which the message originated.
    /// @param _sender The address (bytes32) of the sender on the source chain.
    /// @return The next inbound nonce for the specified receiver, source chain, and sender.
    function lazyInboundNonce(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender
    ) external view returns (uint64);
}
