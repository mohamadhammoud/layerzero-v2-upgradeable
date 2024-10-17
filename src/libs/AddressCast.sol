// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import {Errors} from "./Errors.sol";

/**
 * @title AddressCast
 * @dev Utility library for converting between different address representations, including address, bytes, and bytes32.
 */
library AddressCast {
    /**
     * @notice Converts a dynamic `bytes` type into a `bytes32` representation.
     * @dev This function only works with addresses up to 32 bytes long.
     *      If the input length exceeds 32 bytes, it reverts.
     * @param _addressBytes The input bytes to be converted.
     * @return result A `bytes32` value derived from the input bytes.
     */
    function toBytes32(
        bytes calldata _addressBytes
    ) internal pure returns (bytes32 result) {
        if (_addressBytes.length > 32) revert Errors.InvalidAddress();
        result = bytes32(_addressBytes);
        unchecked {
            uint256 offset = 32 - _addressBytes.length;
            result = result >> (offset * 8);
        }
    }

    /**
     * @notice Converts an Ethereum address to a `bytes32` representation.
     * @param _address The input address to be converted.
     * @return result A `bytes32` value derived from the input address.
     */
    function toBytes32(
        address _address
    ) internal pure returns (bytes32 result) {
        result = bytes32(uint256(uint160(_address)));
    }

    /**
     * @notice Converts a `bytes32` back into a dynamic `bytes` array with a specified size.
     * @dev If the size is invalid (either 0 or greater than 32), the function reverts.
     * @param _addressBytes32 The `bytes32` value to be converted into `bytes`.
     * @param _size The desired byte size of the resulting array.
     * @return result The `bytes` representation of the `bytes32` input.
     */
    function toBytes(
        bytes32 _addressBytes32,
        uint256 _size
    ) internal pure returns (bytes memory result) {
        if (_size == 0 || _size > 32) revert Errors.InvalidSizeForAddress();
        result = new bytes(_size);
        unchecked {
            uint256 offset = 256 - _size * 8;
            assembly {
                mstore(add(result, 32), shl(offset, _addressBytes32))
            }
        }
    }

    /**
     * @notice Converts a `bytes32` value back into an Ethereum address.
     * @param _addressBytes32 The `bytes32` value to be converted.
     * @return result The resulting Ethereum address.
     */
    function toAddress(
        bytes32 _addressBytes32
    ) internal pure returns (address result) {
        result = address(uint160(uint256(_addressBytes32)));
    }

    /**
     * @notice Converts a dynamic `bytes` array back into an Ethereum address.
     * @dev If the input length is not 20 bytes (the size of an Ethereum address), the function reverts.
     * @param _addressBytes The `bytes` array to be converted.
     * @return result The resulting Ethereum address.
     */
    function toAddress(
        bytes calldata _addressBytes
    ) internal pure returns (address result) {
        if (_addressBytes.length != 20) revert Errors.InvalidAddress();
        result = address(bytes20(_addressBytes));
    }
}
