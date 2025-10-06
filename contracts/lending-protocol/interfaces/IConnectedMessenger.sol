// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@zetachain/protocol-contracts/contracts/evm/GatewayEVM.sol";

event RevertEvent(string, RevertContext);

/// @notice Structure of each message to be sent to Zetachain
/// @dev the header identifies what the data is for to the receiver
struct ToZetaCrossChainMessage {
	address user;
	uint8 header;
	uint256 nonce;
	bytes data;
}

/// @notice Structure of each message to be sent from Zetachain
/// @dev the header identifies what the data is for to the receiver
struct FromZetaCrossChainMessage {
	uint8 header;
	uint256 nonce;
	bytes data;
}

interface IConnectedMessenger {

	function setGovernance(address _governance) external;
	function setMinGasValue(uint256 newMinGasValue) external;
	function setGateway(address payable _gateway) external;
	function setAddressesProvider(address _addressesProvider) external;

	/**
	 * @dev Rescue token, native if token = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE
	 * @param token Address of token
	 * @param to Address of receiver
	 * @param amount Amount to receive
	 */
	function rescueTokens(address token, address to, uint256 amount) external;

	/**
	 * @dev Function to send message to contract on Zetachain with some gas
	 * @param user: address of the user who is sending the message
	 * @param receiver: address of the target contract on Zetachain
	 * @param header: identifier that tell receiver what data is
	 * @param data: arbitrary, abi encoded data to be sent to receiver
	 */
	function sendWithGas(
		address user,
		address receiver,
		uint8 header,
		bytes memory data
	) external payable;

	/**
	 * @dev Function to send message to contract on Zetachain
	 * @param user: address of the user who is sending the message
	 * @param receiver: address of the target contract on Zetachain
	 * @param header: identifier that tell receiver what data is
	 * @param data: arbitrary, abi encoded data to be sent to receiver
	 */
	function send(
		address user,
		address receiver,
		uint8 header,
		bytes memory data
	) external;

	/**
	 * @dev Decodes received message, handle data based on header
	 * @param context data receive from zeta
	 * @param message data receive from controller
	 * @return Documents the return variables of a contract’s function state variable
	 */
	function onCall(
		MessageContext calldata context,
		bytes calldata message
	) external payable returns (bytes4); 

	/**
	 * @dev handle revert, not yet implement
	 * @param revertContext data receive from zeta
	 */
	function onRevert(
		RevertContext calldata revertContext
	) external;

	receive() external payable;

	fallback() external payable;
}