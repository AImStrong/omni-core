// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

/**
 * @title AddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Trava Governance
 * @author Trava
 **/
interface IAddressesProvider {

    event PoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event PoolConfiguratorUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);
    event PoolConfigured(address pool);
    event ConnectedMessengerUpdated(address indexed newAddress);
    event UniversalMessengerUpdated(address indexed newAddress);
	event WethUpdated(address indexed newAddress);

	function initPool(
		address pool,
		address configurator
	) external;

	function setAddress(bytes32 id, address newAddress) external;
	function getAddress(bytes32 id) external view returns (address);

	function getPool() external view returns (address);
	function setPoolImpl(address pool) external;

	function setPoolUpdateController(address _poolUpdateController) external;
	function getPoolUpdateController() external view returns (address);

	function getPoolConfigurator() external view returns (address);
	function setPoolConfiguratorImpl(address configurator) external;

	function getPoolOwner() external view returns (address);

	function getGovernance() external view returns (address);

	function getConnectedMessenger() external view returns (address);
	function setConnectedMessenger(address connectedMessenger) external;

	function getUniversalMessenger() external view returns (address);
	function setUniversalMessenger(address universalMessenger) external;

	function getWeth() external view returns (address);
	function setWeth(address weth) external;
}