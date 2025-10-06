// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

import {ReserveLogic} from "./ReserveLogic.sol";
import {ReserveConfiguration} from "../configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../configuration/UserConfiguration.sol";
import {WadRayMath} from "../math/WadRayMath.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {ValidationLogic} from "./ValidationLogic.sol";
import {Errors} from "../helpers/Errors.sol";
import {GenericLogic} from "./GenericLogic.sol";
import {IPriceOracleGetter} from "../../interfaces/IPriceOracleGetter.sol";
import {IUniversalMessenger} from "../../interfaces/IUniversalMessenger.sol";

/**
 * @title LiquidationLogic library
 * @author Trava Protocol
 * @notice Implements the logic for liquidation operations in the protocol
 * @dev Library that contains the logic for liquidation operations
 */
library LiquidationLogic {
  using WadRayMath for uint256;
  using PercentageMath for uint256;
  using ReserveLogic for DataTypes.ReserveData;
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
  using UserConfiguration for DataTypes.UserConfigurationMap;

  /**
    * @dev Emitted when a liquidation is executed
    * @param debtAsset The asset debt being repaid
    * @param collateralAsset The asset used as collateral being liquidated
    * @param user The address of the borrower
    * @param debtChainId The chain ID where the debt asset is located
    * @param collateralChainId The chain ID where the collateral asset is located
    * @param debtToCover The debt amount repaid
    * @param liquidatedCollateralAmount The collateral amount liquidated
    * @param liquidator The address of the liquidator
    * @param receiveTToken True if the liquidation receives TTokens, false otherwise
    */
  event LiquidationCall(
    address indexed debtAsset,
    address indexed collateralAsset,
    address indexed user,
    uint256 debtChainId,
    uint256 collateralChainId,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveTToken
  );

  /**
    * @dev Default percentage of borrower's debt to be repaid in a liquidation.
    * @dev Percentage applied when the users health factor is above `CLOSE_FACTOR_HF_THRESHOLD`
    * Expressed in bps, a value of 0.5e4 results in 50.00%
    */
  uint256 internal constant DEFAULT_LIQUIDATION_CLOSE_FACTOR = 0.5e4;

  /**
    * @dev Maximum percentage of borrower's debt to be repaid in a liquidation
    * @dev Percentage applied when the users health factor is below `CLOSE_FACTOR_HF_THRESHOLD`
    * Expressed in bps, a value of 1e4 results in 100.00%
    */
  uint256 public constant MAX_LIQUIDATION_CLOSE_FACTOR = 1e4;

  /**
    * @dev This constant represents below which health factor value it is possible to liquidate
    * an amount of debt corresponding to `MAX_LIQUIDATION_CLOSE_FACTOR`.
    * A value of 0.95e18 results in 0.95
    */
  uint256 public constant CLOSE_FACTOR_HF_THRESHOLD = 0.95e18;

  /**
    * @dev Struct for the variables used in the liquidation call
    */
  struct LiquidationCallLocalVars {
    uint256 userCollateralBalance;
    uint256 userTotalDebt;
    uint256 actualDebtToLiquidate;
    uint256 liquidationBonus;
    uint256 actualCollateralToLiquidate;
    uint256 maxCollateralToLiquidate;
    uint256 healthFactor;
    bytes crossChainMsg;
  }

  /**
    * @notice Function to liquidate a non-healthy position
    * @dev The caller must provide the amount of asset to cover and receive the collateral as TToken or as the underlying asset
    * @param pools Mapping of pool data per chain
    * @param userData Global user data
    * @param chainsList List of supported chains
    * @param params Struct containing liquidation call parameters
    */
  function liquidationCall(
    mapping(uint256 => DataTypes.PoolData) storage pools,
    DataTypes.UserGlobalData storage userData,
    mapping(uint256 => uint256) storage chainsList,
    DataTypes.ExecuteLiquidationCallParams memory params
  ) external {
    LiquidationCallLocalVars memory vars;

    // Get reserve data from storage
    DataTypes.ReserveData storage collateralReserve = pools[params.collateralChainId].reserves[params.collateralAsset];
    DataTypes.ReserveData storage debtReserve = pools[params.debtChainId].reserves[params.debtAsset];
    DataTypes.UserConfigurationMap storage userCollateralChainConfig = userData.userChainsData[params.collateralChainId].userConfig;
    
    // Calculate user account data and health factor
    (, , , , vars.healthFactor) = GenericLogic.calculateUserAccountData(
      pools,
      userData,
      chainsList,
      params.chainsCount,
      params.oracle
    );

    // Calculate user's total debt for the debt asset
    vars.userTotalDebt = userData
        .userChainsData[params.debtChainId]
        .userScaledBalances[params.debtAsset]
        .scaledDebt
        .rayMul(debtReserve.getNormalizedDebt());
        
    // Calculate the actual debt amount to liquidate
    vars.actualDebtToLiquidate = _calculateDebt(
        vars.userTotalDebt,
        vars.healthFactor,
        params.debtToCover
    );

    // Validate the liquidation call parameters
    ValidationLogic.validateLiquidationCall(
      collateralReserve,
      debtReserve,
      userCollateralChainConfig,
      vars.healthFactor,
      vars.userTotalDebt
    );

    // Get liquidation bonus from collateral reserve
    vars.liquidationBonus = collateralReserve.configuration.getLiquidationBonus();
    
    // Calculate user's collateral balance for the collateral asset
    vars.userCollateralBalance = userData
        .userChainsData[params.collateralChainId]
        .userScaledBalances[params.collateralAsset]
        .scaledInCome
        .rayMul(collateralReserve.getNormalizedIncome());

    // Calculate the collateral to liquidate based on the debt to cover
    (
      vars.actualCollateralToLiquidate,
      vars.actualDebtToLiquidate
    ) = _calculateAvailableCollateralToLiquidate(
      collateralReserve,
      debtReserve,
      params.collateralAsset,
      params.debtAsset,
      vars.actualDebtToLiquidate,
      vars.userCollateralBalance,
      vars.liquidationBonus,
      IPriceOracleGetter(params.oracle)
    );

    // If the liquidator reclaims the underlying asset, ensure enough liquidity
    if (!params.receiveTToken) {
      uint256 currentAvailableCollateral = collateralReserve.balanceOfUnderlyingAsset;
        
      require(
        currentAvailableCollateral >= vars.maxCollateralToLiquidate,
        Errors.LL_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE
      );
    }

    userData.isBeingLiquidated = true;
    // Execute liquidation through universal messenger (commented implementation)
    vars.crossChainMsg = abi.encode(
      params.collateralAsset,
      params.debtAsset,
      params.user,
      msg.sender,
      params.receiveTToken,
      vars.actualCollateralToLiquidate, 
      vars.actualDebtToLiquidate,
      params.collateralChainId
    );

    IUniversalMessenger(params.universalMessenger).send(params.debtChainId, uint8(DataTypes.MessageHeader.ProcessLiquidationCallPhase2), msg.sender, vars.crossChainMsg);

    // Emit liquidation event
    emit LiquidationCall(
      params.debtAsset,
      params.collateralAsset,
      params.user,
      params.debtChainId,
      params.collateralChainId,
      vars.actualDebtToLiquidate,
      vars.actualCollateralToLiquidate,
      msg.sender,
      params.receiveTToken
    );
  }

  /**
    * @notice Calculates the debt amount that can be liquidated based on health factor
    * @dev If health factor is below threshold, apply maximum close factor, otherwise default
    * @param userTotalDebt The total debt of the user for the asset
    * @param healthFactor The health factor of the user
    * @param debtToCover The debt amount requested to be covered by the liquidator
    * @return The actual debt amount to be liquidated
    */
  function _calculateDebt(
    uint256 userTotalDebt,
    uint256 healthFactor,
    uint256 debtToCover
  ) internal pure returns (uint256) {
    // Determine close factor based on health factor threshold
    uint256 closeFactor = healthFactor > CLOSE_FACTOR_HF_THRESHOLD
        ? DEFAULT_LIQUIDATION_CLOSE_FACTOR  // 50% if HF > 0.95
        : MAX_LIQUIDATION_CLOSE_FACTOR;     // 100% if HF <= 0.95

    uint256 maxLiquidatableDebt = userTotalDebt.percentMul(closeFactor);

    uint256 actualDebtToLiquidate = debtToCover > maxLiquidatableDebt
      ? maxLiquidatableDebt
      : debtToCover;

    return actualDebtToLiquidate;
  }

  /**
  * @dev Struct for variables used in collateral liquidation calculations
  */
  struct AvailableCollateralToLiquidateLocalVars {
    uint256 collateralPrice;
    uint256 debtAssetPrice;
    uint256 baseCollateral;
    uint256 maxCollateralToLiquidate;
    uint256 debtAmountNeeded;
    uint256 collateralDecimals;
    uint256 debtAssetDecimals;
    uint256 collateralAssetUnit;
    uint256 debtAssetUnit;
    uint256 collateralAmount;
  }

  /**
   * @notice Calculates how much of a specific collateral can be liquidated, given
   * a certain amount of debt asset.
   * @dev This function needs to be called after all the checks to validate the liquidation have been performed,
   *   otherwise it might fail.
   * @param collateralReserve The data of the collateral reserve
   * @param debtReserve The cached data of the debt reserve
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param userCollateralBalance The collateral balance for the specific `collateralAsset` of the user being liquidated
   * @param liquidationBonus The collateral bonus percentage to receive as result of the liquidation
   * @return The maximum amount that is possible to liquidate given all the liquidation constraints (user balance, close factor)
   * @return The amount to repay with the liquidation
   */
  function _calculateAvailableCollateralToLiquidate(
    DataTypes.ReserveData storage collateralReserve,
    DataTypes.ReserveData storage debtReserve,
    address collateralAsset,
    address debtAsset,
    uint256 debtToCover,
    uint256 userCollateralBalance,
    uint256 liquidationBonus,
    IPriceOracleGetter oracle
  ) internal view returns (uint256, uint256) {
    AvailableCollateralToLiquidateLocalVars memory vars;

    vars.collateralPrice = oracle.getAssetPrice(collateralAsset);
    vars.debtAssetPrice = oracle.getAssetPrice(debtAsset);

    vars.collateralDecimals = collateralReserve.configuration.getDecimals();
    vars.debtAssetDecimals = debtReserve.configuration.getDecimals();

    unchecked {
      vars.collateralAssetUnit = 10 ** vars.collateralDecimals;
      vars.debtAssetUnit = 10 ** vars.debtAssetDecimals;
    }
  
    // This is the base collateral to liquidate based on the given debt to cover
    vars.baseCollateral =
      ((vars.debtAssetPrice * debtToCover * vars.collateralAssetUnit)) /
      (vars.collateralPrice * vars.debtAssetUnit);

    vars.maxCollateralToLiquidate = vars.baseCollateral.percentMul(liquidationBonus);

    if (vars.maxCollateralToLiquidate > userCollateralBalance) {
      vars.collateralAmount = userCollateralBalance;
      vars.debtAmountNeeded = ((vars.collateralPrice * vars.collateralAmount * vars.debtAssetUnit) /
        (vars.debtAssetPrice * vars.collateralAssetUnit)).percentDiv(liquidationBonus);
    } else {
      vars.collateralAmount = vars.maxCollateralToLiquidate;
      vars.debtAmountNeeded = debtToCover;
    }
    
    return (vars.collateralAmount, vars.debtAmountNeeded);
  }
}