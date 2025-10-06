// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;
pragma experimental ABIEncoderV2;

import {SafeMath} from "../../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {IBEP20} from "../../../dependencies/openzeppelin/contracts/IBEP20.sol";
import {SafeBEP20} from "../../../dependencies/openzeppelin/contracts/SafeBEP20.sol";
import {ReserveLogic} from "./ReserveLogic.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

/**
 * @title ReserveLogic library
 * @notice Implements functions to validate the different actions of the protocol
 */
library ValidationLogic {
    using ReserveLogic for DataTypes.ReserveData;
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeBEP20 for IBEP20;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    
    function validateWithdraw(
        address asset,
        uint256 amount,
        uint256 userBalance,
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        mapping(uint256 => DataTypes.PoolData) storage pools,
        DataTypes.UserGlobalData storage userData,
        mapping(uint256 => uint256) storage chainsList,
        uint256 chainsCount,
        address oracle
    ) external view {
        require(amount != 0, Errors.VL_INVALID_AMOUNT);
        require(
            amount <= userBalance,
            Errors.VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE
        );

        (bool isActive, , ) = reservesData[asset].configuration.getFlags();
        require(isActive, Errors.VL_NO_ACTIVE_RESERVE);
        require(
            GenericLogic.balanceDecreaseAllowed(
                asset,
                amount,
                reservesData,
                userConfig,
                pools,
                userData,
                chainsList,
                chainsCount,
                oracle
            ),
            Errors.VL_TRANSFER_NOT_ALLOWED
        );
    }

    struct ValidateBorrowLocalVars {
        uint256 currentLtv;
        uint256 currentLiquidationThreshold;
        uint256 amountOfCollateralNeededUSD;
        uint256 userCollateralBalanceUSD;
        uint256 userBorrowBalanceUSD;
        uint256 availableLiquidity;
        uint256 healthFactor;
        bool isActive;
        bool isFrozen;
        bool borrowingEnabled;
        bool stableRateBorrowingEnabled;
    }

    function validateBorrow(
        DataTypes.ReserveData storage reserve,
        uint256 amount,
        uint256 amountInUSD,
        mapping(uint256 => DataTypes.PoolData) storage pools,
        DataTypes.UserGlobalData storage userData,
        mapping(uint256 => uint256) storage chainsList,
        uint256 chainsCount,
        address oracle
    ) external view {
        ValidateBorrowLocalVars memory vars;
        (vars.isActive, vars.isFrozen, vars.borrowingEnabled) = reserve.configuration.getFlags();

        require(vars.isActive, Errors.VL_NO_ACTIVE_RESERVE);
        require(!vars.isFrozen, Errors.VL_RESERVE_FROZEN);
        require(amount != 0, Errors.VL_INVALID_AMOUNT);
        require(vars.borrowingEnabled, Errors.VL_BORROWING_NOT_ENABLED);

        (
            vars.userCollateralBalanceUSD,
            vars.userBorrowBalanceUSD,
            vars.currentLtv,
            vars.currentLiquidationThreshold,
            vars.healthFactor
        ) = GenericLogic.calculateUserAccountData(
            pools,
            userData,
            chainsList,
            chainsCount,
            oracle
        );

        require(
            vars.userCollateralBalanceUSD > 0,
            Errors.VL_COLLATERAL_BALANCE_IS_0
        );
        require(
            vars.healthFactor >
                GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD
        );

        //add the current already borrowed amount to the amount requested to calculate the total collateral needed.
        vars.amountOfCollateralNeededUSD = vars
            .userBorrowBalanceUSD
            .add(amountInUSD)
            .percentDiv(vars.currentLtv); //LTV is calculated in percentage

        require(
            vars.amountOfCollateralNeededUSD <= vars.userCollateralBalanceUSD,
            Errors.VL_COLLATERAL_CANNOT_COVER_NEW_BORROW
        );
    }
   
    function validateSetUseReserveAsCollateral(
        address asset,
        bool useAsCollateral,
        uint256 underlyingBalance,
        mapping(address => DataTypes.ReserveData) storage reservesData,
        DataTypes.UserConfigurationMap storage userConfig,
        mapping(uint256 => DataTypes.PoolData) storage pools,
        DataTypes.UserGlobalData storage userData,
        mapping(uint256 => uint256) storage chainsList,
        uint256 chainsCount,
        address oracle
    ) external view {

        require(
            underlyingBalance > 0,
            Errors.VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0
        );
        require(
            useAsCollateral ||
            GenericLogic.balanceDecreaseAllowed(
                asset,
                underlyingBalance,
                reservesData,
                userConfig,
                pools,
                userData,
                chainsList,
                chainsCount,
                oracle
            ),
            Errors.VL_DEPOSIT_ALREADY_IN_USE
        );
    }

    /**
     * @dev Validates the liquidation action
     * @param collateralReserve The reserve data of the collateral
     * @param principalReserve The reserve data of the principal
     * @param userConfig The user configuration
     * @param userHealthFactor The user's health factor
     * @param userTotalDebt Total variable debt balance of the user
     **/
    function validateLiquidationCall(
        DataTypes.ReserveData storage collateralReserve,
        DataTypes.ReserveData storage principalReserve,
        DataTypes.UserConfigurationMap storage userConfig,
        uint256 userHealthFactor,
        uint256 userTotalDebt
    ) external view {
        require(
            collateralReserve.configuration.getActive() &&
            principalReserve.configuration.getActive(),
            Errors.VL_NO_ACTIVE_RESERVE
        );
        require(
            userHealthFactor < GenericLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD,
            Errors.VL_LIQUIDATION_HEALTH_FACTOR_NOT_BELOW_THRESHOLD
        );

        bool isCollateralEnabled =
            collateralReserve.configuration.getLiquidationThreshold() > 0 &&
                userConfig.isUsingAsCollateral(collateralReserve.id);

        //if collateral isn't enabled as collateral by user, it cannot be liquidated
        require(
            isCollateralEnabled,
            Errors.VL_LIQUIDATION_COLLATERAL_CANNOT_BE_LIQUIDATED
        );
        require(
            userTotalDebt > 0,
            Errors.VL_LIQUIDATION_DEBT_MUST_BE_GT_0
        );
    }
}