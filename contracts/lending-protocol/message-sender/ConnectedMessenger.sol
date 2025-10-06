// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {RevertOptions, RevertContext} from "@zetachain/protocol-contracts/contracts/Revert.sol";
import "@zetachain/protocol-contracts/contracts/evm/interfaces/IGatewayEVM.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IAddressesProvider.sol";
import "../interfaces/IConnectedMessenger.sol";
import "../interfaces/IPool.sol";
import "../../dependencies/openzeppelin/contracts/IBEP20.sol";
import {SafeBEP20} from "../../dependencies/openzeppelin/contracts/SafeBEP20.sol";

/**
 * @title Message sender a.k.a. Messenger module to send cross chain message
 * @notice Based on Zetachain "Connected" contracts
 * @dev Uses Zetachain's GatewayEVM to send cross chain messages
 * @dev Message will be handled by target contract's "onCall" function
 * @dev Can also receive messages and reverts from GatewayEVM
 */
contract ConnectedMessenger is IConnectedMessenger {

	// ==================== Errors and Events ====================

	error Unauthorized();
	error InsufficientGas();

	event MessageSent(
		uint256 indexed inboundNonce, 
		uint256 indexed outboundNonce, 
		address user,
		uint8 header, 
		bytes data
	);
	event MessageReceived(
		uint256 indexed inboundNonce, 
		uint8 header, 
		bytes data
	);
	event MessageReceivedFailed(
		uint256 indexed inboundNonce, 
		uint8 header, 
		bytes data,
		bytes err
	);

	// ==================== Variables ====================

	using SafeERC20 for IERC20;
	using SafeBEP20 for IBEP20;

	IGatewayEVM public gateway;
	IAddressesProvider public addressesProvider;
	uint256 public MIN_GAS_VALUE;
	address public governance;

	RevertOptions private defaultRevertOptions =
		RevertOptions({
			revertAddress: address(this),
			callOnRevert: false,
			abortAddress: address(0),
			revertMessage: "0x",
			onRevertGasLimit: 5e5
		});

	uint256 public outboundNonce = 0;
	uint256 public currentInboundNonce = 0;
	mapping(uint256 inboundNonce => bool executed) public executedNonces;

	// ==================== Modifiers ====================

	modifier onlyGateway() {
		require(msg.sender == address(gateway) || msg.sender == governance, "caller not gateway");
		_;
	}

	modifier onlyPool() {
		require(msg.sender == addressesProvider.getPool() || msg.sender == governance, "caller not pool");
		_;
	}

	modifier withSufficientGas() {
		require(msg.value >= MIN_GAS_VALUE, "insufficient gas");
		_;
	}

	modifier onlyGovernance() {
        require(governance == address(0) || governance == msg.sender, "Caller not governance");
        _;
    }

	// ==================== Setter function ====================

	function setGovernance(address _governance) external override onlyGovernance {
		governance = _governance;
	}

	function setMinGasValue(uint256 newMinGasValue) external override onlyGovernance {
		MIN_GAS_VALUE = newMinGasValue;
	}

	function setGateway(address payable _gateway) external override onlyGovernance {
		gateway = IGatewayEVM(_gateway);
	}

	function setAddressesProvider(address _addressesProvider) external override onlyGovernance {
		addressesProvider = IAddressesProvider(_addressesProvider);
	}

	// ==================== Rescue tokens ====================

	function rescueTokens(address token, address to, uint256 amount) external override onlyGovernance {
		if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            (bool ok,) = to.call{value: amount}("");
            require(ok, "rescue tokens failed");
        }
        else {
            IBEP20(token).safeTransfer(to, amount);
        }
	}

	// ==================== Message sender functions ====================

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
	) external payable override onlyPool withSufficientGas {
		outboundNonce++;
		ToZetaCrossChainMessage memory message = ToZetaCrossChainMessage({
			user: user,
			header: header,
			data: data,
			nonce: outboundNonce
		});
		bytes memory payload = abi.encode(message);
		gateway.depositAndCall{value: msg.value}(
			receiver,
			payload,
			defaultRevertOptions
		);

		emit MessageSent(currentInboundNonce, outboundNonce, user,  header, data);
	}

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
	) external override onlyPool {
		outboundNonce++;
		ToZetaCrossChainMessage memory message = ToZetaCrossChainMessage({
			user: address(0),
			header: header,
			data: data,
			nonce: outboundNonce
		});
		bytes memory payload = abi.encode(message);
		gateway.call(receiver, payload, defaultRevertOptions);

		emit MessageSent(currentInboundNonce, outboundNonce, user, header, data);
	}

	/**
	 * @dev Decodes received message, handle data based on header
	 * @param context data receive from zeta
	 * @param message data receive from controller
	 * @return Documents the return variables of a contract's function state variable
	 */
	function onCall(
		MessageContext calldata context,
		bytes calldata message
	) external payable override onlyGateway returns (bytes4) {
		require(
			context.sender == addressesProvider.getUniversalMessenger(),
			"onCall caller not universal messenger"
		);

		FromZetaCrossChainMessage memory decodedMessage = abi.decode(
			message,
			(FromZetaCrossChainMessage)
		);
		
		require(
			!executedNonces[decodedMessage.nonce],
			"message already executed"
		);

		executedNonces[decodedMessage.nonce] = true;
		currentInboundNonce = decodedMessage.nonce;

		try IPool(addressesProvider.getPool()).handleInbound(
			decodedMessage.header,
			decodedMessage.data
		) {
			emit MessageReceived(decodedMessage.nonce, decodedMessage.header, decodedMessage.data);
		} catch (bytes memory err) {
			emit MessageReceivedFailed(decodedMessage.nonce, decodedMessage.header, decodedMessage.data, err);
		}

		currentInboundNonce = 0;
		
		return "";
	}

	/**
	 * @dev handle revert, not yet implement
	 * @param revertContext data receive from zeta
	 */
	function onRevert(
		RevertContext calldata revertContext
	) external onlyGateway {
		emit RevertEvent("Revert on EVM", revertContext);
	}

	receive() external payable {}

	fallback() external payable {}
}