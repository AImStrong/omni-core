// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@zetachain/protocol-contracts/contracts/zevm/interfaces/IGatewayZEVM.sol";

interface IUniversalMessenger {

	struct ToZetaCrossChainMessage {
		address user;
		uint8 header;
		uint256 nonce;
		bytes data;
	}

	struct FromZetaCrossChainMessage {
		uint8 header;
		uint256 nonce;
		bytes data;
	}

	event MessageReceived(
		uint256 indexed inboundNonce,
		uint256 indexed chainId, 
		address user, 
		uint8 header
	);
	event MessageSent(
		uint256 indexed inboundNonce,
		uint256 indexed outboundNonce,
		uint256 indexed chainId,
		address user,
		uint8 header,
		address receiver
	);
	event MessageReceivedFailed(
		uint256 indexed inboundNonce,
		uint256 indexed chainId, 
		address user, 
		uint8 header,
		bytes error, 
		ToZetaCrossChainMessage message, 
		bytes32 messageHash
	);
	event LiquidationPhase3Failed(
		uint256 indexed inboundNonce,
		uint256 indexed chainId,
		address indexed user,
		bytes data,
		bytes32 messageHash,
		uint256 countId,
		bytes error
	);
	event MessageRetryFailed(
		uint256 indexed chainId,
		uint256 countId, 
		bytes error
	);
	event MessageRetrySucceeded(
		uint256 indexed chainId, 
		uint256 countId
	);
	error Unauthorized(); 
	error InvalidAddress();
	error ApprovalFailed();
	error NotGasToken();
	error InsufficientAmount(string);

	function setGateway(address payable _gateway) external;
	function setSystemContract(address _systemContract) external;
	function setAddressesProvider(address _addressesProvider) external;
	function setGasLimit(uint256 _gasLimit) external;
	function setController(address _controller) external;
	function setGovernance(address _governance) external;

	function send(
		uint256 chainID,
		uint8 header,
		address user,
		bytes calldata data
	) external;
}