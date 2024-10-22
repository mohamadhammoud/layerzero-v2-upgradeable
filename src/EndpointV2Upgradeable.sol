// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MessagingParams, MessagingFee, MessagingReceipt, Origin, ILayerZeroEndpointV2} from "./interfaces/ILayerZeroEndpointV2.sol";
import {ISendLib, Packet} from "./interfaces/ISendLib.sol";
import {ILayerZeroReceiver} from "./interfaces/ILayerZeroReceiver.sol";
import {GUID} from "./libs/GUID.sol";
import {Transfer} from "./libs/Transfer.sol";
import {Errors} from "./libs/Errors.sol";
import {MessagingChannelUpgradeable} from "./MessagingChannelUpgradeable.sol";
import {MessagingComposerUpgradeable} from "./MessagingComposerUpgradeable.sol";
import {MessageLibManagerUpgradeable} from "./MessageLibManagerUpgradeable.sol";
import {MessagingContextUpgradeable} from "./MessagingContextUpgradeable.sol";

/**
 * @title EndpointV2Upgradeable
 * @dev Upgradeable contract for LayerZero EndpointV2 functionality. Handles omnichain messaging, fee management,
 *      and delegate control. Follows the namespaced storage pattern using ERC-7201 for upgradeable storage.
 */
contract EndpointV2Upgradeable is
    ILayerZeroEndpointV2,
    MessagingChannelUpgradeable,
    MessageLibManagerUpgradeable,
    MessagingComposerUpgradeable,
    MessagingContextUpgradeable
{
    // Define the storage location for EndpointV2, following the namespaced storage pattern.
    bytes32 private constant ENDPOINT_STORAGE_SLOT =
        0xd875ef2f687a9526a0ec9369765cb9f8e9372b7e5a164edfb1e0c54a665af200;
    //    keccak256(abi.encode(uint256(keccak256("EndpointV2Upgradeable.storage")) - 1)) & ~bytes32(uint256(0xff));

    /// @custom:storage-location erc7201:layerzero.endpoint.storage.v2
    struct EndpointStorage {
        address lzToken; // LayerZero token used for paying messaging fees
        mapping(address => address) delegates; // Mapping of OApp addresses to their delegates
    }

    /**
     * @dev Retrieves the storage for the contract using inline assembly.
     * @return storageRef A reference to the EndpointStorage struct.
     */
    function _getEndpointStorage()
        internal
        pure
        returns (EndpointStorage storage storageRef)
    {
        bytes32 slot = ENDPOINT_STORAGE_SLOT;
        assembly {
            storageRef.slot := slot
        }
    }

    /**
     * @dev Initializes the contract with the provided endpoint ID and owner address.
     * @param _eid The endpoint ID representing the current deployment.
     * @param _owner The owner of the contract, typically the deployer or application owner.
     */
    function initialize(uint32 _eid, address _owner) public initializer {
        // Initialize the messaging channel with the endpoint ID
        __MessagingChannel_init(_eid);
        __MessageLibManager_init(_owner);
    }

    /**
     * @notice Provides a quote for sending a message based on the messaging parameters.
     * @dev MESSAGING STEP 0: Returns a fee estimate based on the parameters,
     *      such as destination chain, message size, and whether the fee will be paid in LayerZero tokens.
     * @param _params Messaging parameters, including destination chain and message.
     * @param _sender The sender of the message.
     * @return MessagingFee The calculated fee, including native token fee and LayerZero token fee.
     */
    function quote(
        MessagingParams calldata _params,
        address _sender
    ) external view returns (MessagingFee memory) {
        EndpointStorage storage es = _getEndpointStorage();

        // Ensure that the LayerZero token is set if the fee is to be paid in LayerZero tokens
        if (_params.payInLzToken && es.lzToken == address(0x0))
            revert Errors.LzTokenUnavailable();

        // Generate the outbound nonce for the message
        uint64 nonce = _getMessagingChannelStorage().outboundNonce[_sender][
            _params.dstEid
        ][_params.receiver] + 1;

        uint32 eid = _getMessagingChannelStorage().eid;

        // Construct the packet for the message
        Packet memory packet = Packet({
            nonce: nonce,
            srcEid: eid,
            sender: _sender,
            dstEid: _params.dstEid,
            receiver: _params.receiver,
            guid: GUID.generate(
                nonce,
                eid,
                _sender,
                _params.dstEid,
                _params.receiver
            ),
            message: _params.message
        });

        // Retrieve the send library for the sender and destination endpoint ID
        address sendLibrary = getSendLibrary(_sender, _params.dstEid);

        // Return the fee calculated by the send library
        return
            ISendLib(sendLibrary).quote(
                packet,
                _params.options,
                _params.payInLzToken
            );
    }

    /// @notice Retrieves the address of the LayerZero (LZ) token currently set.
    /// @return The address of the LZ token contract.
    function lzToken() external view returns (address) {
        EndpointStorage storage es = _getEndpointStorage();

        return es.lzToken;
    }
    /**
     * @notice Sends a message to the destination chain after transferring the required fees.
     * @dev MESSAGING STEP 1: Facilitates message transfer and handles the payment of both native
     *      and LayerZero token fees. Refunds any excess fees to the specified refund address.
     * @param _params Messaging parameters, including destination chain and message.
     * @param _refundAddress The address to refund any excess fees.
     * @return MessagingReceipt The receipt of the sent message, including GUID and nonce.
     */
    function send(
        MessagingParams calldata _params,
        address _refundAddress
    ) external payable returns (MessagingReceipt memory) {
        EndpointStorage storage es = _getEndpointStorage();

        // Ensure LayerZero token is set if paying in LayerZero tokens
        if (_params.payInLzToken && es.lzToken == address(0x0))
            revert Errors.LzTokenUnavailable();

        // Perform the message send operation
        (MessagingReceipt memory receipt, address sendLibrary) = _send(
            msg.sender,
            _params
        );

        // Ensure sufficient fees are provided
        uint256 suppliedNative = _suppliedNative();
        uint256 suppliedLzToken = _suppliedLzToken(_params.payInLzToken);
        _assertMessagingFee(receipt.fee, suppliedNative, suppliedLzToken);

        // Handle payment of LayerZero token fees
        _payToken(
            es.lzToken,
            receipt.fee.lzTokenFee,
            suppliedLzToken,
            sendLibrary,
            _refundAddress
        );

        // Handle payment of native fees
        _payNative(
            receipt.fee.nativeFee,
            suppliedNative,
            sendLibrary,
            _refundAddress
        );

        return receipt;
    }

    /**
     * @notice Verifies a message on the destination chain before executing it.
     * @dev MESSAGING STEP 2: Ensures the message is valid, the destination chain and
     *      sender are correct, and the message payload can be trusted.
     * @param _origin The origin details of the message, including source endpoint and nonce.
     * @param _receiver The receiver of the message.
     * @param _payloadHash The hash of the message payload.
     */
    function verify(
        Origin calldata _origin,
        address _receiver,
        bytes32 _payloadHash
    ) external {
        // Ensure the library used for receiving is valid
        if (!isValidReceiveLibrary(_receiver, _origin.srcEid, msg.sender))
            revert Errors.InvalidReceiveLibrary();

        uint64 lazyNonce = _getMessagingChannelStorage().lazyInboundNonce[
            _receiver
        ][_origin.srcEid][_origin.sender];

        if (!_initializable(_origin, _receiver, lazyNonce))
            revert Errors.PathNotInitializable();
        if (!_verifiable(_origin, _receiver, lazyNonce))
            revert Errors.PathNotVerifiable();

        // Store the message in the messaging channel
        _inbound(
            _receiver,
            _origin.srcEid,
            _origin.sender,
            _origin.nonce,
            _payloadHash
        );
        emit PacketVerified(_origin, _receiver, _payloadHash);
    }

    /**
     * @notice Executes a verified message on the destination chain.
     * @dev MESSAGING STEP 3: After verifying a message, clears the payload from storage
     *      and allows the receiver to execute the message.
     * @param _origin The origin details of the message, including source endpoint and nonce.
     * @param _receiver The address of the receiver of the message.
     * @param _guid The globally unique identifier for the message.
     * @param _message The message payload.
     * @param _extraData Additional untrusted data provided by the executor.
     */
    function lzReceive(
        Origin calldata _origin,
        address _receiver,
        bytes32 _guid,
        bytes calldata _message,
        bytes calldata _extraData
    ) external payable {
        // Clear the message payload to prevent reentrancy
        _clearPayload(
            _receiver,
            _origin.srcEid,
            _origin.sender,
            _origin.nonce,
            abi.encodePacked(_guid, _message)
        );

        // Execute the message on the receiver contract
        ILayerZeroReceiver(_receiver).lzReceive{value: msg.value}(
            _origin,
            _guid,
            _message,
            msg.sender,
            _extraData
        );
        emit PacketDelivered(_origin, _receiver);
    }

    /// @dev Oapp uses this interface to clear a message.
    /// @dev this is a PULL mode versus the PUSH mode of lzReceive
    /// @dev the cleared message can be ignored by the app (effectively burnt)
    /// @dev authenticated by oapp
    /// @param _origin the origin of the message
    /// @param _guid the guid of the message
    /// @param _message the message
    function clear(
        address _oapp,
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message
    ) external {
        _assertAuthorized(_oapp);

        bytes memory payload = abi.encodePacked(_guid, _message);
        _clearPayload(
            _oapp,
            _origin.srcEid,
            _origin.sender,
            _origin.nonce,
            payload
        );
        emit PacketDelivered(_origin, _oapp);
    }

    /**
     * @notice Sets the LayerZero token used for paying messaging fees.
     * @dev Can only be called by the owner of the contract.
     * @param _lzToken The new LayerZero token address.
     */
    function setLzToken(address _lzToken) public onlyOwner {
        EndpointStorage storage es = _getEndpointStorage();
        es.lzToken = _lzToken;
        emit LzTokenSet(_lzToken);
    }

    /**
     * @notice Sets a delegate for an OApp, authorizing them to manage configurations.
     * @dev Can be used by an OApp to authorize a delegate to manage LayerZero configurations.
     * @param _delegate The address of the delegate to authorize.
     */
    function setDelegate(address _delegate) external {
        EndpointStorage storage es = _getEndpointStorage();
        es.delegates[msg.sender] = _delegate;
        emit DelegateSet(msg.sender, _delegate);
    }

    // ========================= Internal Functions =========================
    function _initializable(
        Origin calldata _origin,
        address _receiver,
        uint64 _lazyInboundNonce
    ) internal view returns (bool) {
        return
            _lazyInboundNonce > 0 || // allowInitializePath already checked
            ILayerZeroReceiver(_receiver).allowInitializePath(_origin);
    }

    /// @dev bytes(0) payloadHash can never be submitted
    function _verifiable(
        Origin calldata _origin,
        address _receiver,
        uint64 _lazyInboundNonce
    ) internal view returns (bool) {
        return
            _origin.nonce > _lazyInboundNonce || // either initializing an empty slot or reverifying
            _getMessagingChannelStorage().inboundPayloadHash[_receiver][
                _origin.srcEid
            ][_origin.sender][_origin.nonce] !=
            EMPTY_PAYLOAD_HASH; // only allow reverifying if it hasn't been executed
    }

    /// @dev assert the caller to either be the oapp or the delegate
    function _assertAuthorized(
        address _oapp
    )
        internal
        view
        override(MessagingChannelUpgradeable, MessageLibManagerUpgradeable)
    {
        if (
            msg.sender != _oapp &&
            msg.sender != _getEndpointStorage().delegates[_oapp]
        ) revert Errors.Unauthorized();
    }

    /**
     * @dev Internal function to handle the message send operation.
     * @param _sender The sender address.
     * @param _params The messaging parameters.
     * @return receipt The messaging receipt.
     * @return sendLibrary The library used for sending the message.
     */
    function _send(
        address _sender,
        MessagingParams calldata _params
    ) internal returns (MessagingReceipt memory, address) {
        // Generate the outbound nonce for the message
        uint64 latestNonce = _outbound(
            _sender,
            _params.dstEid,
            _params.receiver
        );

        uint32 eid = _getMessagingChannelStorage().eid;

        // Construct the packet for the message
        Packet memory packet = Packet({
            nonce: latestNonce,
            srcEid: eid,
            sender: _sender,
            dstEid: _params.dstEid,
            receiver: _params.receiver,
            guid: GUID.generate(
                latestNonce,
                eid,
                _sender,
                _params.dstEid,
                _params.receiver
            ),
            message: _params.message
        });

        // Retrieve the send library for the sender and destination endpoint ID
        address sendLibrary = getSendLibrary(_sender, _params.dstEid);

        // Message library returns the MessagingFee and encoded packet
        (MessagingFee memory fee, bytes memory encodedPacket) = ISendLib(
            sendLibrary
        ).send(packet, _params.options, _params.payInLzToken);

        emit PacketSent(encodedPacket, _params.options, sendLibrary);

        return (MessagingReceipt(packet.guid, latestNonce, fee), sendLibrary);
    }

    /**
     * @dev Internal function to handle LayerZero token payments.
     * @param _token The LayerZero token address.
     * @param _required The required amount of LayerZero tokens for payment.
     * @param _supplied The amount of tokens provided for payment.
     * @param _receiver The receiver of the payment.
     * @param _refundAddress The address to refund any excess tokens.
     */
    function _payToken(
        address _token,
        uint256 _required,
        uint256 _supplied,
        address _receiver,
        address _refundAddress
    ) internal {
        if (_required > 0) {
            Transfer.token(_token, _receiver, _required);
        }
        if (_required < _supplied) {
            unchecked {
                // Refund any excess tokens
                Transfer.token(_token, _refundAddress, _supplied - _required);
            }
        }
    }

    /**
     * @dev Internal function to handle native token payments.
     * @param _required The required amount of native tokens for payment.
     * @param _supplied The amount of native tokens provided for payment.
     * @param _receiver The receiver of the native payment.
     * @param _refundAddress The address to refund any excess tokens.
     */
    function _payNative(
        uint256 _required,
        uint256 _supplied,
        address _receiver,
        address _refundAddress
    ) internal virtual {
        if (_required > 0) {
            Transfer.native(_receiver, _required);
        }
        if (_required < _supplied) {
            unchecked {
                // Refund any excess native tokens
                Transfer.native(_refundAddress, _supplied - _required);
            }
        }
    }

    /**
     * @dev Ensures the fees provided are sufficient for the messaging operation.
     * @param _required The required fee amounts.
     * @param _suppliedNativeFee The supplied native fee amount.
     * @param _suppliedLzTokenFee The supplied LayerZero token fee amount.
     */
    function _assertMessagingFee(
        MessagingFee memory _required,
        uint256 _suppliedNativeFee,
        uint256 _suppliedLzTokenFee
    ) internal pure {
        if (
            _required.nativeFee > _suppliedNativeFee ||
            _required.lzTokenFee > _suppliedLzTokenFee
        ) {
            revert Errors.InsufficientFee(
                _required.nativeFee,
                _suppliedNativeFee,
                _required.lzTokenFee,
                _suppliedLzTokenFee
            );
        }
    }

    /**
     * @dev Retrieves the supplied LayerZero token fee amount if `payInLzToken` is true.
     * @param _payInLzToken Flag indicating whether to pay the fee in LayerZero tokens.
     * @return supplied The supplied LayerZero token fee.
     */
    function _suppliedLzToken(
        bool _payInLzToken
    ) internal view returns (uint256 supplied) {
        if (_payInLzToken) {
            supplied = IERC20(_getEndpointStorage().lzToken).balanceOf(
                address(this)
            );
            if (supplied == 0) revert Errors.ZeroLzTokenFee();
        }
    }

    /**
     * @dev Retrieves the supplied native token amount.
     * @return The amount of native tokens supplied for payment.
     */
    function _suppliedNative() internal view virtual returns (uint256) {
        return msg.value;
    }

    // ========================= VIEW FUNCTIONS FOR OFFCHAIN ONLY =========================
    // Not involved in any state transition function.
    // ====================================================================================
    function initializable(
        Origin calldata _origin,
        address _receiver
    ) external view returns (bool) {
        return
            _initializable(
                _origin,
                _receiver,
                _getMessagingChannelStorage().lazyInboundNonce[_receiver][
                    _origin.srcEid
                ][_origin.sender]
            );
    }

    /// @dev override this if the endpoint is charging ERC20 tokens as native
    /// @return 0x0 if using native. otherwise the address of the native ERC20 token
    function nativeToken() external view virtual returns (address) {
        return address(0x0);
    }

    function verifiable(
        Origin calldata _origin,
        address _receiver
    ) external view returns (bool) {
        return
            _verifiable(
                _origin,
                _receiver,
                _getMessagingChannelStorage().lazyInboundNonce[_receiver][
                    _origin.srcEid
                ][_origin.sender]
            );
    }
}
