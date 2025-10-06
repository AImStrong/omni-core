// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";
import {InitializableImmutableAdminUpgradeabilityProxy} from '../libraries/upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';

contract AddressesProvider is IAddressesProvider {
	// State variables
	mapping(uint256 => mapping(bytes32 => address)) private _addresses;
	uint256[] public supportedChainIds;
	uint256 private constant THIS_CHAIN_ID = 7000; // mainnet chainId
	// Constants
	bytes32 private constant GOVERNANCE                = "GOVERNANCE";
	bytes32 private constant CONTROLLER_UPDATE_MANAGER = "CONTROLLER_UPDATE_MANAGER";
	bytes32 private constant CONTROLLER_OWNER          = "CONTROLLER_OWNER";
	bytes32 private constant UNIVERSAL_MESSENGER       = "UNIVERSAL_MESSENGER";
	bytes32 private constant PRICE_ORACLE              = "PRICE_ORACLE";
	bytes32 private constant CONTROLLER_CONFIGURATOR   = "CONTROLLER_CONFIGURATOR";
	bytes32 private constant CROSS_CHAIN_CONTROLLER    = "CROSS_CHAIN_CONTROLLER";
	bytes32 private constant CONNECTED_MESSENGER       = "CONNECTED_MESSENGER";
	
	/**
	 * @dev Modifier to check if the caller is the governance
	 * If governance is not set (address(0)), allows the call
	 */
	modifier onlyGovernance() {
		address governanceAddr = getAddress(THIS_CHAIN_ID, GOVERNANCE);
		if (governanceAddr != address(0)) {
			require(msg.sender == governanceAddr, "AddressesProvider: caller is not governance");
		}
		_;
	}

	// ============ Governance Functions ============

	/**
	 * @dev Sets the governance address
	 * @param _governance The address of the new governance
	 */
	function setGovernance(address _governance) external override onlyGovernance {
		require(_governance != address(0), "AddressesProvider: zero governance address");
		_addresses[THIS_CHAIN_ID][GOVERNANCE] = address(_governance);
		emit GovernanceUpdated(_governance);
	}

	/**
	 * @dev Returns the current governance address of the Address Provider
	 * @return The address of the current governance
	 */
	function getGovernance() external view override returns(address) {
		return getAddress(THIS_CHAIN_ID, GOVERNANCE);
	}

	// ============ Controller Functions ============

	/**
	 * @dev Returns true if owner owns the controller
	 * @param owner The address to check
	 * @return True if the address is the controller owner, false otherwise
	 */
	function checkOwner(address owner) external view override returns (bool) {
		return getAddress(THIS_CHAIN_ID, CONTROLLER_OWNER) == owner;
	}
	
	/**
	 * @dev Returns the address of the CrossChainLendingController proxy
	 * @return The address of the CrossChainLendingController
	 */
	function getCrossChainLendingController() external view override returns (address) {
		return getAddress(THIS_CHAIN_ID, CROSS_CHAIN_CONTROLLER);
	}

	/**
	 * @dev Returns the address of the CrossChainLendingController owner
	 * @return The address of the controller owner
	 */
	function getControllerOwner() external view override returns (address) {
		return getAddress(THIS_CHAIN_ID, CONTROLLER_OWNER);
	}

	/**
	 * @dev Sets the address of the CrossChainLendingController owner
	 * @param owner The address of the new controller owner
	 * Requirements:
	 * - The caller must be governance
	 * - The new owner address cannot be zero
	 */
	function setControllerOwner(address owner) external override onlyGovernance {
		require(owner != address(0), " zero owner address");
		_addresses[THIS_CHAIN_ID][CONTROLLER_OWNER] = owner;
		emit ControllerOwnerUpdated(owner);
	}

	/**
	 * @dev Updates the implementation of the CrossChainLendingController
	 * @param implementation The new CrossChainLendingController implementation
	 * Requirements:
	 * - The caller must be governance
	 * - The implementation address cannot be zero
	 */
	function setCrossChainLendingControllerImpl(address implementation) external override onlyGovernance {
		require(implementation != address(0), "Invalid implementation address");
		_updateImpl(CROSS_CHAIN_CONTROLLER, implementation);
		emit CrossChainControllerUpdated(implementation);
	}

	/**
	 * @dev Returns the address of the controller configurator
	 * @return The address of the controller configurator
	 */
	function getControllerConfigurator() external view override returns (address) {
		return getAddress(THIS_CHAIN_ID, CONTROLLER_CONFIGURATOR);
	}

	/**
	 * @dev Updates the address of the controller configurator
	 * @param configurator The address of the new controller configurator
	 * Requirements:
	 * - The caller must be governance
	 * - The configurator address cannot be zero
	 */
	function setControllerConfiguratorImpl(address configurator) external override onlyGovernance {
		require(configurator != address(0), "Invalid configurator address");
		_updateImpl(CONTROLLER_CONFIGURATOR, configurator);
		emit ControllerConfiguratorUpdated(configurator);
	}

	/**
	 * @dev Returns the address of the controller update manager
	 * @return The address of the controller update manager
	 */
	function getControllerUpdateManager() external view override returns (address) {
		return getAddress(THIS_CHAIN_ID, CONTROLLER_UPDATE_MANAGER);
	}

	/**
	 * @dev Updates the address of the controller update manager
	 * @param manager The address of the new controller update manager
	 * Requirements:
	 * - The caller must be governance
	 * - The manager address cannot be zero
	 */
	function setControllerUpdateManager(address manager) external override onlyGovernance {
		require(manager != address(0), "Invalid manager address");
		_addresses[THIS_CHAIN_ID][CONTROLLER_UPDATE_MANAGER] = manager;
		emit ControllerUpdateManagerUpdated(manager);
	}

	// ============ Price Oracle Functions ============

	/**
	 * @dev Returns the address of the price oracle
	 * @return The address of the price oracle
	 */
	function getPriceOracle() external view override returns (address) {
		return getAddress(THIS_CHAIN_ID, PRICE_ORACLE);
	}

	/**
	 * @dev Updates the address of the price oracle
	 * @param oracle The address of the new PriceOracle
	 * Requirements:
	 * - The caller must be governance
	 * - The oracle address cannot be zero
	 */
	function setPriceOracle(address oracle) external override onlyGovernance {
		require(oracle != address(0), "Invalid oracle address");
		_addresses[THIS_CHAIN_ID][PRICE_ORACLE] = oracle;
		emit PriceOracleUpdated(oracle);
	}

	// ============ Connected Messenger Functions ============

	/**
	 * @dev Sets addresses for multiple connected messengers on specific chains
	 * @param chainIds The array of chain IDs
	 * @param messengerAddrs The array of connected messenger addresses
	 * Requirements:
	 * - The caller must be governance
	 * - The arrays must have the same length
	 * - None of the messenger addresses can be zero
	 */
	function setConnectedMessengersForChains(
		uint256[] calldata chainIds,
		address[] calldata messengerAddrs
	) external onlyGovernance {
		require(chainIds.length == messengerAddrs.length, "Arrays length mismatch");
		for (uint256 i = 0; i < chainIds.length; i++) {
			_setConnectedMessengerForChain(chainIds[i], messengerAddrs[i]);
		}
	}

	/**
	 * @dev Get connected messenger address for specific chain
	 * @param chainId The chain ID
	 * @return The connected messenger address for the specified chain
	 */
	function getConnectedMessengerForChain(uint256 chainId) external view override returns (address) {
		return getAddress(chainId, CONNECTED_MESSENGER);
	}

	/**
	 * @dev Get all supported chain IDs
	 * @return Array of supported chain IDs
	 */
	function getSupportedChainIds() external view override returns (uint256[] memory) {
		return supportedChainIds;
	}

	// ============ Universal Messenger Functions ============

	/**
	 * @dev Sets the universal messenger address
	 * @param newMessenger The address of the new universal messenger
	 * Requirements:
	 * - The caller must be the owner
	 * - The new messenger address cannot be zero
	 */
	function setUniversalMessenger(address newMessenger) external override onlyGovernance {
		require(newMessenger != address(0), "AddressesProvider: zero messenger address");
		_addresses[THIS_CHAIN_ID][UNIVERSAL_MESSENGER] = newMessenger;
		emit UniversalMessengerUpdated(newMessenger);
	}

	/**
	 * @dev Returns the current universal messenger address
	 * @return The address of the current universal messenger
	 */
	function getUniversalMessenger() external view override returns (address) {
		return getAddress(THIS_CHAIN_ID, UNIVERSAL_MESSENGER);
	}

	// ============ Helper Functions ============

	/**
	 * @dev Sets an address for a given chain ID and identifier
	 * @param chainId The chain ID
	 * @param id The identifier
	 * @param addr The address to set
	 * Requirements:
	 * - The caller must be the owner
	 */
	function setAddress(uint256 chainId, bytes32 id, address addr) public override onlyGovernance {
		_addresses[chainId][id] = addr;
		emit AddressSet(chainId, id, addr, true);
	}

	/**
	 * @dev Internal function to get an address for a given chain ID and identifier
	 * @param chainId The chain ID
	 * @param id The identifier
	 * @return The stored address
	 */
	function getAddress(uint256 chainId, bytes32 id) public view override returns (address) {
		return _addresses[chainId][id];
	}

	/**
	 * @dev Sets a connected messenger address for a specific chain
	 * @param chainId The chain ID
	 * @param messengerAddr The messenger address
	 * Requirements:
	 * - The messenger address cannot be zero
	 */
	function _setConnectedMessengerForChain(uint256 chainId, address messengerAddr) internal {
		require(messengerAddr != address(0), "AddressesProvider: zero messenger address");
		
		if (_addresses[chainId][CONNECTED_MESSENGER] == address(0)) {
			supportedChainIds.push(chainId);
		}
		setAddress(chainId, CONNECTED_MESSENGER, messengerAddr);
		emit ConnectedMessengerUpdated(chainId, messengerAddr);
	}

	/**
	 * @dev Initializes the core protocol contracts by creating proxies and setting addresses
	 * @param controller The implementation address for the CrossChainLendingController
	 * @param priceOracle The address of the price oracle contract
	 * @param configurator The implementation address for the ControllerConfigurator
	 */
	function initController(address controller, address priceOracle, address configurator) external override onlyGovernance {
		_addresses[THIS_CHAIN_ID][CONTROLLER_OWNER] = msg.sender;
		_updateImpl(CROSS_CHAIN_CONTROLLER, controller);
		_addresses[THIS_CHAIN_ID][PRICE_ORACLE] = priceOracle;
		_updateImpl(CONTROLLER_CONFIGURATOR, configurator);
		
		emit ControllerConfigured(controller);
		emit ControllerUpdated(controller);
		emit PriceOracleUpdated(priceOracle);
		emit ControllerConfiguratorUpdated(configurator);
	}

	/**
	 * @dev Internal function to update the implementation of a specific proxied component
	 * @param id The id of the proxy to be updated
	 * @param newAddress The address of the new implementation
	 */
	function _updateImpl(bytes32 id, address newAddress) internal {
		address payable proxyAddress = payable(_addresses[THIS_CHAIN_ID][id]);
		InitializableImmutableAdminUpgradeabilityProxy proxy =
			InitializableImmutableAdminUpgradeabilityProxy(proxyAddress);

		bytes memory params = abi.encodeWithSignature(
			"initialize(address)",
			address(this)
		);

		if (proxyAddress == address(0)) {
			proxy = new InitializableImmutableAdminUpgradeabilityProxy(
				address(this)
			);
			proxy.initialize(newAddress, params);
			_addresses[THIS_CHAIN_ID][id] = address(proxy);
			emit ProxyCreated(id, address(proxy));
		} else {
			proxy.upgradeToAndCall(newAddress, params);
		}
	}
} 