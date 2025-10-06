// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {Ownable} from "../../dependencies/openzeppelin/contracts/Ownable.sol";
import {InitializableImmutableAdminUpgradeabilityProxy} from '../libraries/upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';
import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";

/**
 * @title PoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Trava Governance
 * @author Trava
 **/
contract AddressesProvider is Ownable, IAddressesProvider {

    // State variables
	address private governance;
	address private poolUpdateController;

	// Mappings
	// (identifier => registeredAddress)
	mapping(bytes32 => address) private _addresses;
	mapping(address => uint256[]) public userProviders;

	// Identifiers
	bytes32 private constant POOL                      = "POOL";
	bytes32 private constant POOL_CONFIGURATOR         = "POOL_CONFIGURATOR";
	bytes32 private constant POOL_OWNER                = "POOL_OWNER";
	bytes32 private constant LENDING_RATE_ORACLE       = "LENDING_RATE_ORACLE";
	bytes32 private constant CONNECTED_MESSENGER       = "CONNECTED_MESSENGER";
	bytes32 private constant UNIVERSAL_MESSENGER       = "UNIVERSAL_MESSENGER";
	bytes32 private constant WETH 					   = "WETH";
	bytes32 private constant INCENTIVES_FACTORY 	   = "INCENTIVES_FACTORY";

	modifier OnlyGovernance() {
		if (address(governance) != address(0)) {
			require(
				address(governance) == msg.sender,
				"Caller not governance"
			);
		}
		_;
	}

	// ============ Governance Functions ============

	/**
	 * @dev Set the Governance address for the Address Provider Factory
	 * Only governance has the authority
	 * @param _governance Governance address
	 **/
	function setGovernance(address _governance) external OnlyGovernance {
		require(address(_governance) != address(0), "governance cannot be 0 address");
		governance = _governance;
	}

	/**
	 * @dev Get the Governance address of the Address Provider Factory
	 * @return The Governance address
	 **/
	function getGovernance() external override view returns (address) {
		return address(governance);
	}

	// ============ Pool Functions ============

	/**
	 * @dev create Proxy and set Pool
	 * Collateral Manager for Pool
	 * @param pool The address of logic implementation of Pool
	 * @param poolConfigurator The address of logic implementation of Pool Configurator
	 **/
	function initPool(
		address pool,
		address poolConfigurator
	) external override OnlyGovernance() {
		_addresses[POOL_OWNER] = msg.sender;
		_updateImpl(POOL, pool);
		_updateImpl(POOL_CONFIGURATOR, poolConfigurator);

		emit PoolConfigured(pool);
		emit PoolUpdated(pool);
		emit PoolConfiguratorUpdated(poolConfigurator);
	}

	/**
	 * @dev Set the Pool Update Controlelr address for the Address Provider
	 * Only governance has the authority
	 * @param _poolUpdateController The Pool Update Controlelr address
	 **/
	function setPoolUpdateController(address _poolUpdateController) external override OnlyGovernance {
		require(_poolUpdateController != address(0), "pool update controller cannot be 0 address");
		poolUpdateController = _poolUpdateController;
	}

	/**
	 * @dev Get the Pool Update Controller address for the Address Provider
	 * @return The Pool Update Controller address
	 **/
	function getPoolUpdateController() external view override returns (address) {
		return poolUpdateController;
	}

	/**
	 * @dev Returns the address of the Pool proxy
	 * @return The Pool proxy address
	 **/
	function getPool() external override view returns (address) {
		return getAddress(POOL);
	}

	/**
	 * @dev Updates the implementation of the Pool, or creates the proxy
	 * setting the new `pool` implementation on the first time calling it
	 * Only governance has the authority
	 * @param pool The new Pool implementation
	 **/
	function setPoolImpl(address pool) external override OnlyGovernance {
		_updateImpl(POOL, pool);
		emit PoolUpdated(pool);
	}

	/**
	 * @dev Returns the address of the PoolConfigurator proxy
	 * @return The PoolConfigurator proxy address
	 **/
	function getPoolConfigurator() external view override returns (address) {
		return getAddress(POOL_CONFIGURATOR);
	}

	/**
	 * @dev Updates the implementation of the PoolConfigurator, or creates the proxy
	 * setting the new `configurator` implementation on the first time calling it
	 * Only governance has the authority
	 * @param poolConfigurator The new PoolConfigurator implementation
	 **/
	function setPoolConfiguratorImpl(address poolConfigurator) external override OnlyGovernance {
		_updateImpl(POOL_CONFIGURATOR, poolConfigurator);
		emit PoolConfiguratorUpdated(poolConfigurator);
	}

	/**
	 * @dev Get the Pool Owner of a Pool
	 * @return The address of the Pool Owner
	 **/
	function getPoolOwner() external view override returns (address) {
		return getAddress(POOL_OWNER);
	}

	// ============ WETH ============

	function getWeth() external view override returns (address) {
		return getAddress(WETH);
	}

	function setWeth(address weth) external override OnlyGovernance {
		_addresses[WETH] = weth;
		emit WethUpdated(weth);
	}

	// ============ Messenger Functions ============

	function setConnectedMessenger(address connectedMessenger) external override OnlyGovernance {
		_addresses[CONNECTED_MESSENGER] = connectedMessenger;
		emit ConnectedMessengerUpdated(connectedMessenger);
	}

	function getConnectedMessenger() external view override returns (address) {
		return getAddress(CONNECTED_MESSENGER);
	}

	function getUniversalMessenger() external view override returns (address) {
		return getAddress(UNIVERSAL_MESSENGER);
	}

	function setUniversalMessenger(address universalMessenger) external override OnlyGovernance {
		_addresses[UNIVERSAL_MESSENGER] = universalMessenger;
		emit UniversalMessengerUpdated(universalMessenger);
	}

	// ============ Internal Functions ============

	/**
	 * @dev Internal function to update the implementation of a specific proxied component of the protocol
	 * - If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
	 *   as implementation and calls the initialize() function on the proxy
	 * - If there is already a proxy registered, it just updates the implementation to `newAddress` and
	 *   calls the initialize() function via upgradeToAndCall() in the proxy
	 * @param id The id of the proxy to be updated
	 * @param newAddress The address of the new implementation
	 **/
	function _updateImpl(bytes32 id, address newAddress) internal {
		address proxyAddress = _addresses[id];
		InitializableImmutableAdminUpgradeabilityProxy proxy;

		bytes memory params = abi.encodeWithSignature(
			"initialize(address)",
			address(this)
		);

		if (proxyAddress == address(0)) {
			proxy = new InitializableImmutableAdminUpgradeabilityProxy(
				address(this)
			);

			proxy.initialize(newAddress, params);
			
			_addresses[id] = address(proxy);
			emit ProxyCreated(id, address(proxy));
		} else {
			proxy = InitializableImmutableAdminUpgradeabilityProxy(payable(proxyAddress));
			proxy.upgradeToAndCall(newAddress, params);
		}
	}

	// ============ Utility Functions ============

	/**
	 * @dev Sets an address for an id replacing the address saved in the addresses map
	 * IMPORTANT Use this function carefully, as it will do a hard replacement
	 * Only governance has the authority
	 * @param id The id
	 * @param newAddress The address to set
	 **/
	function setAddress(bytes32 id, address newAddress) external override OnlyGovernance {
		_addresses[id] = newAddress;
		emit AddressSet(id, newAddress, true);
	}

	/**
	 * @dev Returns an address by id and providerId
	 * @param id The id
	 * @return The address
	 **/
	function getAddress(bytes32 id) public view override returns (address) {
		return _addresses[id];
	}
}