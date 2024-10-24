// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IOAppCore} from "./interfaces/IOAppCore.sol";
import {ILayerZeroEndpointV2} from "./interfaces/ILayerZeroEndpointV2.sol";

/**
 * @title OAppCoreUpgradeable
 * @dev Abstract contract implementing the IOAppCoreUpgradeable interface with basic OApp configurations.
 *      This contract is upgradeable using OpenZeppelin's upgradeable proxy pattern, with namespaced storage based on ERC-7201.
 */
abstract contract OAppCoreUpgradeable is
    IOAppCore,
    Initializable,
    OwnableUpgradeable
{
    /// @custom:storage-location erc7201:oappcoreUpgradeable.endpoint
    struct OAppCoreUpgradeableStorage {
        ILayerZeroEndpointV2 endpoint;
        mapping(uint32 => bytes32) peers;
    }

    // Storage location constants for ERC-7201
    bytes32 private constant OAPP_CORE_STORAGE_SLOT =
        0x2a68337b99837b5cd9932b5f5cee101ff79e0dda8443ea274eb71f6701cfc400;
    // keccak256(
    //     abi.encode(uint256(keccak256("OAppCoreUpgradeable.storage")) - 1)
    // ) & ~bytes32(uint256(0xff));

    /**
     * @dev Initializes the OAppCoreUpgradeable contract with the provided LayerZero endpoint and delegate address.
     * @param _endpoint The address of the LayerZero endpoint contract.
     * @param _delegate The delegate capable of configuring the OApp.
     */
    function __OAppCoreUpgradeable_init(
        address _endpoint,
        address _delegate
    ) public initializer {
        __Ownable_init(_delegate); // Initializes the upgradeable Ownable contract

        _getOAppCoreUpgradeableStorage().endpoint = ILayerZeroEndpointV2(
            _endpoint
        );
        if (_delegate == address(0)) revert InvalidDelegate();
        _getOAppCoreUpgradeableStorage().endpoint.setDelegate(_delegate);
    }

    /**
     * @dev Implements the `endpoint()` function from IOAppCoreUpgradeable.
     *      Returns the stored LayerZero endpoint instance.
     * @return iEndpoint The LayerZero endpoint contract.
     */
    function endpoint()
        public
        view
        override
        returns (ILayerZeroEndpointV2 iEndpoint)
    {
        return _getOAppCoreUpgradeableStorage().endpoint;
    }

    /**
     * @dev Implements the `peers(uint32 _eid)` function from IOAppCoreUpgradeable.
     *      Returns the stored peer address for the given endpoint ID.
     * @param _eid The endpoint ID.
     * @return peer The peer address associated with the given endpoint ID.
     */
    function peers(uint32 _eid) public view override returns (bytes32 peer) {
        return _getOAppCoreUpgradeableStorage().peers[_eid];
    }

    /**
     * @notice Sets the peer address (OApp instance) for a corresponding endpoint.
     * @param _eid The endpoint ID.
     * @param _peer The address of the peer to be associated with the corresponding endpoint.
     *
     * @dev Only the owner/admin of the OApp can call this function.
     * @dev Indicates that the peer is trusted to send LayerZero messages to this OApp.
     * @dev Set this to bytes32(0) to remove the peer address.
     * @dev Peer is a bytes32 to accommodate non-evm chains.
     */
    function setPeer(uint32 _eid, bytes32 _peer) public virtual onlyOwner {
        _setPeer(_eid, _peer);
    }

    /**
     * @notice Internal function to set the peer address for a corresponding endpoint.
     * @param _eid The endpoint ID.
     * @param _peer The address of the peer.
     *
     * @dev Indicates that the peer is trusted to send LayerZero messages to this OApp.
     * @dev Set this to bytes32(0) to remove the peer address.
     * @dev Peer is a bytes32 to accommodate non-evm chains.
     */
    function _setPeer(uint32 _eid, bytes32 _peer) internal virtual {
        _getOAppCoreUpgradeableStorage().peers[_eid] = _peer;
        emit PeerSet(_eid, _peer);
    }

    /**
     * @notice Internal function to get the peer address associated with a specific endpoint; reverts if not set.
     * ie. the peer is set to bytes32(0).
     * @param _eid The endpoint ID.
     * @return peer The address of the peer associated with the specified endpoint.
     */
    function _getPeerOrRevert(
        uint32 _eid
    ) internal view virtual returns (bytes32) {
        bytes32 peer = _getOAppCoreUpgradeableStorage().peers[_eid];
        if (peer == bytes32(0)) revert NoPeer(_eid);
        return peer;
    }

    /**
     * @notice Sets the delegate address for the OApp.
     * @param _delegate The address of the delegate to be set.
     *
     * @dev Only the owner/admin of the OApp can call this function.
     * @dev Provides the ability for a delegate to set configs, on behalf of the OApp, directly on the Endpoint contract.
     */
    function setDelegate(address _delegate) public onlyOwner {
        _getOAppCoreUpgradeableStorage().endpoint.setDelegate(_delegate);
    }

    /**
     * @dev Retrieves the EndpointStorage using inline assembly.
     * @return storageRef Reference to the namespaced EndpointStorage struct.
     */
    function _getOAppCoreUpgradeableStorage()
        internal
        pure
        returns (OAppCoreUpgradeableStorage storage storageRef)
    {
        assembly {
            storageRef.slot := OAPP_CORE_STORAGE_SLOT
        }
    }
}
