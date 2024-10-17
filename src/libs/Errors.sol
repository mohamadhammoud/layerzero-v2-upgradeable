// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

/**
 * @title Errors
 * @dev Library containing custom error definitions used throughout the LayerZero protocol.
 *      These errors help improve gas efficiency and provide meaningful error messages.
 */
library Errors {
    /// @notice Error indicating that the LayerZero token is unavailable.
    error LzTokenUnavailable();

    /// @notice Error indicating that only an alternative token is allowed in the current context.
    error OnlyAltToken();

    /// @notice Error indicating that the provided receive library is invalid.
    error InvalidReceiveLibrary();

    /// @notice Error indicating that the nonce provided is invalid.
    /// @param nonce The invalid nonce.
    error InvalidNonce(uint64 nonce);

    /// @notice Error indicating that an invalid argument was provided.
    error InvalidArgument();

    /// @notice Error indicating that an invalid expiry value was provided.
    error InvalidExpiry();

    /// @notice Error indicating that the amount provided does not match the required amount.
    /// @param required The required amount.
    /// @param supplied The amount that was supplied.
    error InvalidAmount(uint256 required, uint256 supplied);

    /// @notice Error indicating that only registered or default libraries are allowed.
    error OnlyRegisteredOrDefaultLib();

    /// @notice Error indicating that only registered libraries are allowed.
    error OnlyRegisteredLib();

    /// @notice Error indicating that only non-default libraries are allowed in the current context.
    error OnlyNonDefaultLib();

    /// @notice Error indicating that the caller is not authorized to perform this action.
    error Unauthorized();

    /// @notice Error indicating that the default send library is unavailable.
    error DefaultSendLibUnavailable();

    /// @notice Error indicating that the default receive library is unavailable.
    error DefaultReceiveLibUnavailable();

    /// @notice Error indicating that the communication path cannot be initialized due to its state.
    error PathNotInitializable();

    /// @notice Error indicating that the communication path cannot be verified due to its state.
    error PathNotVerifiable();

    /// @notice Error indicating that only send libraries are allowed in the current context.
    error OnlySendLib();

    /// @notice Error indicating that only receive libraries are allowed in the current context.
    error OnlyReceiveLib();

    /// @notice Error indicating that the provided endpoint ID (EID) is unsupported.
    error UnsupportedEid();

    /// @notice Error indicating that the provided interface is unsupported.
    error UnsupportedInterface();

    /// @notice Error indicating that the library has already been registered.
    error AlreadyRegistered();

    /// @notice Error indicating that the value provided is the same as the current value.
    error SameValue();

    /// @notice Error indicating that the payload hash provided is invalid.
    error InvalidPayloadHash();

    /// @notice Error indicating that the expected payload hash does not match the actual payload hash.
    /// @param expected The expected hash value.
    /// @param actual The actual hash value.
    error PayloadHashNotFound(bytes32 expected, bytes32 actual);

    /// @notice Error indicating that a compose action could not be found.
    /// @param expected The expected compose hash.
    /// @param actual The actual compose hash.
    error ComposeNotFound(bytes32 expected, bytes32 actual);

    /// @notice Error indicating that a compose action already exists.
    error ComposeExists();

    /// @notice Error indicating that a reentrant call to the send function occurred.
    error SendReentrancy();

    /// @notice Error indicating that a function is not implemented yet.
    error NotImplemented();

    /// @notice Error indicating that the provided address is invalid.
    error InvalidAddress();

    /// @notice Error indicating that the provided address size is invalid.
    error InvalidSizeForAddress();

    /// @notice Error indicating that the fee provided is insufficient for the operation.
    /// @param requiredNative The required amount of native tokens.
    /// @param suppliedNative The amount of native tokens supplied.
    /// @param requiredLzToken The required amount of LayerZero tokens.
    /// @param suppliedLzToken The amount of LayerZero tokens supplied.
    error InsufficientFee(
        uint256 requiredNative,
        uint256 suppliedNative,
        uint256 requiredLzToken,
        uint256 suppliedLzToken
    );

    /// @notice Error indicating that no LayerZero token fee was provided.
    error ZeroLzTokenFee();

    /// @notice Error indicating that the provided packet is invalid.
    error InvalidPacket();

    /// @notice Error indicating that the native token transfer failed.
    /// @param to The address to which the native token transfer was attempted.
    /// @param value The value of the native token transfer.
    error TransferNativeFailed(address to, uint256 value);

    /// @notice Error indicating that the token transfer failed.
    /// @param token The address of the ERC20 token.
    /// @param to The address to which the token transfer was attempted.
    /// @param value The value of the token transfer.
    error TransferFailed(address token, address to, uint256 value);
}
