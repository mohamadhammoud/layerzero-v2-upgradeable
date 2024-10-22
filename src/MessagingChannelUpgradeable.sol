// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import {IMessagingChannel} from "./interfaces/IMessagingChannel.sol";
import {Errors} from "./libs/Errors.sol";
import {GUID} from "./libs/GUID.sol";

/**
 * @title MessagingChannelUpgradeable
 * @dev Abstract contract providing base functionality for managing message channels in LayerZero communication.
 *      This contract handles nonces and payload hashes for inbound and outbound messages, while using
 *      upgradeable storage with the ERC-7201 namespaced storage pattern.
 */
abstract contract MessagingChannelUpgradeable is IMessagingChannel {
    /// @notice Represents an empty payload hash.
    bytes32 public constant EMPTY_PAYLOAD_HASH = bytes32(0);

    /// @notice Represents a nil (non-verifiable) payload hash.
    bytes32 public constant NIL_PAYLOAD_HASH = bytes32(type(uint256).max);

    /// @custom:storage-location erc7201:messaging.channel
    struct MessagingChannelStorage {
        uint32 eid; // Endpoint ID
        /// @dev Tracks the next inbound nonce for each (receiver, source EID, sender).
        mapping(address receiver => mapping(uint32 srcEid => mapping(bytes32 sender => uint64 nonce))) lazyInboundNonce;
        /// @dev Maps (receiver, source EID, sender, nonce) to the payload hash for each verified message.
        mapping(address receiver => mapping(uint32 srcEid => mapping(bytes32 sender => mapping(uint64 inboundNonce => bytes32 payloadHash)))) inboundPayloadHash;
        /// @dev Tracks the next outbound nonce for each (sender, destination EID, receiver).
        mapping(address sender => mapping(uint32 dstEid => mapping(bytes32 receiver => uint64 nonce))) outboundNonce;
    }

    /// @dev The constant storage slot where the MessagingChannelStorage struct will be stored.
    bytes32 private constant MESSAGING_CHANNEL_STORAGE_SLOT =
        0xb8c31507b3d44e9418725b8e763175ad1f85f06142c1c2df99a62b4ed817d000;
    // keccak256(abi.encode(uint256(keccak256("MessagingChannelUpgradeable.storage")) - 1)) & ~bytes32(uint256(0xff));

    /**
     * @dev Initializes the MessagingChannel contract.
     * @param _eid The Endpoint ID (EID) of this deployed instance.
     */
    function __MessagingChannel_init(uint32 _eid) internal {
        MessagingChannelStorage storage s = _getMessagingChannelStorage();
        s.eid = _eid;
    }

    /**
     * @dev Retrieves the MessagingChannelStorage using inline assembly.
     * @return storageRef Reference to the MessagingChannelStorage struct.
     */
    function _getMessagingChannelStorage()
        internal
        pure
        returns (MessagingChannelStorage storage storageRef)
    {
        bytes32 slot = MESSAGING_CHANNEL_STORAGE_SLOT;
        assembly {
            storageRef.slot := slot
        }
    }

    /**
     * @dev Increment and return the next outbound nonce for a given sender, destination EID, and receiver.
     * @param _sender The address of the message sender.
     * @param _dstEid The destination endpoint ID.
     * @param _receiver The receiver address.
     * @return nonce The next outbound nonce.
     */
    function _outbound(
        address _sender,
        uint32 _dstEid,
        bytes32 _receiver
    ) internal returns (uint64 nonce) {
        MessagingChannelStorage storage s = _getMessagingChannelStorage();
        unchecked {
            nonce = ++s.outboundNonce[_sender][_dstEid][_receiver];
        }
    }

    /**
     * @dev Lazily update the inbound nonce for a given receiver, source EID, and sender.
     * @param _receiver The address of the message receiver.
     * @param _srcEid The source endpoint ID.
     * @param _sender The address of the message sender.
     * @param _nonce The message nonce.
     * @param _payloadHash The payload hash of the message.
     */
    function _inbound(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce,
        bytes32 _payloadHash
    ) internal {
        if (_payloadHash == EMPTY_PAYLOAD_HASH)
            revert Errors.InvalidPayloadHash();

        MessagingChannelStorage storage s = _getMessagingChannelStorage();
        s.inboundPayloadHash[_receiver][_srcEid][_sender][
            _nonce
        ] = _payloadHash;
    }

    /**
     * @notice Returns the current inbound nonce for a given receiver, source EID, and sender.
     * @param _receiver The address of the message receiver.
     * @param _srcEid The source endpoint ID.
     * @param _sender The address of the message sender.
     * @return The current inbound nonce.
     */
    function inboundNonce(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender
    ) public view returns (uint64) {
        MessagingChannelStorage storage s = _getMessagingChannelStorage();
        uint64 nonceCursor = s.lazyInboundNonce[_receiver][_srcEid][_sender];

        // Find the latest verified nonce
        unchecked {
            while (
                _hasPayloadHash(_receiver, _srcEid, _sender, nonceCursor + 1)
            ) {
                ++nonceCursor;
            }
        }
        return nonceCursor;
    }

    /// @notice Returns the current outbound nonce for a specific sender and destination chain.
    /// @param _sender The address of the OApp (Off-chain Application) sending the message.
    /// @param _dstEid The destination environment ID (chain ID) for the outbound message.
    /// @param _receiver The address (bytes32) of the receiver on the destination chain.
    /// @return The current outbound nonce for the specified sender and destination chain.
    function outboundNonce(
        address _sender,
        uint32 _dstEid,
        bytes32 _receiver
    ) external view returns (uint64) {
        return
            _getMessagingChannelStorage().outboundNonce[_sender][_dstEid][
                _receiver
            ];
    }

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
    ) external view returns (uint64) {
        MessagingChannelStorage storage s = _getMessagingChannelStorage();

        return s.lazyInboundNonce[_receiver][_srcEid][_sender];
    }

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
    ) external view returns (bytes32) {
        MessagingChannelStorage storage s = _getMessagingChannelStorage();

        return s.inboundPayloadHash[_receiver][_srcEid][_sender][_nonce];
    }

    /// @notice Returns the environment ID (chain ID) of the current chain.
    /// @return The environment ID (eid) of the current chain.
    function eid() external view returns (uint32) {
        return _getMessagingChannelStorage().eid;
    }

    /// @dev Marks a packet as verified, but disallows execution until it is re-verified.
    /// @dev Reverts if the provided _payloadHash does not match the currently verified payload hash.
    /// @dev A non-verified nonce can be nilified by passing EMPTY_PAYLOAD_HASH for _payloadHash.
    /// @dev Assumes the computational intractability of finding a payload that hashes to bytes32.max.
    /// @dev Authenticated by the caller
    function nilify(
        address _oapp,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce,
        bytes32 _payloadHash
    ) external {
        _assertAuthorized(_oapp);

        MessagingChannelStorage storage s = _getMessagingChannelStorage();

        bytes32 curPayloadHash = s.inboundPayloadHash[_oapp][_srcEid][_sender][
            _nonce
        ];
        if (curPayloadHash != _payloadHash)
            revert Errors.PayloadHashNotFound(curPayloadHash, _payloadHash);
        if (
            _nonce <= s.lazyInboundNonce[_oapp][_srcEid][_sender] &&
            curPayloadHash == EMPTY_PAYLOAD_HASH
        ) revert Errors.InvalidNonce(_nonce);

        // set it to nil
        s.inboundPayloadHash[_oapp][_srcEid][_sender][
            _nonce
        ] = NIL_PAYLOAD_HASH;
        emit PacketNilified(_srcEid, _sender, _oapp, _nonce, _payloadHash);
    }

    /// @dev Marks a nonce as unexecutable and un-verifiable. The nonce can never be re-verified or executed.
    /// @dev Reverts if the provided _payloadHash does not match the currently verified payload hash.
    /// @dev Only packets with nonces less than or equal to the lazy inbound nonce can be burned.
    /// @dev Reverts if the nonce has already been executed.
    /// @dev Authenticated by the caller
    function burn(
        address _oapp,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce,
        bytes32 _payloadHash
    ) external {
        _assertAuthorized(_oapp);
        MessagingChannelStorage storage s = _getMessagingChannelStorage();

        bytes32 curPayloadHash = s.inboundPayloadHash[_oapp][_srcEid][_sender][
            _nonce
        ];
        if (curPayloadHash != _payloadHash)
            revert Errors.PayloadHashNotFound(curPayloadHash, _payloadHash);
        if (
            curPayloadHash == EMPTY_PAYLOAD_HASH ||
            _nonce > s.lazyInboundNonce[_oapp][_srcEid][_sender]
        ) revert Errors.InvalidNonce(_nonce);

        delete s.inboundPayloadHash[_oapp][_srcEid][_sender][_nonce];

        emit PacketBurnt(_srcEid, _sender, _oapp, _nonce, _payloadHash);
    }

    /**
     * @dev Check whether the payload hash for a given message has been initialized.
     * @param _receiver The address of the message receiver.
     * @param _srcEid The source endpoint ID.
     * @param _sender The address of the message sender.
     * @param _nonce The message nonce.
     * @return True if the payload hash has been initialized, false otherwise.
     */
    function _hasPayloadHash(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce
    ) internal view returns (bool) {
        MessagingChannelStorage storage s = _getMessagingChannelStorage();
        return
            s.inboundPayloadHash[_receiver][_srcEid][_sender][_nonce] !=
            EMPTY_PAYLOAD_HASH;
    }

    /**
     * @notice Skip a specific message nonce to prevent its verification.
     * @param _oapp The address of the application (OApp).
     * @param _srcEid The source endpoint ID.
     * @param _sender The address of the message sender.
     * @param _nonce The message nonce.
     */
    function skip(
        address _oapp,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce
    ) external {
        _assertAuthorized(_oapp);

        MessagingChannelStorage storage s = _getMessagingChannelStorage();
        if (_nonce != inboundNonce(_oapp, _srcEid, _sender) + 1)
            revert Errors.InvalidNonce(_nonce);

        s.lazyInboundNonce[_oapp][_srcEid][_sender] = _nonce;
        emit InboundNonceSkipped(_srcEid, _sender, _oapp, _nonce);
    }

    /**
     * @notice Clears a payload for the given message and updates the lazy inbound nonce.
     * @param _receiver The address of the message receiver.
     * @param _srcEid The source endpoint ID.
     * @param _sender The address of the message sender.
     * @param _nonce The message nonce.
     * @param _payload The payload data to clear.
     * @return actualHash The calculated hash of the cleared payload.
     */
    function _clearPayload(
        address _receiver,
        uint32 _srcEid,
        bytes32 _sender,
        uint64 _nonce,
        bytes memory _payload
    ) internal returns (bytes32 actualHash) {
        MessagingChannelStorage storage s = _getMessagingChannelStorage();

        uint64 currentNonce = s.lazyInboundNonce[_receiver][_srcEid][_sender];
        if (_nonce > currentNonce) {
            unchecked {
                for (uint64 i = currentNonce + 1; i <= _nonce; ++i) {
                    if (!_hasPayloadHash(_receiver, _srcEid, _sender, i))
                        revert Errors.InvalidNonce(i);
                }
                s.lazyInboundNonce[_receiver][_srcEid][_sender] = _nonce;
            }
        }

        actualHash = keccak256(_payload);
        bytes32 expectedHash = s.inboundPayloadHash[_receiver][_srcEid][
            _sender
        ][_nonce];
        if (expectedHash != actualHash)
            revert Errors.PayloadHashNotFound(expectedHash, actualHash);

        delete s.inboundPayloadHash[_receiver][_srcEid][_sender][_nonce];
    }

    /**
     * @notice Returns the GUID for the next message given a sender, destination EID, and receiver.
     * @param _sender The address of the message sender.
     * @param _dstEid The destination endpoint ID.
     * @param _receiver The address of the message receiver.
     * @return The next GUID.
     */
    function nextGuid(
        address _sender,
        uint32 _dstEid,
        bytes32 _receiver
    ) external view returns (bytes32) {
        MessagingChannelStorage storage s = _getMessagingChannelStorage();
        uint64 nextNonce = s.outboundNonce[_sender][_dstEid][_receiver] + 1;
        return GUID.generate(nextNonce, s.eid, _sender, _dstEid, _receiver);
    }

    /// @dev Placeholder for authorization logic to ensure only authorized addresses can perform actions.
    function _assertAuthorized(address _oapp) internal virtual;
}
