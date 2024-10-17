// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import {IMessagingContext} from "./interfaces/IMessagingContext.sol";
import {Errors} from "./libs/Errors.sol";

/**
 * @title MessagingContext
 * @dev Abstract contract that serves as a non-reentrancy guard and a source of messaging context.
 *      Provides the ability to capture the remote `eid` and `sender` address during message sends.
 *      Separates the send and receive contexts to allow messaging receipts.
 *      This version follows the upgradeable storage pattern.
 */
abstract contract MessagingContext is IMessagingContext {
    /// @custom:storage-location erc7201:messaging.context.storage
    struct MessagingContextStorage {
        uint256 sendContext;
    }

    /// @dev Constant representing the state where no send operation is ongoing.
    uint256 private constant NOT_ENTERED = 1;

    /// @dev Storage slot where the MessagingContextStorage struct will be stored.
    bytes32 private constant MESSAGING_CONTEXT_STORAGE_SLOT =
        keccak256("messaging.context.storage");

    /**
     * @dev Retrieves the storage struct for MessagingContext.
     * @return storageRef A reference to the MessagingContextStorage struct.
     */
    function _getMessagingContextStorage()
        internal
        pure
        returns (MessagingContextStorage storage storageRef)
    {
        bytes32 slot = MESSAGING_CONTEXT_STORAGE_SLOT;
        assembly {
            storageRef.slot := slot
        }
    }

    /**
     * @dev Modifier that sets the messaging context when a message is being sent.
     *      Ensures that no reentrancy occurs during message sending.
     * @param _dstEid The destination endpoint ID to which the message is being sent.
     * @param _sender The address of the message sender.
     */
    modifier sendContext(uint32 _dstEid, address _sender) {
        MessagingContextStorage storage s = _getMessagingContextStorage();

        if (s.sendContext != NOT_ENTERED) revert Errors.SendReentrancy();

        // Set the send context to the encoded form of the destination endpoint ID and sender address
        s.sendContext = (uint256(_dstEid) << 160) | uint160(_sender);
        _;
        // Reset the send context after the function completes
        s.sendContext = NOT_ENTERED;
    }

    /**
     * @notice Checks whether a message is currently being sent.
     * @dev If `sendContext` is not `NOT_ENTERED`, it indicates a message send operation is ongoing.
     * @return `true` if a message is being sent, `false` otherwise.
     */
    function isSendingMessage() public view returns (bool) {
        MessagingContextStorage storage s = _getMessagingContextStorage();
        return s.sendContext != NOT_ENTERED;
    }

    /**
     * @notice Retrieves the current messaging context during a send operation.
     * @dev Returns the destination endpoint ID and sender address if a message is being sent.
     * @return A tuple containing:
     *      - `uint32`: The destination endpoint ID (`eid`).
     *      - `address`: The sender address.
     *      If no message is being sent, both values return as zero (`0`).
     */
    function getSendContext() external view override returns (uint32, address) {
        MessagingContextStorage storage s = _getMessagingContextStorage();
        return
            isSendingMessage()
                ? _getSendContext(s.sendContext)
                : (0, address(0));
    }

    /**
     * @dev Internal function to decode the send context.
     * @param _context The encoded send context.
     * @return A tuple containing:
     *      - `uint32`: The destination endpoint ID (`eid`).
     *      - `address`: The sender address.
     */
    function _getSendContext(
        uint256 _context
    ) internal pure returns (uint32, address) {
        return (uint32(_context >> 160), address(uint160(_context)));
    }

    /**
     * @dev Initializes the MessagingContext contract (in case of upgradeable patterns).
     */
    function __MessagingContext_init() internal {
        MessagingContextStorage storage s = _getMessagingContextStorage();
        s.sendContext = NOT_ENTERED;
    }
}
