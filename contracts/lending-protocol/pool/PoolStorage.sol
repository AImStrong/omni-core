// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IPool} from "../interfaces/IPool.sol";

contract PoolStorage {

    IAddressesProvider internal _addressesProvider;

    mapping(address => DataTypes.ReserveData) internal _reserves;

    // the list of the available reserves, structured as a mapping for gas savings reasons
    mapping(uint256 => address) internal _reservesList;

    uint256 internal _maxNumberOfReserves;

    uint256 internal _reservesCount;

    bool internal _paused;
}
