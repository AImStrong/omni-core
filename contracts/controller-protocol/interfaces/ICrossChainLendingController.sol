// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

import {DataTypes} from "../../controller-protocol/libraries/types/DataTypes.sol";
import {IAddressesProvider} from "./IAddressesProvider.sol";

/**
 * @title ICrossChainLendingController
 * @dev Interface for the cross-chain lending controller contract
 */
interface ICrossChainLendingController {
    event UpdateStateProcessed(
        uint8 header,
        uint256 sourceChainId,
        address onBehalfOf,
        address asset,
        uint256 amount,
        uint256 newLiquidityIndex,
        uint256 newVariableBorrowIndex,
        uint256 newLiquidityRate,
        uint256 newVariableBorrowRate,
        uint256 newBalanceOfUnderlyingAsset,
        uint40 newLastUpdateTimestampConnectedChain
    );
    event Paused(uint256 indexed chainId);
    event Unpaused(uint256 indexed chainId);
    event PausedController();
    event UnpausedController();
    event ReserveUsedAsCollateral(
        uint256 indexed chainId,
        address indexed asset,
        address indexed user,
        bool useAsCollateral
    );
    event ValidateWithdrawProcessed(
        address indexed user,
        address indexed to,
        address asset,
        uint256 amount,
        uint256 sourceChainId,
        bool isScaled,
        bool returnNative
    );
    event ValidateBorrowProcessed(
        address indexed user,
        address indexed onBehalfOf,
        address asset,
        uint256 amount,
        uint256 sourceChainId,
        bool returnNative
    );
    event LiquidationCallPhase2Processed(
        bool debtIsCover,
        address indexed debtAsset,
        address indexed collateralAsset,
        address indexed user,
        uint256 debtChainId,
        uint256 collateralChainId,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        uint256 liquidatedCollateralAmountScaled,
        address liquidator,
        bool receiveTToken
    );
    event LiquidationCallPhase3Processed(
        address indexed user,
        address indexed liquidator,
        address collateralAsset,
        uint256 actualCollateralToLiquidate,
        uint256 sourceChainId
    );
    event addedChain(uint256 chainId);

    function initialize(IAddressesProvider provider) external;

    function handleInbound(uint256 chainID, uint8 header, bytes calldata data) external;

    function addReserveToList(uint256 chainId, address asset) external;

    function dropReserveFromList(uint256 chainId, address asset) external;

    function setConfiguration(uint256 chainId, address asset, uint256 configuration) external;

    function addChain(uint256 chainId) external;

    function getChainsList() external view returns (uint256[] memory);

    function setPause(uint256 chainId, bool val) external;

    function setPauseController(bool val) external;

    function liquidationCallPhase1(
        address debtAsset,
        address collateralAsset,
        uint256 debtChainId,
        uint256 collateralChainId,
        address user,
        uint256 debtToCover,
        bool receiveTToken
    ) external;

    function getConfiguration(uint256 chainId, address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    function getReservesList(uint256 chainId) external view returns (address[] memory);

    function getReserveData(uint256 chainId, address asset) external view returns (DataTypes.ReserveData memory);

    function getPoolInfo(uint256 chainId) external view returns (
        uint256 reservesCount,
        bool paused,
        uint256 maxNumberOfReserves
    );

    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralUSD,
        uint256 totalDebtUSD,
        uint256 availableBorrowsUSD,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor,
        bool isBeingLiquidated
    );

    function paused(uint256 chainId) external view returns (bool);

    function getUserAssetData(address user, address asset, uint256 chainId) external view returns (
        uint256 income,
        uint256 debt,
        uint256 userConfig
    );

    function getUserAssetDataInDetail(address user, address asset, uint256 chainId) external view returns (
        uint256 income,
        uint256 debt,
        uint256 userConfig,
        bool isBorrowing,
        bool isUsingAsCollateral,
        uint256 scaledIncome,
        uint256 scaledDebt,
        uint256 currentLiquidityIndex,
        uint256 currentVariableBorrowIndex
    );

    function getUserApr(address user) external view returns (int256);

    function retryLiquidationCallPhase3(uint256 chainID, address user, bytes memory data) external;
}