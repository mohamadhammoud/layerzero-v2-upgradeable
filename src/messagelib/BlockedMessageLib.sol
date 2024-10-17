// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IMessageLib, MessageLibType} from "../interfaces/IMessageLib.sol";
import {Errors} from "../libs/Errors.sol";

/**
 * @title BlockedMessageLib
 * @dev A special-purpose message library that blocks all message processing by reverting.
 *      Implements both send and receive operations and is intended to be used when message processing
 *      should be disabled. It conforms to the IMessageLib interface.
 */
contract BlockedMessageLib is ERC165 {
    /**
     * @dev Implements ERC165's `supportsInterface` function to declare support for the IMessageLib interface.
     * @param interfaceId The interface identifier, as specified in ERC165.
     * @return True if the contract implements the interface with `interfaceId`.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {
        return
            interfaceId == type(IMessageLib).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Returns the version of the BlockedMessageLib.
     * @dev Always returns the maximum possible values for version components (uint64 max and uint8 max).
     * @return major The major version number.
     * @return minor The minor version number.
     * @return endpointVersion The version number of the LayerZero endpoint supported.
     */
    function version()
        external
        pure
        returns (uint64 major, uint8 minor, uint8 endpointVersion)
    {
        return (type(uint64).max, type(uint8).max, 2); // Version set to the max possible values.
    }

    /**
     * @notice Specifies the type of the message library.
     * @dev This library handles both sending and receiving operations.
     * @return The type of message library (SendAndReceive).
     */
    function messageLibType() external pure returns (MessageLibType) {
        return MessageLibType.SendAndReceive;
    }

    /**
     * @notice Indicates if a given endpoint ID (eid) is supported.
     * @dev Always returns true, as this library does not process any message and thus supports all eids.
     * @param eid The endpoint ID.
     * @return True indicating support for all eids.
     */
    function isSupportedEid(uint32 eid) external pure returns (bool) {
        return true;
    }

    /**
     * @dev A fallback function to handle any unexpected calls to the contract.
     *      This function will always revert with the `NotImplemented` error.
     */
    fallback() external {
        revert Errors.NotImplemented();
    }
}
