// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import {BaseImmutableAdminUpgradeabilityProxy} from '../libraries/upgradeability/BaseImmutableAdminUpgradeabilityProxy.sol';

contract IncentivesFactory {

    // storage
    address public _governance;
    mapping(address => address) public _assetToVault;

    // modifier
    modifier onlyGovernance() {
        require(msg.sender == _governance, "caller not governance");
        _;
    }

    // constructor
    constructor(address governance_) {
        require(governance_ != address(0), "governance cannot be 0 address");
        _governance = governance_;
    }

    // setter, getter
    function setGovernance(address governance_) external onlyGovernance {
        require(governance_ != address(0), "governance cannot be 0 address");
        _governance = governance_;
    }

    function getGovernance() external view returns (address) {
        return _governance;
    }

    function setVaultImpl(address asset, address implementation) external onlyGovernance {
        // set implementation to 0 address if you want to remove vault
        _updateImpl(asset, implementation);
    }

    function getVault(address asset) external view returns (address) {
        return _assetToVault[asset];
    }

    // internal function
    function _updateImpl(address asset, address newAddress) internal {
        address payable proxyAddress = payable(_assetToVault[asset]);
        BaseImmutableAdminUpgradeabilityProxy proxy = BaseImmutableAdminUpgradeabilityProxy(proxyAddress);

        if (proxyAddress == address(0)) {
            proxy = new BaseImmutableAdminUpgradeabilityProxy(address(this));
            _assetToVault[asset] = address(proxy);
            bytes memory params = abi.encodeWithSignature("initialize(address)", address(_governance));
            proxy.upgradeToAndCall(newAddress, params);
        } else {
            proxy.upgradeTo(newAddress);
        }
    }
}