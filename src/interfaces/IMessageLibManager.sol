// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/// @title IMessageLibManager Interface for LayerZero V2
/// @notice This contract manages the registration and use of messaging libraries for sending and receiving messages across multiple chains in LayerZero V2.
/// @dev Libraries handle the sending and receiving of messages between chains (environments) identified by their environment ID (eid).
interface IMessageLibManager {
    /// @notice Struct for defining configuration parameters for an OApp.
    /// @dev Each OApp can have different configurations depending on the chain or environment it operates in.
    /// @param eid The environment ID (chain ID) for which the configuration is applied.
    /// @param configType The type of configuration, which could represent various settings like gas limits, fees, etc.
    /// @param config The actual configuration data encoded in bytes format.
    struct SetConfigParam {
        uint32 eid;
        uint32 configType;
        bytes config;
    }

    /// @notice Struct for storing the timeout details of a receive library.
    /// @param lib The address of the library handling the receiving of messages.
    /// @param expiry The expiration timestamp for this library's validity.
    struct Timeout {
        address lib;
        uint256 expiry;
    }

    /// @notice Emitted when a new library is registered.
    /// @param newLib The address of the newly registered library.
    event LibraryRegistered(address newLib);

    /// @notice Emitted when the default send library is set for a specific environment ID.
    /// @param eid The environment ID (chain ID) for which the default send library is being set.
    /// @param newLib The address of the new default library for sending messages.
    event DefaultSendLibrarySet(uint32 eid, address newLib);

    /// @notice Emitted when the default receive library is set for a specific environment ID.
    /// @param eid The environment ID (chain ID) for which the default receive library is being set.
    /// @param newLib The address of the new default library for receiving messages.
    event DefaultReceiveLibrarySet(uint32 eid, address newLib);

    /// @notice Emitted when a timeout is set for the default receive library.
    /// @param eid The environment ID (chain ID) for which the timeout is being set.
    /// @param oldLib The previous library that was replaced by the new one.
    /// @param expiry The expiration timestamp for the new library.
    event DefaultReceiveLibraryTimeoutSet(
        uint32 eid,
        address oldLib,
        uint256 expiry
    );

    /// @notice Emitted when a specific OApp sets its send library for a particular chain.
    /// @param sender The address of the OApp setting the send library.
    /// @param eid The environment ID (chain ID) for which the library is being set.
    /// @param newLib The address of the new library for sending messages.
    event SendLibrarySet(address sender, uint32 eid, address newLib);

    /// @notice Emitted when a specific OApp sets its receive library for a particular chain.
    /// @param receiver The address of the OApp setting the receive library.
    /// @param eid The environment ID (chain ID) for which the library is being set.
    /// @param newLib The address of the new library for receiving messages.
    event ReceiveLibrarySet(address receiver, uint32 eid, address newLib);

    /// @notice Emitted when a timeout is set for a specific OApp’s receive library.
    /// @param receiver The address of the OApp setting the timeout.
    /// @param eid The environment ID (chain ID) for which the timeout is being set.
    /// @param oldLib The previous library that was replaced by the new one.
    /// @param timeout The timestamp after which the new library will expire.
    event ReceiveLibraryTimeoutSet(
        address receiver,
        uint32 eid,
        address oldLib,
        uint256 timeout
    );

    /// @notice Registers a new library to be used for sending and receiving messages.
    /// @param _lib The address of the new library to be registered.
    function registerLibrary(address _lib) external;

    /// @notice Checks if a library is already registered.
    /// @param _lib The address of the library to check.
    /// @return A boolean indicating if the library is registered.
    function isRegisteredLibrary(address _lib) external view returns (bool);

    /// @notice Retrieves the addresses of all registered libraries.
    /// @return An array of addresses representing all registered libraries.
    function getRegisteredLibraries() external view returns (address[] memory);

    /// @notice Sets the default library for sending messages on a specific chain.
    /// @param _eid The environment ID (chain ID) for which the default send library is being set.
    /// @param _newLib The address of the new default send library.
    function setDefaultSendLibrary(uint32 _eid, address _newLib) external;

    /// @notice Retrieves the default send library for a specific chain.
    /// @param _eid The environment ID (chain ID) to query.
    /// @return The address of the default send library for the given chain.
    function defaultSendLibrary(uint32 _eid) external view returns (address);

    /// @notice Sets the default receive library for a specific chain with a timeout.
    /// @param _eid The environment ID (chain ID) for which the default receive library is being set.
    /// @param _newLib The address of the new default receive library.
    /// @param _timeout The timestamp after which the new library will expire.
    function setDefaultReceiveLibrary(
        uint32 _eid,
        address _newLib,
        uint256 _timeout
    ) external;

    /// @notice Retrieves the default receive library for a specific chain.
    /// @param _eid The environment ID (chain ID) to query.
    /// @return The address of the default receive library for the given chain.
    function defaultReceiveLibrary(uint32 _eid) external view returns (address);

