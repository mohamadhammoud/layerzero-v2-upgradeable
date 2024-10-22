// SPDX-License-Identifier: LZBL-1.2

pragma solidity ^0.8.20;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IMessageLib, MessageLibType} from "./interfaces/IMessageLib.sol";
import {IMessageLibManager, SetConfigParam} from "./interfaces/IMessageLibManager.sol";
import {Errors} from "./libs/Errors.sol";
import {BlockedMessageLib} from "./messagelib/BlockedMessageLib.sol";

/**
 * @title MessageLibManagerUpgradeable
 * @dev Manages message libraries for LayerZero applications, including registration, versioning, and configuration.
 * This contract follows the upgradeable storage pattern using ERC-7201.
 */
abstract contract MessageLibManagerUpgradeable is
    OwnableUpgradeable,
    IMessageLibManager
{
    address private constant DEFAULT_LIB = address(0);

    /// @custom:storage-location erc7201:messagelib.manager.storage
    struct MessageLibManagerStorage {
        address blockedLibrary; // Immutable blocked library that reverts on operations
        address[] registeredLibraries; // Array of registered libraries
        mapping(address lib => bool) isRegisteredLibrary; // Mapping to check if a library is registered
        mapping(address sender => mapping(uint32 dstEid => address lib)) sendLibrary; // Send library mappings
        mapping(address receiver => mapping(uint32 srcEid => address lib)) receiveLibrary; // Receive library mappings
        mapping(address receiver => mapping(uint32 srcEid => Timeout)) receiveLibraryTimeout; // Receive library timeouts
        mapping(uint32 dstEid => address lib) defaultSendLibrary; // Default send libraries for endpoint IDs
        mapping(uint32 srcEid => address lib) defaultReceiveLibrary; // Default receive libraries for endpoint IDs
        mapping(uint32 srcEid => Timeout) defaultReceiveLibraryTimeout; // Timeout mapping for default libraries
    }

    /// @dev Storage slot for the contract storage
    bytes32 private constant MESSAGELIB_MANAGER_STORAGE_SLOT =
        0x504315d93ce9ee49e3122a2e5a1956935a99ba2bd355ba8cd89135957092d300;
    // keccak256(abi.encode(uint256(keccak256("MessageLibManagerUpgradeable.storage")) - 1)) & ~bytes32(uint256(0xff));

    /**
     * @dev Retrieves the storage for the contract using inline assembly.
     * @return storageRef A reference to the MessageLibManagerStorage struct.
     */
    function _getMessageLibManagerStorage()
        internal
        pure
        returns (MessageLibManagerStorage storage storageRef)
    {
        bytes32 slot = MESSAGELIB_MANAGER_STORAGE_SLOT;
        assembly {
            storageRef.slot := slot
        }
    }

    /**
     * @dev Initializes the contract, setting the blocked library and registering it.
     * This replaces the constructor for upgradeable contracts.
     */
    function __MessageLibManager_init(address owner) internal onlyInitializing {
        __Ownable_init(owner);

        // Register blocked library in storage.
        MessageLibManagerStorage storage s = _getMessageLibManagerStorage();
        s.blockedLibrary = address(new BlockedMessageLib());
        registerLibrary(s.blockedLibrary);
    }

    // Modifiers for access control and validation

    modifier onlyRegistered(address _lib) {
        if (!_getMessageLibManagerStorage().isRegisteredLibrary[_lib])
            revert Errors.OnlyRegisteredLib();
        _;
    }

    modifier isSendLib(address _lib) {
        if (
            _lib != DEFAULT_LIB &&
            IMessageLib(_lib).messageLibType() == MessageLibType.Receive
        ) {
            revert Errors.OnlySendLib();
        }
        _;
    }

    modifier isReceiveLib(address _lib) {
        if (
            _lib != DEFAULT_LIB &&
            IMessageLib(_lib).messageLibType() == MessageLibType.Send
        ) {
            revert Errors.OnlyReceiveLib();
        }
        _;
    }

    modifier onlyRegisteredOrDefault(address _lib) {
        if (
            !_getMessageLibManagerStorage().isRegisteredLibrary[_lib] &&
            _lib != DEFAULT_LIB
        ) revert Errors.OnlyRegisteredOrDefaultLib();
        _;
    }

    modifier onlySupportedEid(address _lib, uint32 _eid) {
        if (_lib != DEFAULT_LIB && !IMessageLib(_lib).isSupportedEid(_eid)) {
            revert Errors.UnsupportedEid();
        }
        _;
    }

    // Getter functions
    /// @notice Retrieves the timeout information for the receive library of a specific OApp.
    /// @param _receiver The address of the OApp acting as the receiver.
    /// @param _eid The environment ID (chain ID) to query.
    /// @return lib The address of the receive library.
    /// @return expiry The expiration timestamp for the library.
    function receiveLibraryTimeout(
        address _receiver,
        uint32 _eid
    ) external view returns (address lib, uint256 expiry) {
        MessageLibManagerStorage storage s = _getMessageLibManagerStorage();
        Timeout memory t = s.receiveLibraryTimeout[_receiver][_eid];

        lib = t.lib;
        expiry = t.expiry;
    }

    /// @notice Retrieves the default receive library for a specific chain.
    /// @param _eid The environment ID (chain ID) to query.
    /// @return The address of the default receive library for the given chain.
    function defaultReceiveLibrary(
        uint32 _eid
    ) external view returns (address) {
        MessageLibManagerStorage storage s = _getMessageLibManagerStorage();

        return s.defaultReceiveLibrary[_eid];
    }

    /// @notice Retrieves the default send library for a specific chain.
    /// @param _eid The environment ID (chain ID) to query.
    /// @return The address of the default send library for the given chain.
    function defaultSendLibrary(uint32 _eid) external view returns (address) {
        MessageLibManagerStorage storage s = _getMessageLibManagerStorage();

        return s.defaultSendLibrary[_eid];
    }

    /// @notice Retrieves the default receive library and its expiration timestamp for a specific chain.
    /// @param _eid The environment ID (chain ID) to query.
    /// @return lib The address of the default receive library.
    /// @return expiry The expiration timestamp of the library.
    function defaultReceiveLibraryTimeout(
        uint32 _eid
    ) external view returns (address lib, uint256 expiry) {
        MessageLibManagerStorage storage s = _getMessageLibManagerStorage();

        Timeout memory t = s.defaultReceiveLibraryTimeout[_eid];

        lib = t.lib;
        expiry = t.expiry;
    }

    /**
     * @notice Returns the list of all registered libraries.
     */
    function getRegisteredLibraries() external view returns (address[] memory) {
        return _getMessageLibManagerStorage().registeredLibraries;
    }

    function isRegisteredLibrary(address _lib) external view returns (bool) {
        return _getMessageLibManagerStorage().isRegisteredLibrary[_lib];
    }

    /**
     * @notice Returns the send library for the given sender and destination endpoint ID.
     * @param _sender The address of the message sender.
     * @param _dstEid The destination endpoint ID.
     * @return lib The address of the send library.
     */
    function getSendLibrary(
        address _sender,
        uint32 _dstEid
    ) public view returns (address lib) {
        lib = _getMessageLibManagerStorage().sendLibrary[_sender][_dstEid];
        if (lib == DEFAULT_LIB) {
            lib = _getMessageLibManagerStorage().defaultSendLibrary[_dstEid];
            if (lib == address(0x0)) revert Errors.DefaultSendLibUnavailable();
        }
    }

    function isDefaultSendLibrary(
        address _sender,
        uint32 _dstEid
    ) public view returns (bool) {
        return
            _getMessageLibManagerStorage().sendLibrary[_sender][_dstEid] ==
            DEFAULT_LIB;
    }

    function getReceiveLibrary(
        address _receiver,
        uint32 _srcEid
    ) public view returns (address lib, bool isDefault) {
        lib = _getMessageLibManagerStorage().receiveLibrary[_receiver][_srcEid];
        if (lib == DEFAULT_LIB) {
            lib = _getMessageLibManagerStorage().defaultReceiveLibrary[_srcEid];
            if (lib == address(0x0))
                revert Errors.DefaultReceiveLibUnavailable();
            isDefault = true;
        }
    }

    function isValidReceiveLibrary(
        address _receiver,
        uint32 _srcEid,
        address _actualReceiveLib
    ) public view returns (bool) {
        (address expectedReceiveLib, bool isDefault) = getReceiveLibrary(
            _receiver,
            _srcEid
        );
        if (_actualReceiveLib == expectedReceiveLib) return true;

        Timeout memory timeout = isDefault
            ? _getMessageLibManagerStorage().defaultReceiveLibraryTimeout[
                _srcEid
            ]
            : _getMessageLibManagerStorage().receiveLibraryTimeout[_receiver][
                _srcEid
            ];
        return
            timeout.lib == _actualReceiveLib && timeout.expiry > block.number;
    }

    // Library registration

    /**
     * @notice Registers a new library.
     * @param _lib The address of the library to register.
     */
    function registerLibrary(address _lib) public onlyOwner {
        if (!IERC165(_lib).supportsInterface(type(IMessageLib).interfaceId))
            revert Errors.UnsupportedInterface();
        if (_getMessageLibManagerStorage().isRegisteredLibrary[_lib])
            revert Errors.AlreadyRegistered();

        _getMessageLibManagerStorage().isRegisteredLibrary[_lib] = true;
        _getMessageLibManagerStorage().registeredLibraries.push(_lib);

        emit LibraryRegistered(_lib);
    }

    // Set default libraries

    /**
     * @notice Sets the default send library for a given endpoint ID.
     * @param _eid The endpoint ID.
     * @param _newLib The address of the new library.
     */
    function setDefaultSendLibrary(
        uint32 _eid,
        address _newLib
    )
        external
        onlyOwner
        onlyRegistered(_newLib)
        isSendLib(_newLib)
        onlySupportedEid(_newLib, _eid)
    {
        MessageLibManagerStorage storage s = _getMessageLibManagerStorage();
        if (s.defaultSendLibrary[_eid] == _newLib) revert Errors.SameValue();
        s.defaultSendLibrary[_eid] = _newLib;
        emit DefaultSendLibrarySet(_eid, _newLib);
    }

    /**
     * @notice Sets the default receive library for a given endpoint ID.
     * @param _eid The endpoint ID.
     * @param _newLib The address of the new library.
     * @param _gracePeriod The grace period before the old library expires.
     */
    function setDefaultReceiveLibrary(
        uint32 _eid,
        address _newLib,
        uint256 _gracePeriod
    )
        external
        onlyOwner
        onlyRegistered(_newLib)
        isReceiveLib(_newLib)
        onlySupportedEid(_newLib, _eid)
    {
        MessageLibManagerStorage storage s = _getMessageLibManagerStorage();
        address oldLib = s.defaultReceiveLibrary[_eid];
        if (oldLib == _newLib) revert Errors.SameValue();

        s.defaultReceiveLibrary[_eid] = _newLib;
        emit DefaultReceiveLibrarySet(_eid, _newLib);

        if (_gracePeriod > 0) {
            Timeout storage timeout = s.defaultReceiveLibraryTimeout[_eid];
            timeout.lib = oldLib;
            timeout.expiry = block.number + _gracePeriod;
            emit DefaultReceiveLibraryTimeoutSet(_eid, oldLib, timeout.expiry);
        } else {
            delete s.defaultReceiveLibraryTimeout[_eid];
            emit DefaultReceiveLibraryTimeoutSet(_eid, oldLib, 0);
        }
    }

    /**
     * @notice Sets the timeout for a default receive library for a given endpoint ID.
     * @param _eid The endpoint ID.
     * @param _lib The address of the library.
     * @param _expiry The block number when the timeout expires.
     */
    function setDefaultReceiveLibraryTimeout(
        uint32 _eid,
        address _lib,
        uint256 _expiry
    )
        external
        onlyRegistered(_lib)
        isReceiveLib(_lib)
        onlySupportedEid(_lib, _eid)
        onlyOwner
    {
        MessageLibManagerStorage storage s = _getMessageLibManagerStorage();
        if (_expiry == 0) {
            delete s.defaultReceiveLibraryTimeout[_eid];
        } else {
            if (_expiry <= block.number) revert Errors.InvalidExpiry();
            Timeout storage timeout = s.defaultReceiveLibraryTimeout[_eid];
            timeout.lib = _lib;
            timeout.expiry = _expiry;
        }
        emit DefaultReceiveLibraryTimeoutSet(_eid, _lib, _expiry);
    }

    /// @dev returns true only if both the default send/receive libraries are set
    function isSupportedEid(uint32 _eid) external view returns (bool) {
        MessageLibManagerStorage storage s = _getMessageLibManagerStorage();

        return
            s.defaultSendLibrary[_eid] != address(0) &&
            s.defaultReceiveLibrary[_eid] != address(0);
    }

    // OApp Interfaces

    function setSendLibrary(
        address _oapp,
        uint32 _eid,
        address _newLib
    )
        external
        onlyRegisteredOrDefault(_newLib)
        isSendLib(_newLib)
        onlySupportedEid(_newLib, _eid)
    {
        _assertAuthorized(_oapp);
        MessageLibManagerStorage storage s = _getMessageLibManagerStorage();

        if (s.sendLibrary[_oapp][_eid] == _newLib) revert Errors.SameValue();
        s.sendLibrary[_oapp][_eid] = _newLib;
        emit SendLibrarySet(_oapp, _eid, _newLib);
    }

    function setReceiveLibrary(
        address _oapp,
        uint32 _eid,
        address _newLib,
        uint256 _gracePeriod
    )
        external
        onlyRegisteredOrDefault(_newLib)
        isReceiveLib(_newLib)
        onlySupportedEid(_newLib, _eid)
    {
        _assertAuthorized(_oapp);
        MessageLibManagerStorage storage s = _getMessageLibManagerStorage();
        address oldLib = s.receiveLibrary[_oapp][_eid];

        if (oldLib == _newLib) revert Errors.SameValue();
        s.receiveLibrary[_oapp][_eid] = _newLib;
        emit ReceiveLibrarySet(_oapp, _eid, _newLib);

        if (_gracePeriod > 0) {
            if (oldLib == DEFAULT_LIB || _newLib == DEFAULT_LIB)
                revert Errors.OnlyNonDefaultLib();
            Timeout memory timeout = Timeout({
                lib: oldLib,
                expiry: block.number + _gracePeriod
            });
            s.receiveLibraryTimeout[_oapp][_eid] = timeout;
            emit ReceiveLibraryTimeoutSet(_oapp, _eid, oldLib, timeout.expiry);
        } else {
            delete s.receiveLibraryTimeout[_oapp][_eid];
            emit ReceiveLibraryTimeoutSet(_oapp, _eid, oldLib, 0);
        }
    }

    function setReceiveLibraryTimeout(
        address _oapp,
        uint32 _eid,
        address _lib,
        uint256 _expiry
    )
        external
        onlyRegistered(_lib)
        isReceiveLib(_lib)
        onlySupportedEid(_lib, _eid)
    {
        _assertAuthorized(_oapp);
        MessageLibManagerStorage storage s = _getMessageLibManagerStorage();

        (, bool isDefault) = getReceiveLibrary(_oapp, _eid);
        if (isDefault) revert Errors.OnlyNonDefaultLib();

        if (_expiry == 0) {
            delete s.receiveLibraryTimeout[_oapp][_eid];
        } else {
            if (_expiry <= block.number) revert Errors.InvalidExpiry();
            Timeout storage timeout = s.receiveLibraryTimeout[_oapp][_eid];
            timeout.lib = _lib;
            timeout.expiry = _expiry;
        }
        emit ReceiveLibraryTimeoutSet(_oapp, _eid, _lib, _expiry);
    }

    function setConfig(
        address _oapp,
        address _lib,
        SetConfigParam[] calldata _params
    ) external onlyRegistered(_lib) {
        _assertAuthorized(_oapp);
        IMessageLib(_lib).setConfig(_oapp, _params);
    }

    function getConfig(
        address _oapp,
        address _lib,
        uint32 _eid,
        uint32 _configType
    ) external view onlyRegistered(_lib) returns (bytes memory config) {
        return IMessageLib(_lib).getConfig(_eid, _oapp, _configType);
    }

    function _assertAuthorized(address _oapp) internal virtual;
}
