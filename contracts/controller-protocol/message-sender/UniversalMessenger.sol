// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {RevertContext, RevertOptions} from "@zetachain/protocol-contracts/contracts/Revert.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/UniversalContract.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/IGatewayZEVM.sol";
import "@zetachain/protocol-contracts/contracts/zevm/GatewayZEVM.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/ISystem.sol";
import {ICrossChainLendingController} from "../interfaces/ICrossChainLendingController.sol";
import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";
import {IUniversalMessenger} from "../interfaces/IUniversalMessenger.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

/// @title UniversalMessenger contract
/// @notice This contract demonstrate how cross chain messages can be handled
/// @dev To be deployed on Zetachain, performs actions in response to onCall
contract UniversalMessenger is UniversalContract, IUniversalMessenger{

	// ==================== Variables ====================
	GatewayZEVM public gateway;
	ISystem public systemContract;
	IAddressesProvider public addressesProvider;
	uint256 public gasLimit;
	ICrossChainLendingController public controller;
	address public governance;

	mapping(uint256 chainId => uint256 nonce) outboundNonce;
	mapping(uint256 chainId => mapping(uint256 nonce => bool executed)) public receivedNonces;
	mapping(address => mapping(address => uint256)) public userGasBalances; // user => gasToken => balance
	mapping(uint256 chainId => mapping(uint256 nonce => bytes32 messageHash)) public failedMessages;

	// Mapping to track failed liquidation call phase 3 messages
	// chainId => counter => (user, messageHash, timestamp)
	mapping(uint256 => mapping(uint256 => bytes32)) public failedLiquidationPhase3Messages;
	mapping(uint256 => uint256) public failedLiquidationPhase3Count;

	// inbound nonce for tracking tx from connected chain
	uint256 currentInboundNonce = 0;

	// ==================== Modifiers ====================
	modifier onlyController() {
		if (msg.sender != addressesProvider.getCrossChainLendingController()) revert Unauthorized();
		_;
	}

	modifier onlyGateway() {
		if (msg.sender != address(gateway)) revert Unauthorized();
		_;
	}

	modifier onlyGovernance() {
		if (governance != address(0) && governance != msg.sender) revert Unauthorized();
		_;
	}

	modifier onlyGatewayorGorvernance() {
		if (msg.sender != address(gateway) && msg.sender != governance) revert Unauthorized();
		_;
	}

	// ==================== Setter getter functions ====================
	function setGateway(address payable _gateway) external onlyGovernance {
		if (_gateway == address(0)) revert InvalidAddress();
		gateway = GatewayZEVM(_gateway);
	}

	function setSystemContract(address _systemContract) external onlyGovernance {
		if (_systemContract == address(0)) revert InvalidAddress();
		systemContract = ISystem(_systemContract);
	}

	function setAddressesProvider(address _addressesProvider) external onlyGovernance {
		if (_addressesProvider == address(0)) revert InvalidAddress();
		addressesProvider = IAddressesProvider(_addressesProvider);
	}

	function setGasLimit(uint256 _gasLimit) external onlyGovernance {
		gasLimit = _gasLimit;
	}

	function setController(address _controller) external onlyGovernance {
		if (_controller == address(0)) revert InvalidAddress();
		controller = ICrossChainLendingController(_controller);
	}

	function setGovernance(address _governance) external onlyGovernance {
		if (_governance == address(0)) revert InvalidAddress();
		governance = _governance;
	}

	// Add function to check user's gas balance
	function getUserGasBalance(address user, address gasToken) external view returns (uint256) {
		return userGasBalances[user][gasToken];
	}

	// ==================== Message sender functions ====================

	/// @notice Cross chain message entry point
	/// @dev abi decode message upon arrival and act according to header
	function onCall(
		MessageContext calldata context,
		address zrc20,
		uint256 amount,
		bytes calldata message
	) external override onlyGatewayorGorvernance {
		// check if the sender is the connected messenger for the chain
		if (context.sender != addressesProvider.getConnectedMessengerForChain(context.chainID)) revert Unauthorized();
	
		ToZetaCrossChainMessage memory decodedMessage = abi.decode(
			message,
			(ToZetaCrossChainMessage)
		);
		// Add gas amount to user's balance if user address is not zero
		if (decodedMessage.user != address(0)) {
			userGasBalances[decodedMessage.user][zrc20] += amount;
		}

		require(
			!receivedNonces[context.chainID][decodedMessage.nonce],
			"Message already received"
		);

		receivedNonces[context.chainID][decodedMessage.nonce] = true;
		currentInboundNonce = decodedMessage.nonce;

		try controller.handleInbound( // add try catch so that if the message is not handled, it will not be reverted
			context.chainID,
			decodedMessage.header,
			decodedMessage.data
		) {
			emit MessageReceived(decodedMessage.nonce, context.chainID, decodedMessage.user, decodedMessage.header);
		} catch (bytes memory err) {
			// Don't revert so the message can be tracked as failedMore actions
			bytes32 messageHash = keccak256(abi.encode(message));
			failedMessages[context.chainID][decodedMessage.nonce] = messageHash;
			emit MessageReceivedFailed(
				decodedMessage.nonce,
				context.chainID,
				decodedMessage.user,
				decodedMessage.header,
				err,
				decodedMessage,
				messageHash
			);
		}

		currentInboundNonce = 0;
	}

	/// @notice Sends a cross-chain message to a specified receiver.
	/// @dev Encodes the message and attempts to send it via the gateway contract.
	/// If the call fails when call liquidation phase3, an error message is emitted.
	/// @param chainID the identifier number of the destination chain.
	/// @param header The message header containing metadata.
	/// @param data The payload data to be sent along with the message.
	function send(
		uint256 chainID,
		uint8 header,
		address user,
		bytes memory data
	) external onlyController {
		address zrc20 = systemContract.gasCoinZRC20ByChainId(chainID);
		
		// Only use try-catch for ProcessLiquidationCallPhase3
		if (header == uint8(DataTypes.MessageHeader.ProcessLiquidationCallPhase3)) {
			try this.handleGasPayment(zrc20, user) {
				_sendMessage(chainID, user, header, data);
			} catch (bytes memory err) {
				// Store failed message hash
				bytes32 messageHash = keccak256(abi.encode(chainID, user, data));
				uint countId = failedLiquidationPhase3Count[chainID];
				failedLiquidationPhase3Messages[chainID][countId] = messageHash;
				
				failedLiquidationPhase3Count[chainID]++;
				
				emit LiquidationPhase3Failed(
					currentInboundNonce,
					chainID,
					user,
					data,
					messageHash,
					countId,
					err
				);
			}
		} else {
			this.handleGasPayment(zrc20, user);
			_sendMessage(chainID, user, header, data);
		}
	}

	/// @notice Internal function to handle the common logic for sending messages
	/// @param chainID The destination chain identifier
	/// @param user The user address associated with the message
	/// @param header The message type identifier
	/// @param data The payload data to be sent
	function _sendMessage(
		uint256 chainID,
		address user,
		uint8 header,
		bytes memory data
	) private {
		outboundNonce[chainID]++;
		address receiver = addressesProvider.getConnectedMessengerForChain(chainID);
		address zrc20 = systemContract.gasCoinZRC20ByChainId(chainID);
		
		FromZetaCrossChainMessage memory message = FromZetaCrossChainMessage({
			header: header,
			nonce: outboundNonce[chainID],
			data: data
		});
		bytes memory payload = abi.encode(message);
		
		gateway.call(
			abi.encodePacked(receiver),
			zrc20,
			payload,
			CallOptions(gasLimit, false),
			RevertOptions(
				address(this),
				true,
				address(0),
				abi.encode(receiver, zrc20),
				gasLimit
			)
		);
		emit MessageSent(currentInboundNonce, outboundNonce[chainID], chainID, user, header, receiver);
	}

	/// @notice not yet implemented
	function onRevert(RevertContext calldata context) external onlyGateway {}

	// ==================== Retry liquidation phase 3 ====================

	/// @notice Verify if a failed liquidation phase 3 message exists and return its hash
	/// @dev Checks if the messageHash exists in the failedLiquidationPhase3Messages mapping
	/// @param chainID The chain ID where the message was sent
	/// @param countId The index of the failed message in the mapping
	/// @param user The user address associated with the message
	/// @param data The data of the failed message
	/// @return messageHash The hash of the message if valid
	function _verifyFailedMessage(
		uint256 chainID, 
		uint256 countId,
		address user,
		bytes memory data
	) private view returns (bytes32 messageHash) {
		// Check if index is within bounds
		if (countId >= failedLiquidationPhase3Count[chainID]) revert("Invalid countId");
		
		// Get the stored message hash
		bytes32 storedHash = failedLiquidationPhase3Messages[chainID][countId];
		
		// Compute the expected hash
		bytes32 computedHash = keccak256(abi.encode(
			chainID,
			user,
			data
		));
		
		// Verify the hash matches
		if (storedHash != computedHash) revert("Hash mismatch");
		
		return computedHash;
	}

	/// @notice Retry a failed liquidation call phase 3
	/// @dev Verifies the message exists in failed messages and calls the controller
	/// @param chainID The chain ID where the message was sent
	/// @param countId The index of the failed message in the mapping
	/// @param user The user address associated with the message
	/// @param data The data of the failed message
	function retryLiquidationCallPhase3(
		uint256 chainID,
		uint256 countId,
		address user,
		bytes memory data
	) external {
		// Verify the message exists and matches
		bytes32 messageHash = _verifyFailedMessage(chainID, countId, user, data);
		
		// Remove the message from the failed messages
		delete failedLiquidationPhase3Messages[chainID][countId];
		// call handler with received payload
		try controller.retryLiquidationCallPhase3(chainID, user, data) { // maybe can replace by retry without try catch block
			// emit message retry as succeeded
			emit MessageRetrySucceeded(chainID, countId);
		} catch (bytes memory err) {
			// store and emit message retry as failed
			failedLiquidationPhase3Messages[chainID][countId] = messageHash;
			emit MessageRetryFailed(chainID, countId, err);
		}
	}

	// ==================== Gas functions ====================
		
	/// @notice Handle gas payment with deposited gas token
	/// @dev Cross chain message should be called from connected with msg.value
	/// enough to cover gas fee on Zetachain (this contract)
	/// @param zrc20: address of deposited token, must be gas token
	/// @param user: address of user to check gas balance
	function handleGasPayment(address zrc20, address user) external {
		require(msg.sender == address(this), "Only callable by this contract");
		(address gasZRC20, uint256 gasFee) = IZRC20(zrc20).withdrawGasFeeWithGasLimit(gasLimit);
		if (zrc20 != gasZRC20) revert NotGasToken();

		// Check and use user's gas balance
		uint256 userBalance = userGasBalances[user][gasZRC20];
		if (userBalance < gasFee) revert InsufficientAmount("Insufficient gas balance");

		// Deduct gas fee from user's balance
		userGasBalances[user][gasZRC20] -= gasFee;

		if (!IZRC20(gasZRC20).approve(address(gateway), gasFee)) revert ApprovalFailed();
	}

	// Add function to deposit gas balance
	function depositGasBalance(uint256 chainId, uint256 amount, address onBehalfOf) external {
		if (amount == 0) revert InsufficientAmount("Amount must be greater than 0");
		if (onBehalfOf == address(0)) revert InvalidAddress();
		
		address gasToken = systemContract.gasCoinZRC20ByChainId(chainId);
		if (!IZRC20(gasToken).transferFrom(msg.sender, address(this), amount)) {
			revert ApprovalFailed();
		}
		userGasBalances[onBehalfOf][gasToken] += amount;
	}

	// Add function to withdraw unused gas balance 
	function withdrawGasBalance(uint256 chainId, uint256 amount, address to) external {
		if (amount == 0) revert InsufficientAmount("Amount must be greater than 0");
		if (to == address(0)) revert InvalidAddress();

		address gasToken = systemContract.gasCoinZRC20ByChainId(chainId);
		uint256 userBalance = userGasBalances[msg.sender][gasToken];
		uint256 withdrawAmount = amount;

		if (amount == type(uint256).max) {
			withdrawAmount = userBalance;
		} else if (userBalance < amount) {
			revert InsufficientAmount("Insufficient gas balance");
		}

		userGasBalances[msg.sender][gasToken] -= withdrawAmount;
		if (!IZRC20(gasToken).transfer(to, withdrawAmount)) {
			revert ApprovalFailed();
		}
	}

	// Add function to transfer gas balance to another user
	function transferGasBalance(uint256 chainId, uint256 amount, address to) external {
		if (amount == 0) revert InsufficientAmount("Amount must be greater than 0");
		if (to == address(0)) revert InvalidAddress();
		if (to == msg.sender) revert InvalidAddress();

		address gasToken = systemContract.gasCoinZRC20ByChainId(chainId);
		userGasBalances[msg.sender][gasToken] -= amount;
		userGasBalances[to][gasToken] += amount;
	}

	/// @notice Allows the contract to receive native tokens
	receive() external payable {}
}