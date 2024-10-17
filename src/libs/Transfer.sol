// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Transfer
 * @dev Utility library for handling native and ERC20 token transfers with built-in error handling.
 *      Includes functions for transferring native tokens, ERC20 tokens, and selecting between the two based on token address.
 */
library Transfer {
    using SafeERC20 for IERC20;

    /// @dev Constant representing the zero address.
    address internal constant ADDRESS_ZERO = address(0);

    /**
     * @notice Error triggered when a native token transfer fails.
     * @param _to The address that was intended to receive the transfer.
     * @param _value The amount of native tokens that were being transferred.
     */
    error TransferNativeFailed(address _to, uint256 _value);

    /**
     * @notice Error triggered when attempting to transfer tokens to the zero address.
     */
    error ToAddressIsZero();

    /**
     * @notice Transfers native currency (e.g., Ether) to the specified address.
     * @dev Reverts if the recipient address is the zero address or if the transfer fails.
     * @param _to The address to which the native currency is being transferred.
     * @param _value The amount of native currency to transfer.
     */
    function native(address _to, uint256 _value) internal {
        if (_to == ADDRESS_ZERO) revert ToAddressIsZero();
        (bool success, ) = _to.call{value: _value}("");
        if (!success) revert TransferNativeFailed(_to, _value);
    }

    /**
     * @notice Transfers ERC20 tokens to the specified address.
     * @dev Reverts if the recipient address is the zero address.
     * @param _token The ERC20 token address to transfer from.
     * @param _to The address to which the ERC20 tokens are being transferred.
     * @param _value The amount of ERC20 tokens to transfer.
     */
    function token(address _token, address _to, uint256 _value) internal {
        if (_to == ADDRESS_ZERO) revert ToAddressIsZero();
        IERC20(_token).safeTransfer(_to, _value);
    }

    /**
     * @notice Transfers either native currency or ERC20 tokens depending on whether the token address is zero.
     * @dev If `_token` is the zero address, it performs a native transfer, otherwise it performs an ERC20 transfer.
     * @param _token The token address to transfer from (if zero, it will transfer native currency).
     * @param _to The address to which the tokens/native currency are being transferred.
     * @param _value The amount of tokens/native currency to transfer.
     */
    function nativeOrToken(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        if (_token == ADDRESS_ZERO) {
            native(_to, _value);
        } else {
            token(_token, _to, _value);
        }
    }
}
