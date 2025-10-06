// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {UserConfiguration} from "../libraries/configuration/UserConfiguration.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {IUniversalMessenger} from "../interfaces/IUniversalMessenger.sol";
/**
 * @title CrossChainLendingControllerStorage
 * @dev Storage contract for CrossChainLendingController, containing all the state variables
 */
contract CrossChainLendingControllerStorage {
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using WadRayMath for uint256;
    
    mapping(uint256 => DataTypes.PoolData) internal _pools; // chainID -> Pool : 1 chain -> 1 pool
    mapping(address => DataTypes.UserGlobalData) internal _users; // address_user -> global user data
    mapping(uint256 => uint256) internal _chainsList; // the list of the available chain, structured as a mapping for gas savings reasons
    uint256 internal _chainsCount;

    bool internal _paused;

    uint256 internal _maxNumberOfChains;
    
    IAddressesProvider internal _addressesProvider;

    IUniversalMessenger internal _messenger;
}