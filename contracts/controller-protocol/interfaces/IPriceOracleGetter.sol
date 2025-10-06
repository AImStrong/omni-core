// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

interface IPriceOracleGetter {
    function getAssetPrice(address asset) external view returns (uint256);
}