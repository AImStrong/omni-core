// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;
pragma experimental ABIEncoderV2;

import {ReserveLogic} from "./ReserveLogic.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {Errors} from "../helpers/Errors.sol";
import {IPriceOracleGetter} from "../../interfaces/IPriceOracleGetter.sol";

/**
 * @title GenericLogic library
 * @title Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;

    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1 ether;

    struct BalanceDecreaseAllowedVars {
        uint256 decimals;
        uint256 liquidationThreshold;
        uint256 totalCollateralInUSD;
        uint256 totalDebtInUSD;
        uint256 avgLiquidationThreshold;
        uint256 amountToDecreaseInUSD;
        uint256 collateralBalanceAfterDecrease;
        uint256 liquidationThresholdAfterDecrease;
        uint256 healthFactorAfterDecrease;
        uint256 price;
    }

    struct CalculateUserChainDataVars {
        uint256 reserveUnitPrice;
        uint256 tokenUnit;
        uint256 compoundedLiquidityBalance;
        uint256 compoundedBorrowBalance;
        uint256 decimals;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 i;
        uint256 totalCollateralInUSD;
        uint256 totalDebtInUSD;
        uint256 avgLtv;
        uint256 avgLiquidationThreshold;
        address currentReserveAddress;
    }

    struct CalculateUserAccountDataVars {
        uint256 totalCollateralInUSD;
        uint256 totalDebtInUSD;
        uint256 weightedLtv;
        uint256 weightedLiquidationThreshold;
        uint256 chainCollateralInUSD;
        uint256 chainDebtInUSD;
        uint256 chainLtv;
        uint256 chainLiquidationThreshold;
        uint256 chainId;
        uint256 ltv;
        uint256 currentLiquidationThreshold;
        uint256 healthFactor;
        uint256 i;
    }

    struct CalculateUserAprVars {
        uint256 totalCollateralInUSD;
        address currentReserveAddress;
        uint256 compoundedLiquidityBalance;
        uint256 compoundedBorrowBalance;
        uint256 tokenUnit;
        uint256 reserveUnitPrice;
        uint256 liquidityBalanceUSD;
        uint256 totalSupplyInterestInUSD;
        uint256 totalBorrowInterestInUSD;
        uint256 netInterestInUSD;
    }

    /**
     * @dev Checks if a specific balance decrease is allowed for a user.
     * This function evaluates if decreasing the balance of a specific reserve by a given amount
     * would bring the user's borrow position health factor below the HEALTH_FACTOR_LIQUIDATION_THRESHOLD.
     * It takes into account the user's current configuration, reserve data, pool data, and global user data.
     * 
     * @param reserveAddress The address of the reserve for which the balance decrease is being evaluated.
     * @param amount The amount of the balance decrease being considered.
     * @param reservesData A mapping of reserve addresses to their data.
     * @param userConfig The user's configuration data.
     * @param pools A mapping of pool data by chain ID.
     * @param userData The user's global data.
     * @param chainsList A mapping of chain IDs to their list positions.
     * @param chainsCount The total number of chains.
     * @param oracle The address of the oracle contract used for price retrieval.
     * @return Returns true if the balance decrease is allowed, false otherwise.
     **/
    function balanceDecreaseAllowed(
        address reserveAddress,
        uint256 amount,
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap calldata userConfig,
        mapping(uint256 => DataTypes.PoolData) storage pools,
        DataTypes.UserGlobalData storage userData,
        mapping(uint256 => uint256) storage chainsList,
        uint256 chainsCount,
        address oracle
    ) external view returns (bool) {
        if (
            !userConfig.isBorrowingAny() ||
            !userConfig.isUsingAsCollateral(reservesData[reserveAddress].id)
        ) {
            return true;
        }

        BalanceDecreaseAllowedVars memory vars;

        (, vars.liquidationThreshold, , vars.decimals, ) = reservesData[reserveAddress]
            .configuration
            .getParams();

        if (vars.liquidationThreshold == 0) return true;

        (
            vars.totalCollateralInUSD,
            vars.totalDebtInUSD,
            ,
            vars.avgLiquidationThreshold,

        ) = calculateUserAccountData(
            pools,
            userData,
            chainsList,
            chainsCount,
            oracle
        );

        if (vars.totalDebtInUSD == 0) return true;

        vars.price = IPriceOracleGetter(oracle).getAssetPrice(reserveAddress);
        vars.amountToDecreaseInUSD = vars.price * amount / (10**vars.decimals);

        vars.collateralBalanceAfterDecrease = vars.totalCollateralInUSD - vars.amountToDecreaseInUSD;

        //if there is a borrow, there can't be 0 collateral
        if (vars.collateralBalanceAfterDecrease == 0) return false;

        vars.liquidationThresholdAfterDecrease = 
            (vars.totalCollateralInUSD * vars.avgLiquidationThreshold - 
             vars.amountToDecreaseInUSD * vars.liquidationThreshold) / 
            vars.collateralBalanceAfterDecrease;

        vars.healthFactorAfterDecrease = calculateHealthFactorFromBalances(
            vars.collateralBalanceAfterDecrease,
            vars.totalDebtInUSD,
            vars.liquidationThresholdAfterDecrease
        );

        return
            vars.healthFactorAfterDecrease >=
            GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD;
    }
    
    /**
     * @dev Calculates the user data across all chains and reserves
     * @param pools Mapping of pools data for each chain
     * @param userData The user's global data containing chain-specific configurations
     * @param chainsList List of available chains
     * @param chainsCount Total number of chains
     * @param oracle The price oracle address
     * @return totalCollateralInUSD The total collateral in USD across all chains
     * @return totalDebtInUSD The total debt in USD across all chains
     * @return ltv The weighted average LTV across all chains
     * @return currentLiquidationThreshold The weighted average liquidation threshold across all chains
     * @return healthFactor The health factor calculated from the total position
     **/
    function calculateUserAccountData(
        mapping(uint256 => DataTypes.PoolData) storage pools,
        DataTypes.UserGlobalData storage userData,
        mapping(uint256 => uint256) storage chainsList,
        uint256 chainsCount,
        address oracle
    ) internal view returns (
        uint256,
        uint256, 
        uint256, 
        uint256, 
        uint256 
    ) {
        CalculateUserAccountDataVars memory vars;

        // Loop through all chains
        for (vars.i = 0; vars.i < chainsCount; vars.i++) { // @audit: <= chainsCount
            vars.chainId = chainsList[vars.i];
            DataTypes.UserChainData storage UserChainData = userData.userChainsData[vars.chainId];
            DataTypes.PoolData storage poolData = pools[vars.chainId];

            // Calculate user data for current chain
            (
                vars.chainCollateralInUSD,
                vars.chainDebtInUSD,
                vars.chainLtv,
                vars.chainLiquidationThreshold
            ) = calculateUserChainData(
                UserChainData.userScaledBalances,
                poolData.reserves,
                UserChainData.userConfig,
                poolData.reservesList,
                poolData.reservesCount,
                oracle
            );
            
            // Update totals
            vars.totalCollateralInUSD = vars.totalCollateralInUSD + vars.chainCollateralInUSD;
            vars.totalDebtInUSD = vars.totalDebtInUSD + vars.chainDebtInUSD;
            
            vars.weightedLtv = vars.weightedLtv + vars.chainLtv;
            vars.weightedLiquidationThreshold = vars.weightedLiquidationThreshold + vars.chainLiquidationThreshold;
        }
    
        // Calculate final weighted averages if there is total collateral, if not have Collateral return default value 0
        if (vars.totalCollateralInUSD > 0) {
            vars.ltv = vars.weightedLtv / vars.totalCollateralInUSD; 
            vars.currentLiquidationThreshold = vars.weightedLiquidationThreshold / vars.totalCollateralInUSD;
        }
        
        // Calculate final health factor
        vars.healthFactor = calculateHealthFactorFromBalances(
            vars.totalCollateralInUSD,
            vars.totalDebtInUSD,
            vars.currentLiquidationThreshold
        );

        return (
            vars.totalCollateralInUSD,
            vars.totalDebtInUSD,
            vars.ltv,
            vars.currentLiquidationThreshold,
            vars.healthFactor
        );
    }


    /**
     * @dev Calculates the user's data for a specific chain
     * @param userScaledBalances The user's scaled balances for each reserve in the chain
     * @param reservesData Data of all the reserves in the chain
     * @param userConfig The user's configuration for the chain
     * @param reserves The list of reserves in the chain
     * @param reservesCount The number of reserves in the chain
     * @param oracle The price oracle address
     * @return totalCollateralInUSD The total collateral in USD for this chain
     * @return totalDebtInUSD The total debt in USD for this chain
     * @return avgLtv The weighted average LTV for this chain
     * @return avgLiquidationThreshold The weighted average liquidation threshold for this chain
     */
    function calculateUserChainData(
        mapping(address => DataTypes.UserReserveData) storage userScaledBalances,
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap memory userConfig,
        mapping(uint256 => address) storage reserves,
        uint256 reservesCount,
        address oracle
    ) internal view returns (
        uint256,
        uint256,
        uint256,
        uint256
    ) {
        CalculateUserChainDataVars memory vars;

        if (userConfig.isEmpty()) return (0, 0, 0, 0);

        for (vars.i = 0; vars.i < reservesCount; vars.i++) {
            if (!userConfig.isUsingAsCollateralOrBorrowing(vars.i)) continue;

            vars.currentReserveAddress = reserves[vars.i];
            DataTypes.ReserveData storage currentReserve = reservesData[vars.currentReserveAddress];

            (
                vars.ltv,
                vars.liquidationThreshold,
                ,
                vars.decimals,
            ) = currentReserve.configuration.getParams();

            vars.tokenUnit = 10**vars.decimals;
            vars.reserveUnitPrice = IPriceOracleGetter(oracle).getAssetPrice(
                vars.currentReserveAddress
            );

            if (
                vars.liquidationThreshold != 0 &&
                userConfig.isUsingAsCollateral(vars.i)
            ) {
                vars.compoundedLiquidityBalance = userScaledBalances[vars.currentReserveAddress].scaledInCome.rayMul(
                currentReserve.getNormalizedIncome());

                uint256 liquidityBalanceUSD =
                    vars.reserveUnitPrice
                        * vars.compoundedLiquidityBalance
                        / vars.tokenUnit;

                vars.totalCollateralInUSD = vars.totalCollateralInUSD + liquidityBalanceUSD;

                vars.avgLtv = vars.avgLtv + liquidityBalanceUSD * vars.ltv;
                vars.avgLiquidationThreshold = vars.avgLiquidationThreshold + 
                    liquidityBalanceUSD * vars.liquidationThreshold;
            }

            if (userConfig.isBorrowing(vars.i)) {
                vars.compoundedBorrowBalance = userScaledBalances[vars.currentReserveAddress].scaledDebt.rayMul(
                currentReserve.getNormalizedDebt());
                vars.totalDebtInUSD = vars.totalDebtInUSD + 
                    vars.reserveUnitPrice * vars.compoundedBorrowBalance / vars.tokenUnit;
            }
        }
        
        return (
            vars.totalCollateralInUSD,
            vars.totalDebtInUSD,
            vars.avgLtv,
            vars.avgLiquidationThreshold
        );
    }

    /**
     * @dev Calculates the health factor from the corresponding balances
     * @param totalCollateralInUSD The total collateral in USD
     * @param totalDebtInUSD The total debt in USD
     * @param liquidationThreshold The avg liquidation threshold
     * @return The health factor calculated from the balances provided
     **/
    function calculateHealthFactorFromBalances(
        uint256 totalCollateralInUSD,
        uint256 totalDebtInUSD,
        uint256 liquidationThreshold
    ) internal pure returns (uint256) {
        uint256 healthFactor;
        
        if (totalDebtInUSD == 0) healthFactor = type(uint256).max;
        else healthFactor = (totalCollateralInUSD.percentMul(liquidationThreshold)).wadDiv(totalDebtInUSD);

        // require(healthFactor > 0, Errors.GL_INVALID_HEALTH_FACTOR);
        return healthFactor;
    }

    /**
     * @dev Calculates the equivalent amount in USD that an user can borrow, depending on the available collateral and the
     * average Loan To Value
     * @param totalCollateralInUSD The total collateral in USD
     * @param totalDebtInUSD The total borrow balance
     * @param ltv The average loan to value
     * @return the amount available to borrow in USD for the user
     **/
    function calculateAvailableBorrowsUSD(
        uint256 totalCollateralInUSD,
        uint256 totalDebtInUSD,
        uint256 ltv
    ) internal pure returns (uint256) {
        uint256 availableBorrowsUSD = totalCollateralInUSD.percentMul(ltv);

        if (availableBorrowsUSD < totalDebtInUSD) return 0;

        availableBorrowsUSD = availableBorrowsUSD - totalDebtInUSD;
        return availableBorrowsUSD;
    }
    
    /**
     * @dev Calculates the user's Apr 
     * @param pools Mapping of pools data for each chain
     * @param userData The user's global data containing chain-specific configurations
     * @param chainsList List of available chains
     * @param chainsCount Total number of chains
     * @param oracle The price oracle address
     * @return The Apr by the user 
     */
    function calculateUserApr(
        mapping(uint256 => DataTypes.PoolData) storage pools,
        DataTypes.UserGlobalData storage userData,
        mapping(uint256 => uint256) storage chainsList,
        uint256 chainsCount,
        address oracle
    ) internal view returns (int256) {
        CalculateUserAprVars memory vars;

        // Loop through all chains
        for (uint256 i = 0; i < chainsCount; i++) {
            uint256 chainId = chainsList[i];
            DataTypes.UserChainData storage userChainData = userData.userChainsData[chainId];
            DataTypes.UserConfigurationMap memory userConfig = userChainData.userConfig;
            DataTypes.PoolData storage poolData = pools[chainId];

            if (userConfig.isEmpty()) continue;

            // Loop through all reserves in the chain
            for (uint256 j = 0; j < poolData.reservesCount; j++) {
                if (!userConfig.isUsingAsCollateralOrBorrowing(j)) continue;

                vars.currentReserveAddress = poolData.reservesList[j];
                DataTypes.ReserveData storage currentReserve = poolData.reserves[vars.currentReserveAddress];

                (
                    ,
                    uint256 liquidationThreshold,
                    ,
                    uint256 decimals,
                ) = currentReserve.configuration.getParams();

                vars.tokenUnit = 10**decimals;
                vars.reserveUnitPrice = IPriceOracleGetter(oracle).getAssetPrice(vars.currentReserveAddress);

                if (
                    liquidationThreshold != 0 &&
                    userConfig.isUsingAsCollateral(j)
                ) {
                    vars.compoundedLiquidityBalance = userChainData.userScaledBalances[vars.currentReserveAddress].scaledInCome.rayMul(
                    currentReserve.getNormalizedIncome());

                    vars.liquidityBalanceUSD =
                        vars.reserveUnitPrice
                            * vars.compoundedLiquidityBalance
                            / vars.tokenUnit;

                    vars.totalCollateralInUSD = vars.totalCollateralInUSD + vars.liquidityBalanceUSD;

                    // Track supply interest
                    vars.totalSupplyInterestInUSD += vars.liquidityBalanceUSD.rayMul(currentReserve.currentLiquidityRate);
                }

                if (userConfig.isBorrowing(j)) {
                    vars.compoundedBorrowBalance = userChainData.userScaledBalances[vars.currentReserveAddress].scaledDebt.rayMul(
                    currentReserve.getNormalizedDebt());

                    uint256 borrowBalanceUSD = vars.reserveUnitPrice * vars.compoundedBorrowBalance / vars.tokenUnit;
                    
                    // Track borrow interest
                    vars.totalBorrowInterestInUSD += borrowBalanceUSD.rayMul(currentReserve.currentVariableBorrowRate);
                }
            }
        }

        if (vars.totalCollateralInUSD == 0) return 0;

        // Calculate net interest (supply interest - borrow interest)
        if (vars.totalSupplyInterestInUSD >= vars.totalBorrowInterestInUSD) {
            // Positive case
            vars.netInterestInUSD = vars.totalSupplyInterestInUSD - vars.totalBorrowInterestInUSD;
            return int256(vars.netInterestInUSD.rayDiv(vars.totalCollateralInUSD));
        } else {
            // Negative case
            vars.netInterestInUSD = vars.totalBorrowInterestInUSD - vars.totalSupplyInterestInUSD;
            return -int256(vars.netInterestInUSD.rayDiv(vars.totalCollateralInUSD));
        }
    }
}