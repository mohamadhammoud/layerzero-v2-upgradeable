// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import {IMessagingComposer} from "./interfaces/IMessagingComposer.sol";
import {ILayerZeroComposer} from "./interfaces/ILayerZeroComposer.sol";
import {Errors} from "./libs/Errors.sol";

/**
 * @title MessagingComposer
 * @dev Abstract contract implementing composition of LayerZero messages.
 *      Uses upgradeable storage for future-proofing and includes message
 *      composition, verification, and delivery functionality.
 */
abstract contract MessagingComposer is IMessagingComposer {
    /// @dev Represents a message that has not yet been composed.
    bytes32 private constant NO_MESSAGE_HASH = bytes32(0);

    /// @dev Represents a message that has already been received.
    bytes32 private constant RECEIVED_MESSAGE_HASH = bytes32(uint256(1));

    /// @custom:storage-location erc7201:messaging.composer
    struct MessagingComposerStorage {
        /// @dev Mapping that tracks the message hashes for composed messages.
        mapping(address from => mapping(address to => mapping(bytes32 guid => mapping(uint16 index => bytes32 messageHash)))) composeQueue;
    }

    /// @dev The constant storage slot where the MessagingComposerStorage struct will be stored.
    bytes32 private constant MESSAGING_COMPOSER_STORAGE_SLOT =
        keccak256("messaging.composer.storage");

    /**
     * @dev Retrieves the MessagingComposerStorage using inline assembly.
     * @return storageRef Reference to the MessagingComposerStorage struct.
     */
    function _getMessagingComposerStorage()
        internal
        pure
        returns (MessagingComposerStorage storage storageRef)
    {
        bytes32 slot = MESSAGING_COMPOSER_STORAGE_SLOT;
        assembly {
            storageRef.slot := slot
        }
    }

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
    ) external view returns (bytes32 messageHash) {
        MessagingComposerStorage storage s = _getMessagingComposerStorage();

        return s.composeQueue[_from][_to][_guid][_index];
    }

    /**
     * @notice Sends a composed message from the sender to the receiver.
     * @dev The sender must assert the sender address since anyone can send a compose message.
     * @param _to The address which will receive the composed message.
     * @param _guid The unique message GUID.
     * @param _index The index of the message within the composition sequence.
     * @param _message The actual message payload.
     */
    function sendCompose(
        address _to,
        bytes32 _guid,
        uint16 _index,
        bytes calldata _message
    ) external override {
        MessagingComposerStorage storage s = _getMessagingComposerStorage();

        // Ensure the message hasn't been sent before
        if (s.composeQueue[msg.sender][_to][_guid][_index] != NO_MESSAGE_HASH) {
            revert Errors.ComposeExists();
        }

        // Store the hash of the composed message
        s.composeQueue[msg.sender][_to][_guid][_index] = keccak256(_message);

        emit ComposeSent(msg.sender, _to, _guid, _index, _message);
    }

    /**
     * @notice Executes a composed message from the sender to the receiver.
     * @dev The receiver must assert the message's validity before executing.
     *      Marks the message as received and prevents reentrancy.
     * @param _from The address which sends the composed message.
     * @param _to The address which receives the composed message.
     * @param _guid The unique message GUID.
     * @param _index The index of the message within the composition sequence.
     * @param _message The actual message payload.
     * @param _extraData Additional untrusted execution context.
     */
    function lzCompose(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable override {
        MessagingComposerStorage storage s = _getMessagingComposerStorage();

        // Ensure the message hash matches the stored hash
        bytes32 expectedHash = s.composeQueue[_from][_to][_guid][_index];
        bytes32 actualHash = keccak256(_message);
        if (expectedHash != actualHash) {
            revert Errors.ComposeNotFound(expectedHash, actualHash);
        }

        // Mark the message as received to prevent reentrancy
        s.composeQueue[_from][_to][_guid][_index] = RECEIVED_MESSAGE_HASH;

        // Execute the composed message in the receiver's contract
        ILayerZeroComposer(_to).lzCompose{value: msg.value}(
            _from,
            _guid,
            _message,
            msg.sender,
            _extraData
        );

        emit ComposeDelivered(_from, _to, _guid, _index);
    }

    /**
     * @notice Sends an alert if the composed message is not delivered successfully.
     * @param _from The address which sends the composed message.
     * @param _to The address which receives the composed message.
     * @param _guid The unique message GUID.
     * @param _index The index of the message within the composition sequence.
     * @param _gas The gas used during execution.
     * @param _value The amount of native currency sent with the message.
     * @param _message The actual message payload.
     * @param _extraData Additional untrusted execution context.
     * @param _reason The reason why the message delivery failed.
     */
    function lzComposeAlert(
        address _from,
        address _to,
        bytes32 _guid,
        uint16 _index,
        uint256 _gas,
        uint256 _value,
        bytes calldata _message,
        bytes calldata _extraData,
        bytes calldata _reason
    ) external {
        emit LzComposeAlert(
            _from,
            _to,
            msg.sender,
            _guid,
            _index,
            _gas,
            _value,
            _message,
            _extraData,
            _reason
        );
    }
}
