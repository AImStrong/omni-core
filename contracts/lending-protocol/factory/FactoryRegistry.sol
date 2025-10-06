// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {BaseImmutableAdminUpgradeabilityProxy} from '../libraries/upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol';
import {IFactoryRegistry} from "../interfaces/IFactoryRegistry.sol";
import {IConnectedMessenger} from "../interfaces/IConnectedMessenger.sol";

/**
 * @title Fatory Registry contract
 * @dev Main registry of addresses part of pool creation components, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Trava
 * @author Trava
 **/
contract FactoryRegistry is IFactoryRegistry {
    mapping(bytes32 => address) private _addresses;

    address private governance;

    bytes32 private constant ADDRESSES_PROVIDER    = "ADDRESSES_PROVIDER";
    bytes32 private constant INTEREST_RATE_FACTORY = "INTEREST_RATE_FACTORY";
    bytes32 private constant CONNECTED_MESSENGER   = "CONNECTED_MESSENGER";

    event GovernanceTransferred(
        address indexed previousGovernance,
        address indexed newGovernance
    );

    constructor(address _governance) {
        governance = _governance;
        emit GovernanceTransferred(address(0), address(_governance));
    }

    function getGovernance() public view returns (address) {
        return address(governance);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(address(governance) == msg.sender, "Caller not governance");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_governance`).
     * Can only be called by the current owner.
     */
    function transferGovernance(address _governance) public virtual onlyGovernance {
        require(
            _governance != address(0),
            "Governance cannot be 0 address"
        );
        emit GovernanceTransferred(address(governance), address(_governance));
        governance = _governance;
    }

    /**
     * @dev Sets an address for an id replacing the address saved in the addresses map
     * IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress) external override onlyGovernance {
        _addresses[id] = newAddress;
        emit AddressSet(id, newAddress, false);
    }

    /**
     * @dev Returns an address by id
     * @return The address
     */
    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
    }

    /**
     * @dev Returns the address of the AddressesProvider proxy
     * @return The AddressesProvider proxy address
     **/
    function getAddressesProvider() external view override returns (address) {
        return getAddress(ADDRESSES_PROVIDER);
    }

    /**
     * @dev Updates the implementation of the AddressesProvider, or creates the proxy
     * setting the new `AddressesProvider` implementation on the first time calling it
     * @param addressesProviderAddress The new addressesProvider implementation
     **/
    function setAddressesProviderImpl(address addressesProviderAddress) external override onlyGovernance {
        _updateImpl(ADDRESSES_PROVIDER, addressesProviderAddress);
        emit AddressesProviderUpdated(addressesProviderAddress);
    }

    /**
     * @dev Returns the address of the InterestRateFactory proxy
     * @return The InterestRateFactory proxy address
     **/
    function getInterestRateFactory() external view override returns (address) {
        return getAddress(INTEREST_RATE_FACTORY);
    }

    /**
     * @dev Updates the implementation of the InterestRateFactory, or creates the proxy
     * setting the new `InterestRateFactory` implementation on the first time calling it
     * @param interestRateFactory The new interestRateFactory implementation
     **/
    function setInterestRateFactoryImpl(address interestRateFactory) external override onlyGovernance {
        _updateImpl(INTEREST_RATE_FACTORY, interestRateFactory);
        emit InterestRateFactoryUpdated(interestRateFactory);
    }

    /**
     * @dev Returns the address of the ConnectedMessenger proxy
     * @return The ConnectedMessenger proxy address
     */
    function getConnectedMessenger() external view override returns (address) {
        return getAddress(CONNECTED_MESSENGER);
    }

    /**
     * @dev Updates the implementation of the ConnectedMessenger, or creates the proxy
     * setting the new `ConnectedMessenger` implementation on the first time calling it
     * @param connectedMessenger The new connectedMessenger implementation
     * @param _governance set governance for connected messenger
     */
    function setConnectedMessengerImpl(
        address connectedMessenger, 
        address _governance
    ) external override onlyGovernance {
        _updateImpl(CONNECTED_MESSENGER, connectedMessenger);
        IConnectedMessenger(payable(connectedMessenger)).setGovernance(_governance);
        emit ConnectedMessengerUpdated(connectedMessenger);
    }

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
        address payable proxyAddress = payable(_addresses[id]);
        BaseImmutableAdminUpgradeabilityProxy proxy =
            BaseImmutableAdminUpgradeabilityProxy(proxyAddress);

        if (proxyAddress == address(0)) {
            proxy = new BaseImmutableAdminUpgradeabilityProxy(address(this));
            proxy.upgradeTo(newAddress);
            _addresses[id] = address(proxy);
            emit ProxyCreated(id, address(proxy));
        } else {
            proxy.upgradeTo(newAddress);
        }
    }
}