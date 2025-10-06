// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

import {BaseImmutableAdminUpgradeabilityProxy} from '../libraries/upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol';
import {IFactoryRegistry} from "../interfaces/IFactoryRegistry.sol";

contract FactoryRegistry is IFactoryRegistry {
    mapping(bytes32 => address) private _addresses;

    address private governance;

    bytes32 private constant ADDRESSES_PROVIDER  = "ADDRESSES_PROVIDER";
    bytes32 private constant UNIVERSAL_MESSENGER = "UNIVERSAL_MESSENGER";

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
        require(address(governance) == msg.sender, "onlyGovernance: caller is not the governance");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_governance`).
     * Can only be called by the current owner.
     */
    function transferGovernance(address _governance) public virtual onlyGovernance {
        require(
            _governance != address(0),
            "transferGovernance: new governance is the zero address"
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
     * @dev Returns the address of the UniversalMessenger proxy
     * @return The UniversalMessenger proxy address
     **/
    function getUniversalMessenger() external view override returns (address) {
        return getAddress(UNIVERSAL_MESSENGER);
    }

    /**
     * @dev Updates the implementation of the UniversalMessenger, or creates the proxy
     * setting the new `UniversalMessenger` implementation on the first time calling it
     * @param universalMessenger The new universalMessenger implementation
     **/
    function setUniversalMessengerImpl(address universalMessenger) external override onlyGovernance {
        _updateImpl(UNIVERSAL_MESSENGER, universalMessenger);
        emit UniversalMessengerUpdated(universalMessenger);
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