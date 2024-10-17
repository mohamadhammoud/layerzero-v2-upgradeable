// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import {AddressCast} from "./AddressCast.sol";

/**
 * @title GUID
 * @dev Utility library for generating globally unique identifiers (GUID) based on message parameters.
 */
library GUID {
    using AddressCast for address;

    /**
     * @notice Generates a globally unique identifier (GUID) for a given set of parameters.
     * @dev The GUID is generated using a combination of nonce, source endpoint ID (srcEid), sender address,
     *      destination endpoint ID (dstEid), and receiver address (as bytes32).
     * @param _nonce The message nonce.
     * @param _srcEid The source endpoint ID (unique identifier for the originating endpoint).
     * @param _sender The address of the sender initiating the message.
     * @param _dstEid The destination endpoint ID (unique identifier for the receiving endpoint).
     * @param _receiver The receiver's address (in bytes32 format).
     * @return A unique 32-byte GUID.
     */
    function generate(
        uint64 _nonce,
        uint32 _srcEid,
        address _sender,
        uint32 _dstEid,
        bytes32 _receiver
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _nonce,
                    _srcEid,
                    _sender.toBytes32(),
                    _dstEid,
                    _receiver
                )
            );
    }
}
