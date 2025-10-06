// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {SafeMath} from "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IReserveInterestRateStrategy} from "../interfaces/IReserveInterestRateStrategy.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";
import {IBEP20} from "../../dependencies/openzeppelin/contracts/IBEP20.sol";

/**
 * @title DefaultReserveInterestRateStrategy contract
 * @notice Implements the calculation of the interest rates depending on the reserve stateaddressesProvider
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_UTILIZATION_RATE`
 * point of utilization and another from that one to 100%
 * - An instance of this same contract, can't be used across different markets, due to the caching
 *   of the AddressesProvider
 **/
contract ReserveInterestRateStrategy is IReserveInterestRateStrategy {
    using WadRayMath for uint256;
    using SafeMath for uint256;
    using PercentageMath for uint256;

    /**
     * @dev this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates.
     * Expressed in ray
     **/
    uint256 public immutable OPTIMAL_UTILIZATION_RATE;

    /**
     * @dev This constant represents the excess utilization rate above the optimal. It's always equal to
     * 1-optimal utilization rate. Added as a constant here for gas optimizations.
     * Expressed in ray
     **/

    uint256 public immutable EXCESS_UTILIZATION_RATE;

    IAddressesProvider public immutable addressesProvider;

    // Base variable borrow rate when Utilization rate = 0. Expressed in ray
    uint256 internal immutable _baseVariableBorrowRate;

    // Slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable _variableRateSlope1;

    // Slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    uint256 internal immutable _variableRateSlope2;

    // Slope of the stable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
    // uint256 internal immutable _stableRateSlope1;

    // Slope of the stable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
    // uint256 internal immutable _stableRateSlope2;

    // constructor() {}

    constructor(
        IAddressesProvider provider,
        uint256 optimalUtilizationRate,
        uint256 baseVariableBorrowRate_,
        uint256 variableRateSlope1_,
        uint256 variableRateSlope2_
    ) {
        OPTIMAL_UTILIZATION_RATE = optimalUtilizationRate;
        EXCESS_UTILIZATION_RATE = WadRayMath.ray().sub(optimalUtilizationRate);
        addressesProvider = provider;
        _baseVariableBorrowRate = baseVariableBorrowRate_;
        _variableRateSlope1 = variableRateSlope1_;
        _variableRateSlope2 = variableRateSlope2_;
    }

    function variableRateSlope1() external view returns (uint256) {
        return _variableRateSlope1;
    }

    function variableRateSlope2() external view returns (uint256) {
        return _variableRateSlope2;
    }

    function baseVariableBorrowRate() external view override returns (uint256) {
        return _baseVariableBorrowRate;
    }

    function getMaxVariableBorrowRate() external view override returns (uint256) {
        return
            _baseVariableBorrowRate.add(_variableRateSlope1).add(
                _variableRateSlope2
            );
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configurations
     * @param reserve The address of the reserve
     * @param tToken The address of tToken
     * @param liquidityAdded The liquidity added during the operation
     * @param liquidityTaken The liquidity taken during the operation
     * @param totalVariableDebt The total borrowed from the reserve at a variable rate
     * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
     * @return The liquidity rate and the variable borrow rate
     **/
    function calculateInterestRates(
        address reserve,
        address tToken,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 totalVariableDebt,
        uint256 reserveFactor
    ) external view override returns (uint256, uint256) {
        uint256 availableLiquidity = IBEP20(reserve).balanceOf(tToken);
        //avoid stack too deep
        availableLiquidity = availableLiquidity.add(liquidityAdded).sub(
            liquidityTaken
        );

        return
            calculateInterestRates(
                // reserve,
                availableLiquidity,
                totalVariableDebt,
                reserveFactor
            );
    }

    struct CalcInterestRatesLocalVars {
        uint256 totalDebt;
        uint256 currentVariableBorrowRate;
        uint256 currentLiquidityRate;
        uint256 utilizationRate;
    }

    /**
     * @dev Calculates the interest rates depending on the reserve's state and configurations.
     * NOTE This function is kept for compatibility with the previous DefaultInterestRateStrategy interface.
     * New protocol implementation uses the new calculateInterestRates() interface
     * @param availableLiquidity The liquidity available in the corresponding tToken
     * @param totalVariableDebt The total borrowed from the reserve at a variable rate
     * @param reserveFactor The reserve portion of the interest that goes to the treasury of the market
     * @return The liquidity rate and the variable borrow rate
     **/
    function calculateInterestRates(
        // address reserve,
        uint256 availableLiquidity,
        uint256 totalVariableDebt,
        uint256 reserveFactor
    ) public view override returns (uint256, uint256) {
        CalcInterestRatesLocalVars memory vars;

        vars.totalDebt = totalVariableDebt;
        vars.currentVariableBorrowRate = 0;
        vars.currentLiquidityRate = 0;
        vars.utilizationRate = vars.totalDebt == 0
            ? 0
            : vars.totalDebt.rayDiv(availableLiquidity.add(vars.totalDebt));

        // Borrow rate
        if (vars.utilizationRate > OPTIMAL_UTILIZATION_RATE) {
            // Ut > Uoptimal
            uint256 excessUtilizationRateRatio =
                vars.utilizationRate.sub(OPTIMAL_UTILIZATION_RATE).rayDiv(
                    EXCESS_UTILIZATION_RATE
                );
            vars.currentVariableBorrowRate = _baseVariableBorrowRate
                .add(_variableRateSlope1)
                .add(_variableRateSlope2.rayMul(excessUtilizationRateRatio));
        } else {
            // Ut < Uoptimal
            uint256 excessUtilizationRateRatio =
                vars.utilizationRate.rayDiv(OPTIMAL_UTILIZATION_RATE);

            vars.currentVariableBorrowRate = _baseVariableBorrowRate.add(
                excessUtilizationRateRatio.rayMul(_variableRateSlope1)
            );
        }
        // LRt = Overal Rt * Ut
        // Don't use Stable rate. So Overall borrow rate = variable borrow rate
        vars.currentLiquidityRate = vars
            .currentVariableBorrowRate
            .rayMul(vars.utilizationRate)
            .percentMul(PercentageMath.PERCENTAGE_FACTOR.sub(reserveFactor));
        return (vars.currentLiquidityRate, vars.currentVariableBorrowRate);
    }
}