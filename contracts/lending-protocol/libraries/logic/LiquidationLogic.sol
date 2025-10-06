// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import {DataTypes} from '../types/DataTypes.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {SafeMath} from "../../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {SafeBEP20} from "../../../dependencies/openzeppelin/contracts/SafeBEP20.sol";
import {IBEP20} from "../../../dependencies/openzeppelin/contracts/IBEP20.sol";
import {ITToken} from '../../interfaces/ITToken.sol';
import {IVariableDebtToken} from '../../interfaces/IVariableDebtToken.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {IConnectedMessenger} from "../../interfaces/IConnectedMessenger.sol";
import {Helpers} from '../helpers/Helpers.sol';

/**
 * @title LiquidationLogic library
 * @author Trava
 * @notice Implements the base logic for borrow/repay
 */
library LiquidationLogic {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using WadRayMath for uint256;

    event ReceiveLiquidatorUnderlying(
        address indexed reserve,
        address user,
        address liquidator,
        uint256 amount
    );

    event ReceiveLiquidatorUnderlyingFailed(
        address indexed reserve,
        address user,
        address liquidator,
        uint256 amount,
        uint256 balanceOfLiquidator,
        uint256 allowanceOfLiquidator,
        uint256 userDebt
    );

    event LiquidateCollateral(
        address indexed reserve,
        address user,
        address liquidator,
        bool receiveTToken,
        uint256 amount
    );

    /**
     * ReceiveLiquidatorUnderlying logic
     * @param reservesData The state of all the reserves
     * @param connectedMessenger message sender
     * @param universalMessenger message receiver
     * @param params The additional parameters needed to execute the TransferLiquidatorToken function
     */
    function executeReceiveLiquidatorUnderlying(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        IConnectedMessenger connectedMessenger,
        address universalMessenger,
        DataTypes.ReceiveLiquidatorUnderlyingParams memory params
    ) external {

        DataTypes.ReserveData storage debtReserve = reservesData[params.debtAsset];
        uint256 amountScaledMintedToTreasury = debtReserve.updateState();

        IVariableDebtToken(debtReserve.variableDebtTokenAddress).burn(
            params.user,
            params.actualDebtToLiquidate,
            debtReserve.variableBorrowIndex
        );

        debtReserve.updateInterestRates(
            params.debtAsset,
            debtReserve.tTokenAddress,
            params.actualDebtToLiquidate,
            0
        );

        IBEP20(params.debtAsset).safeTransferFrom(
            params.liquidator,
            debtReserve.tTokenAddress,
            params.actualDebtToLiquidate
        );

        uint256 newBalanceOfUnderlyingAsset = IBEP20(params.debtAsset).balanceOf(debtReserve.tTokenAddress);
        uint256 scaledAmount = params.actualDebtToLiquidate.rayDiv(debtReserve.variableBorrowIndex);
        bytes memory crossChainMsg = abi.encode(
            // liquidation data
            true, //debtIsCover
            params.collateralAsset,
            params.receiveTToken,
            params.actualCollateralToLiquidate,
            params.collateralChainId,
            params.liquidator,
            // user data
            params.user,
            params.debtAsset, 
            scaledAmount,
            // reserve data
            debtReserve.liquidityIndex,
            debtReserve.variableBorrowIndex,
            debtReserve.currentLiquidityRate,
            debtReserve.currentVariableBorrowRate,
            newBalanceOfUnderlyingAsset,
            // treasury
            ITToken(debtReserve.tTokenAddress).RESERVE_TREASURY_ADDRESS(),
            amountScaledMintedToTreasury,
            // timestamp
            uint40(block.timestamp)
        );

        connectedMessenger.send(
            params.liquidator,
            universalMessenger,
            uint8(DataTypes.MessageHeader.ProcessLiquidationCallPhase2),
            crossChainMsg
        );

        emit ReceiveLiquidatorUnderlying(params.debtAsset, params.user, params.liquidator, params.actualDebtToLiquidate);
    }

    /**
     * ReceiveLiquidatorUnderlyingFailed logic
     * @param reservesData The state of all the reserves
     * @param connectedMessenger message sender
     * @param universalMessenger message receiver
     * @param params The additional parameters needed to execute the ReceiveLiquidatorUnderlyingFailed function
     */
    function executeReceiveLiquidatorUnderlyingFailed(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        IConnectedMessenger connectedMessenger,
        address universalMessenger,
        DataTypes.ReceiveLiquidatorUnderlyingParams memory params
    ) external {

        DataTypes.ReserveData storage debtReserve = reservesData[params.debtAsset];
        uint256 amountScaledMintedToTreasury = debtReserve.updateState();

        // if transfer failed, send msg to admin to stop liquidation progress
        uint256 userDebt = Helpers.getUserCurrentDebt(params.user, debtReserve);
        
        bytes memory failedCrossChainMsg = abi.encode(
            // liquidation data
            false, //debtIsCover
            params.collateralAsset,
            params.receiveTToken,
            params.actualCollateralToLiquidate,
            params.collateralChainId,
            params.liquidator,
            // user data
            params.user,
            params.debtAsset, 
            0,
            // reserve data
            debtReserve.liquidityIndex,
            debtReserve.variableBorrowIndex,
            debtReserve.currentLiquidityRate,
            debtReserve.currentVariableBorrowRate,
            IBEP20(params.debtAsset).balanceOf(debtReserve.tTokenAddress),
            // treasury
            ITToken(debtReserve.tTokenAddress).RESERVE_TREASURY_ADDRESS(),
            amountScaledMintedToTreasury,
            // timestamp
            uint40(block.timestamp)
        );

        connectedMessenger.send(
            params.liquidator,
            universalMessenger,
            uint8(DataTypes.MessageHeader.ProcessLiquidationCallPhase2),
            failedCrossChainMsg
        );

        emit ReceiveLiquidatorUnderlyingFailed(
            params.debtAsset, 
            params.user, 
            params.liquidator, 
            params.actualDebtToLiquidate,
            IBEP20(params.debtAsset).balanceOf(params.liquidator),
            IBEP20(params.debtAsset).allowance(params.liquidator, address(this)),
            userDebt
        );
    }

    function executeLiquidateCollateral(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        IConnectedMessenger connectedMessenger,
        address universalMessenger,
        DataTypes.LiquidateCollateralParams memory params
    ) external {
        DataTypes.ReserveData storage collateralReserve = reservesData[params.collateralAsset];
        
        if (IBEP20(params.collateralAsset).balanceOf(collateralReserve.tTokenAddress) < params.actualCollateralToLiquidate) 
            params.receiveTToken = true;

        if (params.receiveTToken) {
            ITToken(collateralReserve.tTokenAddress).transferOnLiquidation(
                params.user,
                params.liquidator,
                params.actualCollateralToLiquidate
            );

            uint256 amountScaled = params.actualCollateralToLiquidate.rayDiv(collateralReserve.getNormalizedIncome());

            bytes memory crossChainMsg = abi.encode(
                params.user,
                params.liquidator,
                params.collateralAsset,
                amountScaled,
                params.actualCollateralToLiquidateScaled
            );

            connectedMessenger.send(
                params.liquidator,
                universalMessenger,
                uint8(DataTypes.MessageHeader.UpdateStateLiquidationCallPhase3Case1),
                crossChainMsg
            );
        }
        else {
            uint256 amountScaledMintedToTreasury = collateralReserve.updateState();
            collateralReserve.updateInterestRates(params.collateralAsset, collateralReserve.tTokenAddress, 0, params.actualCollateralToLiquidate);
            
            ITToken(collateralReserve.tTokenAddress).burn(
                params.user,
                params.liquidator,
                params.actualCollateralToLiquidate,
                collateralReserve.liquidityIndex
            );

            uint256 scaledAmount = params.actualCollateralToLiquidate.rayDiv(collateralReserve.liquidityIndex);
            uint256 delta = params.actualCollateralToLiquidateScaled - scaledAmount;

            bytes memory crossChainMsg = abi.encode(
                // user data
                params.user,
                params.collateralAsset,
                delta,
                // reserve data
                collateralReserve.liquidityIndex,
                collateralReserve.variableBorrowIndex,
                collateralReserve.currentLiquidityRate,
                collateralReserve.currentVariableBorrowRate,
                IBEP20(params.collateralAsset).balanceOf(collateralReserve.tTokenAddress),
                // treasury
                ITToken(collateralReserve.tTokenAddress).RESERVE_TREASURY_ADDRESS(),
                amountScaledMintedToTreasury,
                // timestamp
                uint40(block.timestamp)
            );

            connectedMessenger.send(
                params.liquidator,
                universalMessenger,
                uint8(DataTypes.MessageHeader.UpdateStateLiquidationCallPhase3Case2),
                crossChainMsg
            );
        }

        emit LiquidateCollateral(params.collateralAsset, params.user, params.liquidator, params.receiveTToken, params.actualCollateralToLiquidate);
    }
}