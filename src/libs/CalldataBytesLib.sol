// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

/**
 * @title CalldataBytesLib
 * @dev Library for converting slices of `bytes` calldata into various types like uint8, uint16, uint32, etc.
 *      Primarily useful when dealing with low-level byte manipulation in calldata.
 */
library CalldataBytesLib {
    /**
     * @notice Extracts a uint8 value from a slice of `bytes` calldata starting at the provided index.
     * @param _bytes The `bytes` calldata to extract the value from.
     * @param _start The starting index in the `bytes` array.
     * @return The uint8 value extracted from `_bytes`.
     */
    function toU8(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (uint8) {
        return uint8(_bytes[_start]);
    }

    /**
     * @notice Extracts a uint16 value from a slice of `bytes` calldata starting at the provided index.
     * @param _bytes The `bytes` calldata to extract the value from.
     * @param _start The starting index in the `bytes` array.
     * @return The uint16 value extracted from `_bytes`.
     */
    function toU16(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (uint16) {
        unchecked {
            uint256 end = _start + 2;
            return uint16(bytes2(_bytes[_start:end]));
        }
    }

    /**
     * @notice Extracts a uint32 value from a slice of `bytes` calldata starting at the provided index.
     * @param _bytes The `bytes` calldata to extract the value from.
     * @param _start The starting index in the `bytes` array.
     * @return The uint32 value extracted from `_bytes`.
     */
    function toU32(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (uint32) {
        unchecked {
            uint256 end = _start + 4;
            return uint32(bytes4(_bytes[_start:end]));
        }
    }

    /**
     * @notice Extracts a uint64 value from a slice of `bytes` calldata starting at the provided index.
     * @param _bytes The `bytes` calldata to extract the value from.
     * @param _start The starting index in the `bytes` array.
     * @return The uint64 value extracted from `_bytes`.
     */
    function toU64(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (uint64) {
        unchecked {
            uint256 end = _start + 8;
            return uint64(bytes8(_bytes[_start:end]));
        }
    }

    /**
     * @notice Extracts a uint128 value from a slice of `bytes` calldata starting at the provided index.
     * @param _bytes The `bytes` calldata to extract the value from.
     * @param _start The starting index in the `bytes` array.
     * @return The uint128 value extracted from `_bytes`.
     */
    function toU128(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (uint128) {
        unchecked {
            uint256 end = _start + 16;
            return uint128(bytes16(_bytes[_start:end]));
        }
    }

    /**
     * @notice Extracts a uint256 value from a slice of `bytes` calldata starting at the provided index.
     * @param _bytes The `bytes` calldata to extract the value from.
     * @param _start The starting index in the `bytes` array.
     * @return The uint256 value extracted from `_bytes`.
     */
    function toU256(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (uint256) {
        unchecked {
            uint256 end = _start + 32;
            return uint256(bytes32(_bytes[_start:end]));
        }
    }

    /**
     * @notice Extracts an address from a slice of `bytes` calldata starting at the provided index.
     * @dev Addresses are represented by 20 bytes in Ethereum.
     * @param _bytes The `bytes` calldata to extract the address from.
     * @param _start The starting index in the `bytes` array.
     * @return The address extracted from `_bytes`.
     */
    function toAddr(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (address) {
        unchecked {
            uint256 end = _start + 20;
            return address(bytes20(_bytes[_start:end]));
        }
    }

    /**
     * @notice Extracts a bytes32 value from a slice of `bytes` calldata starting at the provided index.
     * @param _bytes The `bytes` calldata to extract the bytes32 from.
     * @param _start The starting index in the `bytes` array.
     * @return The bytes32 value extracted from `_bytes`.
     */
    function toB32(
        bytes calldata _bytes,
        uint256 _start
    ) internal pure returns (bytes32) {
        unchecked {
            uint256 end = _start + 32;
            return bytes32(_bytes[_start:end]);
        }
    }
}
