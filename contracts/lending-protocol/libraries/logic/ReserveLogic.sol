// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {SafeMath} from "../../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IBEP20} from "../../../dependencies/openzeppelin/contracts/IBEP20.sol";
import {SafeBEP20} from "../../../dependencies/openzeppelin/contracts/SafeBEP20.sol";
import {ITToken} from "../../interfaces/ITToken.sol";
import {IVariableDebtToken} from "../../interfaces/IVariableDebtToken.sol";
import {IReserveInterestRateStrategy} from "../../interfaces/IReserveInterestRateStrategy.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {MathUtils} from "../math/MathUtils.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
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
        address indexed asset,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
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

        uint256 cumulated = MathUtils.calculateLinearInterest(
            reserve.currentLiquidityRate,
            timestamp
        ).rayMul(reserve.liquidityIndex);

        return cumulated;
    }

    /**
     * @dev Returns the ongoing normalized variable debt for the reserve
     * A value of 1e27 means there is no debt. As time passes, the income is accrued
     * A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
     * @param reserve The reserve object
     * @return The normalized variable debt. expressed in ray
     **/
    function getNormalizedDebt(DataTypes.ReserveData storage reserve) internal view returns (uint256)
    {
        uint40 timestamp = reserve.lastUpdateTimestamp;

        //solium-disable-next-line
        if (timestamp == uint40(block.timestamp)) {
            //if the index was updated in the same block, no need to perform any calculation
            return reserve.variableBorrowIndex;
        }

        uint256 cumulated = MathUtils.calculateCompoundedInterest(
            reserve.currentVariableBorrowRate,
            timestamp
        ).rayMul(reserve.variableBorrowIndex);

        return cumulated;
    }

    /**
     * @dev Updates the liquidity cumulative index and the variable borrow index.
     * @param reserve the reserve object
     **/
    function updateState(DataTypes.ReserveData storage reserve) internal returns (uint256) {
        uint256 scaledVariableDebt = IVariableDebtToken(reserve.variableDebtTokenAddress).scaledTotalSupply();
        uint256 previousVariableBorrowIndex = reserve.variableBorrowIndex;
        uint256 previousLiquidityIndex = reserve.liquidityIndex;
        uint40 lastUpdatedTimestamp = reserve.lastUpdateTimestamp;

        (uint256 newLiquidityIndex, uint256 newVariableBorrowIndex) = _updateIndexes(
            reserve,
            scaledVariableDebt,
            previousLiquidityIndex,
            previousVariableBorrowIndex,
            lastUpdatedTimestamp
        );

        return _mintToTreasury(
            reserve,
            scaledVariableDebt,
            previousVariableBorrowIndex,
            newLiquidityIndex,
            newVariableBorrowIndex,
            lastUpdatedTimestamp
        );
    }

    /**
     * @dev Initializes a reserve
     * @param reserve The reserve object
     * @param tToken The address of the overlying tToken contract
     * @param variableDebtToken The address of the overlying variableDebtToken contract
     * @param interestRateStrategy The address of the interest rate strategy contract
     **/
    function init(
        DataTypes.ReserveData storage reserve,
        ITToken tToken,
        IVariableDebtToken variableDebtToken,
        IReserveInterestRateStrategy interestRateStrategy
    ) external {
        require(
            reserve.tTokenAddress == address(0),
            "reserve already initialized"
        );

        reserve.liquidityIndex = uint128(WadRayMath.ray());
        reserve.variableBorrowIndex = uint128(WadRayMath.ray());
        reserve.tTokenAddress = address(tToken);
        reserve.variableDebtTokenAddress = address(variableDebtToken);
        reserve.interestRateStrategyAddress = address(interestRateStrategy);
    }

    struct UpdateInterestRatesLocalVars {
        uint256 availableLiquidity;
        uint256 newLiquidityRate;
        uint256 newVariableRate;
        uint256 totalVariableDebt;
    }

    /**
     * @dev Updates the current variable borrow rate and the current liquidity rate
     * @param reserveAddress The address of the reserve to be updated
     * @param tTokenAddress The address of tToken to be updated
     * @param liquidityAdded The amount of liquidity added to the protocol (deposit or repay) in the previous action
     * @param liquidityTaken The amount of liquidity taken from the protocol (redeem or borrow)
     **/
    function updateInterestRates(
        DataTypes.ReserveData storage reserve,
        address reserveAddress,
        address tTokenAddress,
        uint256 liquidityAdded,
        uint256 liquidityTaken
    ) internal {
        UpdateInterestRatesLocalVars memory vars;

        //calculates the total variable debt locally using the scaled total supply instead
        //of totalSupply(), as it's noticeably cheaper. Also, the index has been
        //updated by the previous updateState() call
        vars.totalVariableDebt = IVariableDebtToken(
            reserve.variableDebtTokenAddress
        )
            .scaledTotalSupply()
            .rayMul(reserve.variableBorrowIndex);

        (
            vars.newLiquidityRate,
            vars.newVariableRate
        ) = IReserveInterestRateStrategy(reserve.interestRateStrategyAddress)
            .calculateInterestRates(
                reserveAddress,
                tTokenAddress,
                liquidityAdded,
                liquidityTaken,
                vars.totalVariableDebt,
                reserve.configuration.getReserveFactor()
            );

        require(
            vars.newLiquidityRate <= type(uint128).max,
            "newLiquidityRate overflow"
        );
        
        require(
            vars.newVariableRate <= type(uint128).max,
            "newVariableRate overflow"
        );

        reserve.currentLiquidityRate = uint128(vars.newLiquidityRate);
        reserve.currentVariableBorrowRate = uint128(vars.newVariableRate);

        emit ReserveDataUpdated(
            reserveAddress,
            vars.newLiquidityRate,
            vars.newVariableRate,
            reserve.liquidityIndex,
            reserve.variableBorrowIndex
        );
    }

    struct MintToTreasuryLocalVars {
        uint256 currentStableDebt;
        uint256 principalStableDebt;
        uint256 previousStableDebt;
        uint256 currentVariableDebt;
        uint256 previousVariableDebt;
        uint256 avgStableRate;
        uint256 cumulatedStableInterest;
        uint256 totalDebtAccrued;
        uint256 amountToMint;
        uint256 reserveFactor;
        uint40 stableSupplyUpdatedTimestamp;
    }

    /**
     * @dev Mints part of the repaid interest to the reserve treasury as a function of the reserveFactor for the
     * specific asset.
     * @param reserve The reserve to be updated
     * @param scaledVariableDebt The current scaled total variable debt
     * @param previousVariableBorrowIndex The variable borrow index before the last accumulation of the interest
     * @param newLiquidityIndex The new liquidity index
     * @param newVariableBorrowIndex The variable borrow index after the last accumulation of the interest
     * @return amountToMint amount minted to treasury
     **/
    function _mintToTreasury(
        DataTypes.ReserveData storage reserve,
        uint256 scaledVariableDebt,
        uint256 previousVariableBorrowIndex,
        uint256 newLiquidityIndex,
        uint256 newVariableBorrowIndex,
        uint40
    ) internal returns (uint256 amountToMint) {
        MintToTreasuryLocalVars memory vars;

        vars.reserveFactor = reserve.configuration.getReserveFactor();

        if (vars.reserveFactor == 0) return 0;

        vars.previousVariableDebt = scaledVariableDebt.rayMul(
            previousVariableBorrowIndex
        );

        vars.currentVariableDebt = scaledVariableDebt.rayMul(
            newVariableBorrowIndex
        );

        vars.totalDebtAccrued = vars.currentVariableDebt.sub(
            vars.previousVariableDebt
        );

        vars.amountToMint = vars.totalDebtAccrued.percentMul(
            vars.reserveFactor
        );

        if (vars.amountToMint != 0) {
            ITToken(reserve.tTokenAddress).mintToTreasury(
                vars.amountToMint,
                newLiquidityIndex
            );
        }

        return vars.amountToMint.rayDiv(newLiquidityIndex);
    }

    /**
     * @dev Updates the reserve indexes and the timestamp of the update
     * @param reserve The reserve reserve to be updated
     * @param scaledVariableDebt The scaled variable debt
     * @param liquidityIndex The last stored liquidity index
     * @param variableBorrowIndex The last stored variable borrow index
     * @param timestamp The timestamp of the last update
     * @return The new updated liquidity index and variable borrow index
     **/
    function _updateIndexes(
        DataTypes.ReserveData storage reserve,
        uint256 scaledVariableDebt,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex,
        uint40 timestamp
    ) internal returns (uint256, uint256) {
        uint256 currentLiquidityRate = reserve.currentLiquidityRate;

        uint256 newLiquidityIndex = liquidityIndex;
        uint256 newVariableBorrowIndex = variableBorrowIndex;

        //only cumulating if there is any income being produced
        if (currentLiquidityRate > 0) {
            uint256 cumulatedLiquidityInterest = MathUtils.calculateLinearInterest(
                currentLiquidityRate,
                timestamp
            );

            newLiquidityIndex = cumulatedLiquidityInterest.rayMul(liquidityIndex);

            require(
                newLiquidityIndex <= type(uint128).max,
                "newLiquidityIndex overflow"
            );

            reserve.liquidityIndex = uint128(newLiquidityIndex);

            //as the liquidity rate might come only from stable rate loans, we need to ensure
            //that there is actual variable debt before accumulating
            if (scaledVariableDebt != 0) {
                uint256 cumulatedVariableBorrowInterest = MathUtils.calculateCompoundedInterest(
                    reserve.currentVariableBorrowRate,
                    timestamp
                );
                newVariableBorrowIndex = cumulatedVariableBorrowInterest.rayMul(variableBorrowIndex);
                
                require(
                    newVariableBorrowIndex <= type(uint128).max,
                    "newVariableBorrowIndex overflow"
                );
                reserve.variableBorrowIndex = uint128(newVariableBorrowIndex);
            }
        }

        //solium-disable-next-line
        reserve.lastUpdateTimestamp = uint40(block.timestamp);
        return (newLiquidityIndex, newVariableBorrowIndex);
    }
}