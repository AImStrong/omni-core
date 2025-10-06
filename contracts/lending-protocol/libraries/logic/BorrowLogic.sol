// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import {DataTypes} from '../types/DataTypes.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {SafeMath} from "../../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {SafeBEP20} from "../../../dependencies/openzeppelin/contracts/SafeBEP20.sol";
import {IBEP20} from "../../../dependencies/openzeppelin/contracts/IBEP20.sol";
import {Helpers} from '../helpers/Helpers.sol';
import {ITToken} from '../../interfaces/ITToken.sol';
import {IVariableDebtToken} from '../../interfaces/IVariableDebtToken.sol';
import {WadRayMath} from '../math/WadRayMath.sol';
import {IConnectedMessenger} from "../../interfaces/IConnectedMessenger.sol";
import {DebtTokenBase} from '../../tokenization/base/DebtTokenBase.sol';
import {IWETH} from '../../interfaces/IWETH.sol';

/**
 * @title BorrowLogic library
 * @author Trava | inspired by Aave
 * @notice Implements the base logic for borrow/repay
 */
library BorrowLogic {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using WadRayMath for uint256;

    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        bool returnNative,
        uint16 indexed referral
    );
    event BorrowOnCall(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        bool returnNative
    );
    event BorrowOnCallFailed(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 allowance,
        uint256 borrowAmountScaled,
        uint256 amountScaled,
        uint256 underlying,
        bool returnNative
    );
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount
    );

    /**
     * @dev Borrow logic
     * @param reservesData The state of all the reserves
     * @param connectedMessenger message sender
     * @param getUniversalMessenger message receiver
     * @param params The additional parameters needed to execute the borrow function
     */
    function executeBorrow(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        IConnectedMessenger connectedMessenger,
        address getUniversalMessenger,
        DataTypes.ExecuteBorrowParams memory params
    ) external {

        DataTypes.ReserveData storage reserve = reservesData[params.asset];

        (bool isActive, bool isFrozen, bool borrowingEnabled) = reserve.configuration.getFlags();

        require(isActive, "reserve not active");
        require(!isFrozen, "reserve frozev");
        require(params.amount != 0, "invalid amount");
        require(borrowingEnabled, "borrowing not enable");

        bytes memory crossChainMsg = abi.encode(
            msg.sender,
            params.onBehalfOf,
            params.asset,
            params.amount,
            params.returnNative
        );

        connectedMessenger.sendWithGas{value: msg.value}(
            msg.sender,
            getUniversalMessenger,
            uint8(DataTypes.MessageHeader.ValidateBorrow),
            crossChainMsg
        );

        emit Borrow(params.asset, msg.sender, params.onBehalfOf, params.amount, params.returnNative, params.referralCode);
    }

    /**
     * @dev BorrowOnCall logic
     * @param reservesData The state of all the reserves
     * @param connectedMessenger message sender
     * @param universalMessenger message receiver
     * @param params The additional parameters needed to execute the borrowOnCall function
     */
    function executeBorrowOnCall(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        IConnectedMessenger connectedMessenger,
        address universalMessenger,
        address weth,
        DataTypes.ExecuteBorrowOnCallParams memory params
    ) external {

        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        uint256 amountScaledMintedToTreasury = reserve.updateState();

        uint256 scaledAmount = params.amount.rayDiv(reserve.variableBorrowIndex);

        IVariableDebtToken(reserve.variableDebtTokenAddress).mint(
            params.user,
            params.onBehalfOf,
            params.amount,
            reserve.variableBorrowIndex
        );

        reserve.updateInterestRates(params.asset, reserve.tTokenAddress, 0, params.amount);

        // Unwrap WETH and send ETH to user if needed
        if (params.returnNative && params.asset == weth) {
            ITToken(reserve.tTokenAddress).transferUnderlyingTo(address(this), params.amount);

            IWETH(params.asset).withdraw(params.amount);

            (bool success, ) = payable(params.user).call{ value: params.amount }("");
            require(success, "ETH transfer to user failed");
        } else {
            ITToken(reserve.tTokenAddress).transferUnderlyingTo(params.user, params.amount);
        }

        uint256 delta = params.amountToBorrowScaled - scaledAmount;

        bytes memory crossChainMsg = abi.encode(
            // user data
            params.onBehalfOf,
            params.asset, 
            delta, 
            // reserve data
            reserve.liquidityIndex,
            reserve.variableBorrowIndex,
            reserve.currentLiquidityRate,
            reserve.currentVariableBorrowRate,
            IBEP20(params.asset).balanceOf(reserve.tTokenAddress),
            // treasury
            ITToken(reserve.tTokenAddress).RESERVE_TREASURY_ADDRESS(),
            amountScaledMintedToTreasury,
            // timestamp
            uint40(block.timestamp)
        );

        connectedMessenger.send(
            params.user,
            universalMessenger,
            uint8(DataTypes.MessageHeader.UpdateStateBorrow),
            crossChainMsg
        );

        emit BorrowOnCall(params.asset, params.user, params.onBehalfOf, params.amount, params.returnNative);
    }

    /**
     * @dev BorrowOnCallFailed logic
     * @param reservesData The state of all the reserves
     * @param connectedMessenger message sender
     * @param universalMessenger message receiver
     * @param params The additional parameters needed to execute the borrowOnCallFailed function
     */
    function executeBorrowOnCallFailed(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        IConnectedMessenger connectedMessenger,
        address universalMessenger,
        DataTypes.ExecuteBorrowOnCallParams memory params
    ) external {

        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        uint256 amountScaledMintedToTreasury = reserve.updateState();

        uint256 allowance = (params.user == params.onBehalfOf) ?
            type(uint256).max : 
            DebtTokenBase(reserve.variableDebtTokenAddress).borrowAllowance(params.onBehalfOf, params.user);

        uint256 scaledAmount = params.amount.rayDiv(reserve.variableBorrowIndex);

        bytes memory failedCrossChainMsg = abi.encode(
            // user data
            params.onBehalfOf,
            params.asset, 
            params.amountToBorrowScaled,
            // reserve data
            reserve.liquidityIndex,
            reserve.variableBorrowIndex,
            reserve.currentLiquidityRate,
            reserve.currentVariableBorrowRate,
            IBEP20(params.asset).balanceOf(reserve.tTokenAddress),
            // treasury
            ITToken(reserve.tTokenAddress).RESERVE_TREASURY_ADDRESS(),
            amountScaledMintedToTreasury,
            // timestamp
            uint40(block.timestamp)
        );

        connectedMessenger.send(
            params.user,
            universalMessenger,
            uint8(DataTypes.MessageHeader.UpdateStateBorrow),
            failedCrossChainMsg
        );

        emit BorrowOnCallFailed(
            params.asset, 
            params.user, 
            params.onBehalfOf, 
            params.amount, 
            allowance, 
            params.amountToBorrowScaled, 
            scaledAmount,
            IBEP20(params.asset).balanceOf(reserve.tTokenAddress),
            params.returnNative
        );
    }

    /**
     * @dev Repay logic
     * @param reservesData The state of all the reserves
     * @param connectedMessenger message sender
     * @param getUniversalMessenger message receiver
     * @param params The additional parameters needed to execute the repay function
     */
    function executeRepay(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        IConnectedMessenger connectedMessenger,
        address getUniversalMessenger,
        DataTypes.ExecuteRepayParams memory params
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        uint256 variableDebt = Helpers.getUserCurrentDebt(params.onBehalfOf, reserve);

        (bool isActive, bool isFrozen, ) = reserve.configuration.getFlags();

        require(params.amount != 0, "invalid amount");
        require(isActive, "reserve not active");
        require(!isFrozen, "reserve frozen");
        
        require(
            params.amount != type(uint256).max || msg.sender == params.onBehalfOf,
            "no explicit amount to repay on behalf"
        );

        uint256 paybackAmount = variableDebt;
        if (params.amount < paybackAmount) {
            paybackAmount = params.amount;
        }

        uint256 amountScaledMintedToTreasury = reserve.updateState();

        IVariableDebtToken(reserve.variableDebtTokenAddress).burn(
            params.onBehalfOf,
            paybackAmount,
            reserve.variableBorrowIndex
        );

        address tToken = reserve.tTokenAddress;
        reserve.updateInterestRates(params.asset, tToken, paybackAmount, 0);
        IBEP20(params.asset).safeTransferFrom(msg.sender, tToken, paybackAmount);
        ITToken(tToken).handleRepayment(msg.sender, paybackAmount);

        uint256 newBalanceOfUnderlyingAsset = IBEP20(params.asset).balanceOf(reserve.tTokenAddress);

        bytes memory crossChainMsg = abi.encode(
            // user data
            params.onBehalfOf,
            params.asset, 
            paybackAmount.rayDiv(reserve.variableBorrowIndex),
            // reserve data 
            reserve.liquidityIndex,
            reserve.variableBorrowIndex,
            reserve.currentLiquidityRate,
            reserve.currentVariableBorrowRate,
            newBalanceOfUnderlyingAsset,
            // treasury
            ITToken(tToken).RESERVE_TREASURY_ADDRESS(),
            amountScaledMintedToTreasury,
            // timestamp
            uint40(block.timestamp)
        );

        connectedMessenger.send(
            msg.sender,
            getUniversalMessenger,
            uint8(DataTypes.MessageHeader.UpdateStateRepay),
            crossChainMsg
        );

        emit Repay(params.asset, params.onBehalfOf, msg.sender, paybackAmount);
    }
}