    /// @notice Sets a timeout for the default receive library on a specific chain.
    /// @param _eid The environment ID (chain ID) for which the timeout is being set.
    /// @param _lib The address of the receive library.
    /// @param _expiry The timestamp after which the library will expire.
    function setDefaultReceiveLibraryTimeout(
        uint32 _eid,
        address _lib,
        uint256 _expiry
    ) external;

    /// @notice Retrieves the default receive library and its expiration timestamp for a specific chain.
    /// @param _eid The environment ID (chain ID) to query.
    /// @return lib The address of the default receive library.
    /// @return expiry The expiration timestamp of the library.
    function defaultReceiveLibraryTimeout(
        uint32 _eid
    ) external view returns (address lib, uint256 expiry);

    /// @notice Checks if a specific chain is supported.
    /// @param _eid The environment ID (chain ID) to check.
    /// @return A boolean indicating whether the chain is supported.
    function isSupportedEid(uint32 _eid) external view returns (bool);

    /// @notice Checks if the receive library for a specific OApp and chain is valid.
    /// @param _receiver The address of the OApp acting as a receiver.
    /// @param _eid The environment ID (chain ID) to check.
    /// @param _lib The address of the library to validate.
    /// @return A boolean indicating whether the receive library is valid for the specified OApp and chain.
    function isValidReceiveLibrary(
        address _receiver,
        uint32 _eid,
        address _lib
    ) external view returns (bool);

    /// @notice Sets a specific send library for an OApp on a given chain.
    /// @param _oapp The address of the OApp setting the send library.
    /// @param _eid The environment ID (chain ID) for which the library is being set.
    /// @param _newLib The address of the new library for sending messages.
    function setSendLibrary(
        address _oapp,
        uint32 _eid,
        address _newLib
    ) external;

    /// @notice Retrieves the send library used by a specific OApp on a given chain.
    /// @param _sender The address of the OApp acting as the sender.
    /// @param _eid The environment ID (chain ID) to query.
    /// @return lib The address of the send library.
    function getSendLibrary(
        address _sender,
        uint32 _eid
    ) external view returns (address lib);

    /// @notice Checks if the OApp is using the default send library for a specific chain.
    /// @param _sender The address of the OApp acting as the sender.
    /// @param _eid The environment ID (chain ID) to check.
    /// @return A boolean indicating whether the OApp is using the default send library for the chain.
    function isDefaultSendLibrary(
        address _sender,
        uint32 _eid
    ) external view returns (bool);

    /// @notice Sets a specific receive library for an OApp on a given chain.
    /// @param _oapp The address of the OApp setting the receive library.
    /// @param _eid The environment ID (chain ID) for which the library is being set.
    /// @param _newLib The address of the new library for receiving messages.
    /// @param _gracePeriod The period during which the library will remain valid before expiry.
    function setReceiveLibrary(
        address _oapp,
        uint32 _eid,
        address _newLib,
        uint256 _gracePeriod
    ) external;

    /// @notice Retrieves the receive library used by a specific OApp on a given chain.
    /// @param _receiver The address of the OApp acting as the receiver.
    /// @param _eid The environment ID (chain ID) to query.
    /// @return lib The address of the receive library.
    /// @return isDefault A boolean indicating whether this is the default receive library for the chain.
    function getReceiveLibrary(
        address _receiver,
        uint32 _eid
    ) external view returns (address lib, bool isDefault);

    /// @notice Sets a timeout for the receive library of an OApp on a given chain.
    /// @param _oapp The address of the OApp setting the timeout.
    /// @param _eid The environment ID (chain ID) for which the timeout is being set.
    /// @param _lib The address of the receive library.
    /// @param _gracePeriod The period during which the library will remain valid before expiring.
    function setReceiveLibraryTimeout(
        address _oapp,
        uint32 _eid,
        address _lib,
        uint256 _gracePeriod
    ) external;

    /// @notice Retrieves the timeout information for the receive library of a specific OApp.
    /// @param _receiver The address of the OApp acting as the receiver.
    /// @param _eid The environment ID (chain ID) to query.
    /// @return lib The address of the receive library.
    /// @return expiry The expiration timestamp for the library.
    function receiveLibraryTimeout(
        address _receiver,
        uint32 _eid
    ) external view returns (address lib, uint256 expiry);

    /// @notice Sets configuration parameters for a specific OApp and library.
    /// @param _oapp The address of the OApp for which the configuration is being set.
    /// @param _lib The address of the library to configure.
    /// @param _params An array of SetConfigParam structs defining the configuration parameters.
    function setConfig(
        address _oapp,
        address _lib,
        SetConfigParam[] calldata _params
    ) external;

    /// @notice Retrieves the configuration data for a specific OApp, library, and chain.
    /// @param _oapp The address of the OApp to query.
    /// @param _lib The address of the library to query.
    /// @param _eid The environment ID (chain ID) for which the configuration is being retrieved.
    /// @param _configType The type of configuration to retrieve.
    /// @return config The configuration data.
    function getConfig(
        address _oapp,
        address _lib,
        uint32 _eid,
        uint32 _configType
    ) external view returns (bytes memory config);
}
