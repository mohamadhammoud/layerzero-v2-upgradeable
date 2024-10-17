// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {MessagingFee} from "./ILayerZeroEndpointV2.sol";
import {IMessageLib} from "./IMessageLib.sol";

/**
 * @dev Packet structure used for sending messages via LayerZero.
 * @param nonce The message nonce to ensure unique transmission.
 * @param srcEid The source endpoint ID (chain ID).
 * @param sender The address of the message sender on the source chain.
 * @param dstEid The destination endpoint ID (chain ID).
 * @param receiver The address of the message receiver on the destination chain.
 * @param guid The globally unique identifier for the message.
 * @param message The actual message payload to be sent.
 */
struct Packet {
    uint64 nonce; // Unique message nonce
    uint32 srcEid; // Source endpoint ID (chain ID)
    address sender; // Address of the sender
    uint32 dstEid; // Destination endpoint ID (chain ID)
    bytes32 receiver; // Address of the receiver on the destination chain
    bytes32 guid; // Globally unique identifier (GUID) for the message
    bytes message; // The message payload
}

/**
 * @title ISendLib
 * @dev Interface for the Send Library in LayerZero's messaging system.
 *      It defines the functions for sending messages, quoting fees, and managing the treasury.
 */
interface ISendLib is IMessageLib {
    /**
     * @notice Sends a message across chains via LayerZero.
     * @param _packet The packet containing the message details (nonce, source and destination IDs, sender, receiver, etc.).
     * @param _options Additional options for the message transfer, such as gas limit, priority, etc.
     * @param _payInLzToken Flag indicating whether the fee will be paid in LayerZero tokens.
     * @return MessagingFee The calculated fee for the message, including native token and LayerZero token fees.
     * @return encodedPacket The encoded packet that contains the message data for LayerZero transmission.
     */
    function send(
        Packet calldata _packet,
        bytes calldata _options,
        bool _payInLzToken
    ) external returns (MessagingFee memory, bytes memory encodedPacket);

    /**
     * @notice Provides a quote for the messaging fee based on the packet details and options.
     * @param _packet The packet containing the message details (nonce, source and destination IDs, sender, receiver, etc.).
     * @param _options Additional options for the message transfer, such as gas limit, priority, etc.
     * @param _payInLzToken Flag indicating whether the fee will be paid in LayerZero tokens.
     * @return MessagingFee The calculated fee for the message, including native token and LayerZero token fees.
     */
    function quote(
        Packet calldata _packet,
        bytes calldata _options,
        bool _payInLzToken
    ) external view returns (MessagingFee memory);

    /**
     * @notice Sets the treasury address where the fees will be collected.
     * @dev This function is restricted to the owner or admin of the SendLib.
     * @param _treasury The address of the treasury.
     */
    function setTreasury(address _treasury) external;

    /**
     * @notice Withdraws collected fees in native tokens.
     * @param _to The address to withdraw the funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawFee(address _to, uint256 _amount) external;

    /**
     * @notice Withdraws collected LayerZero token fees.
     * @param _lzToken The address of the LayerZero token.
     * @param _to The address to withdraw the funds to.
     * @param _amount The amount to withdraw.
     */
    function withdrawLzTokenFee(
        address _lzToken,
        address _to,
        uint256 _amount
    ) external;
}
