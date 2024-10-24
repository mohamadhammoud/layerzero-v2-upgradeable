// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./OAppUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title GatewayV2
 * @dev Extension of GatewayV1 with additional functionality.
 */
/// @custom:oz-upgrades-from GatewayV1
contract GatewayV2 is OAppUpgradeable, UUPSUpgradeable {
    // Event to signal that a message was received
    event MessageReceived(uint32 srcEid, bytes32 sender, string message);

    // State variable to store the last received message
    string public lastReceivedMessage;
    uint32 public lastReceivedSrcEid; // To store the source endpoint ID from the origin
    bytes32 public lastSender; // To store the sender address from the origin

    /**
     * @dev Initializes the GatewayV1 with the provided endpoint and delegate.
     * @param _endpoint The address of the LOCAL LayerZero endpoint.
     * @param _delegate The delegate capable of making OApp configurations inside of the endpoint.
     */
    function initialize(
        address _endpoint,
        address _delegate
    ) public initializer {
        __OAppCore_init(_endpoint, _delegate); // Initialize the parent OAppCore contract
    }

    /**
     * @notice Sends a message from the source chain to a destination chain.
     * @param _dstEid The endpoint ID of the destination chain.
     * @param _message The message string to be sent.
     * @param _options Additional options for message execution.
     * @dev Encodes the message as bytes and sends it using the `_lzSend` internal function.
     * @return receipt A `MessagingReceipt` struct containing details of the message sent.
     */
    function send(
        uint32 _dstEid,
        string memory _message,
        bytes calldata _options
    ) external payable returns (MessagingReceipt memory receipt) {
        bytes memory _payload = abi.encode(_message);
        receipt = _lzSend(
            _dstEid,
            _payload,
            _options,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    }

    /**
     * @notice Retrieves the OApp version information.
     * @return senderVersion The version of the OAppSender.sol implementation.
     * @return receiverVersion The version of the OAppReceiver.sol implementation.
     */
    function oAppVersion()
        public
        pure
        virtual
        override(OAppUpgradeable)
        returns (uint64 senderVersion, uint64 receiverVersion)
    {
        return OAppUpgradeable.oAppVersion();
    }

    /**
     * @dev A simple function for V2, this will be updated in V2.
     * @return string Message from V2 contract.
     */
    function versionedFunction() public pure virtual returns (string memory) {
        return "This is OApp V2";
    }

    /**
     * @notice Quotes the gas needed to pay for the full omnichain transaction in native gas or ZRO token.
     * @param _dstEid Destination chain's endpoint ID.
     * @param _message The message.
     * @param _options Message execution options (e.g., for sending gas to destination).
     * @param _payInLzToken Whether to return fee in ZRO token.
     * @return fee A `MessagingFee` struct containing the calculated gas fee in either the native token or ZRO token.
     */
    function quote(
        uint32 _dstEid,
        string memory _message,
        bytes memory _options,
        bool _payInLzToken
    ) public view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(_message);
        fee = _quote(_dstEid, payload, _options, _payInLzToken);
    }

    /**
     * @dev Receives messages from LayerZero. Implements `_lzReceive` from `OAppReceiver`.
     * @param _origin The origin chain and sender details.
     * @param _guid A globally unique identifier for the message.
     * @param _message The message payload (expected to be a simple string).
     * @param _executor The address executing the message.
     * @param _extraData Additional data for execution.
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual override {
        // Assuming the message payload is a string, we decode the payload
        string memory receivedMessage = abi.decode(_message, (string));

        // Store the received message and origin details
        lastReceivedMessage = receivedMessage;
        lastReceivedSrcEid = _origin.srcEid;
        lastSender = _origin.sender;

        // You can add additional logic here to process the received message
        emit MessageReceived(
            _origin.srcEid,
            bytes32(_origin.sender),
            receivedMessage
        );
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override onlyOwner {} // solhint-disable-line
}
