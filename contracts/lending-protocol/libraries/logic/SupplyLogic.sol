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
import {WadRayMath} from '../math/WadRayMath.sol';
import {IConnectedMessenger} from "../../interfaces/IConnectedMessenger.sol";
import {IWETH} from '../../interfaces/IWETH.sol';

/**
 * @title SupplyLogic library
 * @author Trava | inspired by Aave
 * @notice Implements the base logic for deposit/withdraw
 */
library SupplyLogic {
    
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using WadRayMath for uint256;

    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount,
        bool returnNative
    );
    event WithdrawOnCall(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount,
        bool returnNative
    );
    event WithdrawOnCallFailed(
        address indexed reserve,
        address indexed user,
        address indexed to
    );
    event WithdrawOnCallFullDetails(
        uint8 indexed header,
        address indexed reserve,
        address indexed user,
        address to,
        uint256 amount,
        uint256 amountToWithdraw,
        uint256 amountScaled,
        uint256 amountScaledChanged,
        uint256 amountScaledMintedToTreasury,
        bool returnNative
    );

    /**
     * @dev Deposit logic
     * @param reservesData The state of all the reserves
     * @param connectedMessenger message sender
     * @param getUniversalMessenger message receiver
     * @param params The additional parameters needed to execute the deposit function
     */
    function executeDeposit(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        IConnectedMessenger connectedMessenger,
        address getUniversalMessenger,
        DataTypes.ExecuteDepositParams memory params
    ) external {

        DataTypes.ReserveData storage reserve = reservesData[params.asset];

        (bool isActive, bool isFrozen, ) = reserve.configuration.getFlags();

        require(params.amount != 0, "invalid amount");
        require(isActive, "reserve not active");
        require(!isFrozen, "reserve frozen");

        require(params.onBehalfOf != reserve.tTokenAddress, "cannot set onBehalf equal tToken");

        address tToken = reserve.tTokenAddress;

        uint256 amountScaledMintedToTreasury = reserve.updateState();
        reserve.updateInterestRates(params.asset, tToken, params.amount, 0);

        IBEP20(params.asset).safeTransferFrom(msg.sender, tToken, params.amount);
        ITToken(tToken).mint(params.onBehalfOf, params.amount, reserve.liquidityIndex);

        uint256 newBalanceOfUnderlyingAsset = IBEP20(params.asset).balanceOf(reserve.tTokenAddress);

        bytes memory crossChainMsg = abi.encode(
            // user data
            params.onBehalfOf,
            params.asset, 
            params.amount.rayDiv(reserve.liquidityIndex), 
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
            uint8(DataTypes.MessageHeader.UpdateStateDeposit),
            crossChainMsg
        );

        emit Deposit(params.asset, msg.sender, params.onBehalfOf, params.amount, params.referralCode);
    }

    /**
     * @dev Withdraw logic
     * @param reservesData The state of all the reserves
     * @param connectedMessenger message sender
     * @param getUniversalMessenger message receiver
     * @param params The additional parameters needed to execute the withdraw function 
     */
    function executeWithdraw(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        IConnectedMessenger connectedMessenger,
        address getUniversalMessenger,
        DataTypes.ExecuteWithdrawParams memory params
    ) external {

        DataTypes.ReserveData storage reserve = reservesData[params.asset];

        (bool isActive, bool isFrozen, ) = reserve.configuration.getFlags();

        require(params.amount != 0, "invalid amount");
        require(isActive, "reserve not active");
        require(!isFrozen, "reserve frozen");

        require(params.to != reserve.tTokenAddress, "cannot set onBehalf equal tToken");

        address tToken = reserve.tTokenAddress;
        uint256 userBalance = ITToken(tToken).balanceOf(msg.sender);

        require(
            params.amount == type(uint256).max || params.amount <= userBalance,
            "user don't have enough balance"
        );

        bytes memory crossChainMsg = abi.encode(
            msg.sender,
            params.to,
            params.asset,
            params.amount,
            params.returnNative
        );

        connectedMessenger.sendWithGas{value: msg.value}(
            msg.sender,
            getUniversalMessenger,
            uint8(DataTypes.MessageHeader.ValidateWithdraw),
            crossChainMsg
        );

        emit Withdraw(params.asset, msg.sender, params.to, params.amount, params.returnNative);
    }

    /**
     * @dev WithdrawOnCall logic
     * @param reservesData The state of all the reserves
     * @param connectedMessenger message sender
     * @param getUniversalMessenger message receiver
     * @param params The additional parameters needed to execute the withdrawOnCall function
     */
    function executeWithdrawOnCall(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        IConnectedMessenger connectedMessenger,
        address getUniversalMessenger,
        address weth,
        DataTypes.ExecuteWithdrawOnCallParams memory params
    ) external {

        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        address tToken = reserve.tTokenAddress;

        uint256 amountScaledMintedToTreasury = reserve.updateState();

        uint256 amountToWithdraw = (params.isScaled) ? params.amount.rayMul(reserve.liquidityIndex) : params.amount;
        uint256 amountScaled     = (params.isScaled) ? params.amount : params.amount.rayDiv(reserve.liquidityIndex);

        reserve.updateInterestRates(params.asset, tToken, 0, amountToWithdraw);

        // Unwrap WETH and send ETH to user if needed
        if (params.returnNative && params.asset == weth) {
            ITToken(tToken).burn(
                params.user,
                address(this),
                amountToWithdraw,
                reserve.liquidityIndex
            );

            IWETH(params.asset).withdraw(amountToWithdraw);

            (bool success, ) = payable(params.to).call{ value: amountToWithdraw }("");
            require(success, "ETH transfer to user failed");
        } else {
            ITToken(tToken).burn(
                params.user,
                params.to,
                amountToWithdraw,
                reserve.liquidityIndex
            );
        }

        uint256 delta = params.amountToWithdrawScaled - amountScaled;

        bytes memory crossChainMsg = abi.encode(
            // user data
            params.user,
            params.asset, 
            delta, 
            // reserve data
            reserve.liquidityIndex,
            reserve.variableBorrowIndex,
            reserve.currentLiquidityRate,
            reserve.currentVariableBorrowRate,
            IBEP20(params.asset).balanceOf(reserve.tTokenAddress),
            // treasury
            ITToken(tToken).RESERVE_TREASURY_ADDRESS(),
            amountScaledMintedToTreasury,
            // timestamp
            uint40(block.timestamp)
        );

        connectedMessenger.send(
            params.user,
            getUniversalMessenger,
            uint8(DataTypes.MessageHeader.UpdateStateWithdraw),
            crossChainMsg
        );

        emit WithdrawOnCall(params.asset, params.user, params.to, params.amount, params.returnNative);
        emit WithdrawOnCallFullDetails(
            uint8(DataTypes.MessageHeader.UpdateStateWithdraw),
            params.asset, 
            params.user, 
            params.to, 
            params.amount, 
            amountToWithdraw, 
            amountScaled, 
            delta, 
            amountScaledMintedToTreasury, 
            params.returnNative
        );
    }

    /**
     * @dev WithdrawOnCallFailed logic
     * @param reservesData The state of all the reserves
     * @param connectedMessenger message sender
     * @param getUniversalMessenger message receiver
     * @param params The additional parameters needed to execute the withdrawOnCallFailed function
     */
    function executeWithdrawOnCallFailed(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        IConnectedMessenger connectedMessenger,
        address getUniversalMessenger,
        DataTypes.ExecuteWithdrawOnCallParams memory params
    ) external {

        DataTypes.ReserveData storage reserve = reservesData[params.asset];
        address tToken = reserve.tTokenAddress;

        uint256 amountScaledMintedToTreasury = reserve.updateState();

        bytes memory failedCrossChainMsg = abi.encode(
            // user data
            params.user,
            params.asset, 
            params.amountToWithdrawScaled,
            // reserve data
            reserve.liquidityIndex,
            reserve.variableBorrowIndex,
            reserve.currentLiquidityRate,
            reserve.currentVariableBorrowRate,
            IBEP20(params.asset).balanceOf(reserve.tTokenAddress),
            // treasury
            ITToken(tToken).RESERVE_TREASURY_ADDRESS(),
            amountScaledMintedToTreasury,
            // timestamp
            uint40(block.timestamp)
        );

        connectedMessenger.send(
            params.user,
            getUniversalMessenger,
            uint8(DataTypes.MessageHeader.UpdateStateWithdraw),
            failedCrossChainMsg
        );

        emit WithdrawOnCallFailed(params.asset, params.user, params.to);
    }

    /**
     * @dev SetUserUseReserveAsCollateral logic
     * @param connectedMessenger message sender
     * @param getUniversalMessenger message receiver
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     */
    function executeUseReserveAsCollateral(
        IConnectedMessenger connectedMessenger,
        address getUniversalMessenger,
        address asset,
        bool useAsCollateral
    ) external {

        bytes memory crossChainMsg = abi.encode(
            msg.sender,
            asset,
            useAsCollateral
        );

        connectedMessenger.send(
            msg.sender,
            getUniversalMessenger,
            uint8(DataTypes.MessageHeader.ValidateSetUserUseReserveAsCollateral),
            crossChainMsg
        );
    }
}