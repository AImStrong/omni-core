// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

import {DataTypes} from '../types/DataTypes.sol';
import {ReserveLogic} from './ReserveLogic.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {Address} from "../../../dependencies/openzeppelin/contracts/Address.sol";
import {SafeMath} from "../../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {SafeBEP20} from "../../../dependencies/openzeppelin/contracts/SafeBEP20.sol";
import {IBEP20} from "../../../dependencies/openzeppelin/contracts/IBEP20.sol";
import {Helpers} from '../helpers/Helpers.sol';
import {ITToken} from '../../interfaces/ITToken.sol';
import {IVariableDebtToken} from '../../interfaces/IVariableDebtToken.sol';
import {IReserveInterestRateStrategy} from '../../interfaces/IReserveInterestRateStrategy.sol';

/**
 * @title PoolLogic library
 * @author Trava | inspired by Aave
 * @notice Implements the functions to initialize reserves and update aTokens and debtTokens
 */
library PoolLogic {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    /**
     * @notice Initialize an asset reserve and add the reserve to the list of reserves
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param params Additional parameters needed for initiation
     * @return true if appended, false if inserted at existing empty spot
     */
    function executeInitReserve(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        DataTypes.InitReserveParams memory params
    ) external returns (bool) {
        require(Address.isContract(params.asset), "asset is not a contract");

        bool reserveAlreadyAdded =
            reservesData[params.asset].id != 0 || reservesList[0] == params.asset;

        require(!reserveAlreadyAdded, "reserve already added");

        ITToken tToken = ITToken(params.tTokenAddress);
        IVariableDebtToken variableDebtToken = IVariableDebtToken(params.variableDebtTokenAddress);
        IReserveInterestRateStrategy reserveInterestRateStrategy = IReserveInterestRateStrategy(params.reserveInterestRateStrategyAddress);

        reservesData[params.asset].init(
            tToken,
            variableDebtToken,
            reserveInterestRateStrategy
        );

        for (uint8 i = 0; i < params.reservesCount; i++) {
            if (reservesList[i] == address(0)) {
                reservesData[params.asset].id = i;
                reservesList[i] = params.asset;
                return false;
            }
        }

        require(params.reservesCount < params.maxNumberOfReserves, "no more reserve allowed");
        reservesData[params.asset].id = uint8(params.reservesCount);
        reservesList[params.reservesCount] = params.asset;
        return true;
    }

    /**
     * @notice Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function executeRescueTokens(address token, address to, uint256 amount) external {
        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            (bool ok,) = to.call{value: amount}("");
            require(ok, "rescue tokens failed");
        }
        else {
            IBEP20(token).safeTransfer(to, amount);
        }
    }

    /**
     * @notice Drop a reserve
     * @param reservesData The state of all the reserves
     * @param reservesList The addresses of all the active reserves
     * @param asset The address of the underlying asset of the reserve
     */
    function executeDropReserve(
        mapping(address => DataTypes.ReserveData) storage reservesData,
        mapping(uint256 => address) storage reservesList,
        address asset
    ) external {
        DataTypes.ReserveData storage reserve = reservesData[asset];
        require(asset != address(0), "asset is 0x0");
        require(reserve.id != 0 || reservesList[0] == asset, "asset not listed");
        require(
            IBEP20(reserve.variableDebtTokenAddress).totalSupply() == 0,
            "reserve has debt"
        );
        require(
            IBEP20(reserve.tTokenAddress).totalSupply() == 0 && IBEP20(asset).balanceOf(reserve.tTokenAddress) == 0,
            "reserve has supply"
        );
        reservesList[reservesData[asset].id] = address(0);
        delete reservesData[asset];
    }
}