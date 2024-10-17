// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {SetConfigParam} from "./IMessageLibManager.sol";

/**
 * @dev Enum representing the type of message library.
 * - Send: Capable of only sending messages.
 * - Receive: Capable of only receiving messages.
 * - SendAndReceive: Capable of both sending and receiving messages.
 */
enum MessageLibType {
    Send,
    Receive,
    SendAndReceive
}

/**
 * @title IMessageLib
 * @dev Interface for LayerZero message libraries. Defines the functions related to message configurations,
 *      versioning, supported endpoints, and message library types (send, receive, or both).
 */
interface IMessageLib is IERC165 {
    /**
     * @notice Sets configuration parameters for the messaging library.
     * @param _oapp The address of the Omnichain Application (OApp) using the messaging library.
     * @param _config An array of configuration parameters to be applied to the OApp.
     */
    function setConfig(
        address _oapp,
        SetConfigParam[] calldata _config
    ) external;

    /**
     * @notice Retrieves the current configuration for the given OApp and configuration type.
     * @param _eid The endpoint ID for which the configuration applies.
     * @param _oapp The address of the OApp whose configuration is being queried.
     * @param _configType The type of configuration being requested (e.g., gas limits, timeouts).
     * @return config The configuration data as a bytes array.
     */
    function getConfig(
        uint32 _eid,
        address _oapp,
        uint32 _configType
    ) external view returns (bytes memory config);

    /**
     * @notice Checks whether the specified endpoint ID is supported by this message library.
     * @param _eid The endpoint ID to check for support.
     * @return bool True if the endpoint is supported, false otherwise.
     */
    function isSupportedEid(uint32 _eid) external view returns (bool);

    /**
     * @notice Retrieves the version of the messaging library.
     * @return major The major version of the message library.
     * @return minor The minor version of the message library.
     * @return endpointVersion The version of the LayerZero endpoint this message library is compatible with.
     */
    function version()
        external
        view
        returns (uint64 major, uint8 minor, uint8 endpointVersion);

    /**
     * @notice Retrieves the type of the message library (Send, Receive, or SendAndReceive).
     * @return MessageLibType The type of message library indicating its capabilities (sending, receiving, or both).
     */
    function messageLibType() external view returns (MessageLibType);
}
