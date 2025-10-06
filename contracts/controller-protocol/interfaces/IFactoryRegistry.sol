// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

/**
 * @title Fatory Registry contract
 * @dev Main registry of addresses part of pool creation components, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Trava
 * @author Trava
 **/
interface IFactoryRegistry {
    event ConfigurationAdminUpdated(uint256 providerId, address indexed newAddress);
    event EmergencyAdminUpdated(uint256 providerId, address indexed newAddress);
    event AddressesProviderUpdated(address indexed newAddress);
    event UniversalMessengerUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function setAddress(bytes32 id, address newAddress) external;
    function getAddress(bytes32 id) external view returns (address);

    function getAddressesProvider() external view returns (address);
    function setAddressesProviderImpl(address addressesProvider) external;

    function getUniversalMessenger() external view returns (address);
    function setUniversalMessengerImpl(address universalMessenger) external;
}