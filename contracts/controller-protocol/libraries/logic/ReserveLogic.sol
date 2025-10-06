// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

import {SafeMath} from "../../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IBEP20} from "../../../dependencies/openzeppelin/contracts/IBEP20.sol";
import {SafeBEP20} from "../../../dependencies/openzeppelin/contracts/SafeBEP20.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {MathUtils} from "../math/MathUtils.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title ReserveLogic library
 * @notice Implements the logic to update the reserves state
 */
library ReserveLogic {
    using SafeMath for uint256;
    using WadRayMath for uint256;

    using PercentageMath for uint256;
    using SafeBEP20 for IBEP20;

    event ReserveDataUpdated(
        uint sourceChainId,
        address indexed asset,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex,
        uint256 newBalanceOfUnderlyingAsset,
        uint256 lastUpdateTimestamp,
        uint256 lastUpdateTimestampConnectedChain
    );

    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    /**
     * @dev Returns the ongoing normalized income for the reserve
     * A value of 1e27 means there is no income. As time passes, the income is accrued
     * A value of 2*1e27 means for each unit of asset one unit of income has been accrued
     * @param reserve The reserve object
     * @return the normalized income. expressed in ray
     **/
    function getNormalizedIncome(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
        uint40 timestamp = reserve.lastUpdateTimestamp;

        //solium-disable-next-line
        if (timestamp == uint40(block.timestamp)) {
            //if the index was updated in the same block, no need to perform any calculation
            return reserve.liquidityIndex;
        }

        uint256 cumulated = MathUtils.calculateLinearInterest(reserve.currentLiquidityRate, timestamp)
                                    .rayMul(reserve.liquidityIndex);
        return cumulated;
    }

    /**
     * @dev Returns the ongoing normalized variable debt for the reserve
     * A value of 1e27 means there is no debt. As time passes, the income is accrued
     * A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
     * @param reserve The reserve object
     * @return The normalized variable debt. expressed in ray
     **/
    function getNormalizedDebt(DataTypes.ReserveData storage reserve) internal view returns (uint256) {
        uint40 timestamp = reserve.lastUpdateTimestamp; //should we use lastUpdateTimestamp or lastUpdateTimestampConnectedChain? 
        //solium-disable-next-line
        if (timestamp == uint40(block.timestamp)) {
            //if the index was updated in the same block, no need to perform any calculation
            return reserve.variableBorrowIndex;
        }

        uint256 cumulated = MathUtils.calculateCompoundedInterest(reserve.currentVariableBorrowRate, timestamp)
                                    .rayMul(reserve.variableBorrowIndex);
        return cumulated;
    }

    /**
     * @dev Updates the complete state of the reserve
     * @param reserve The reserve object
     * @param sourceChainId The source chain ID
     * @param asset The address of the underlying asset of the reserve
     * @param newLiquidityIndex The new liquidity index
     * @param newVariableBorrowIndex The new variable borrow index
     * @param newLiquidityRate The new liquidity rate
     * @param newVariableBorrowRate The new variable borrow rate
     * @param newBalanceOfUnderlyingAsset The new balance of the underlying asset
     **/
    function updateCompleteState(
        DataTypes.ReserveData storage reserve,
        uint256 sourceChainId,
        address asset,
        uint256 newLiquidityIndex,
        uint256 newVariableBorrowIndex,
        uint256 newLiquidityRate,
        uint256 newVariableBorrowRate,
        uint256 newBalanceOfUnderlyingAsset,
        uint40  newLastUpdateTimestampConnectedChain
    ) internal {

        // Update indices and rates
        if(newLastUpdateTimestampConnectedChain > reserve.lastUpdateTimestampConnectedChain){
            reserve.liquidityIndex = uint128(newLiquidityIndex);
            reserve.variableBorrowIndex = uint128(newVariableBorrowIndex);
            reserve.currentLiquidityRate = uint128(newLiquidityRate);
            reserve.currentVariableBorrowRate = uint128(newVariableBorrowRate);
            reserve.balanceOfUnderlyingAsset = newBalanceOfUnderlyingAsset;
            reserve.lastUpdateTimestamp = uint40(block.timestamp);
            reserve.lastUpdateTimestampConnectedChain = newLastUpdateTimestampConnectedChain;
        }
       
        DataTypes.ReserveData memory cachedReserve = reserve; // for gas saving

        emit ReserveDataUpdated(
            sourceChainId,
            asset,
            cachedReserve.currentLiquidityRate,
            cachedReserve.currentVariableBorrowRate,
            cachedReserve.liquidityIndex,
            cachedReserve.variableBorrowIndex,
            cachedReserve.balanceOfUnderlyingAsset,
            cachedReserve.lastUpdateTimestamp,
            cachedReserve.lastUpdateTimestampConnectedChain
        );
    }
}