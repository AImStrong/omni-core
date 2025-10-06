// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

import {DataTypes} from "../../controller-protocol/libraries/types/DataTypes.sol";
import "./ICrossChainLendingController.sol";

/**
 * @title ICrossChainLendingControllerConfigurator
 * @author Trava
 * @notice Defines the configuration interface for the Cross Chain Lending Controller
 */
interface ICrossChainLendingControllerConfigurator {
    event ReserveInitialized(uint256 indexed chainId, address indexed underlyingAsset);
    event SetReserveBorrowingEnabled(uint256 chainId, address indexed asset, bool variableBorrowRateEnabled, bool stableBorrowRateEnabled);
    event SetReserveActive(uint256 indexed chainId, address indexed asset, bool active);
    event SetReserveFrozen(uint256 indexed chainId, address indexed asset, bool freeze);
    event ReserveConfiguredAsCollateral(
        uint256 indexed chainId,
        address indexed asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    );
    event ReserveDecimalsChanged(uint256 chainId, address indexed asset, uint256 decimals);

    struct InitReserveInput {
        uint256 chainId;
        address underlyingAsset;
        uint8 underlyingAssetDecimals;
        uint256 baseLTVAsCollateral;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
    }

    function addChainToController(uint256 chainId) external ;

    function batchInitReserve(InitReserveInput[] calldata input) external;

    function configureReserveAsCollateral(
        uint256 chainId,
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external;

    function setReserveBorrowingEnabled(
        uint256 chainId, 
        address asset, 
        bool variableBorrowRateEnabled, 
        bool stableBorrowRateEnabled
    ) external;

    function setReserveActive(uint256 chainId, address asset, bool active) external;

    function setReserveFrozen(uint256 chainId, address asset, bool freeze) external;

    function setReserveDecimals(uint256 chainId, address asset, uint256 decimals) external;

    function setPoolPause(uint256 chainId, bool val) external;

    function setControllerPause(bool val) external;
}