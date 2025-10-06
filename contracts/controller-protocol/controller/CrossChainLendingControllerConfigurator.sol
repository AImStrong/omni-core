// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {VersionedInitializable} from "../libraries/upgradeability/VersionedInitializable.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {ICrossChainLendingControllerConfigurator} from "../interfaces/ICrossChainLendingControllerConfigurator.sol";
import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";
import {ICrossChainLendingController} from "../interfaces/ICrossChainLendingController.sol";
import {
    InitializableImmutableAdminUpgradeabilityProxy
} from "../libraries/upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";

/**
 * @title CrossChainLendingControllerConfigurator contract
 * @author Trava
 * @notice Implements the configuration methods for the Trava protocol
 * @dev Implements ICrossChainLendingControllerConfigurator interface
 **/
contract CrossChainLendingControllerConfigurator is 
    VersionedInitializable, 
    ICrossChainLendingControllerConfigurator
{
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    ICrossChainLendingController internal controller;
    IAddressesProvider internal _addressesProvider;

    modifier onlyControllerOwner() {
        require(
            _addressesProvider.getControllerOwner() == msg.sender,
            Errors.CRC_CALLER_NOT_CONTROLLER_OWNER
        );
        _;
    }

    modifier onlyControllerUpdateManager() {
        require(
            _addressesProvider.getControllerUpdateManager() == msg.sender,
            Errors.CRC_CALLER_NOT_UPDATE_MANAGER
        );
        _;
    }

    uint256 public constant CONFIGURATOR_REVISION = 0x6;

    function getRevision() internal pure override returns (uint256) {
        return CONFIGURATOR_REVISION;
    }

    /**
     * @notice Initializes the configurator
     * @param provider The address provider contract
     */
    function initialize(IAddressesProvider provider) external initializer {
        _addressesProvider = provider;
        controller = ICrossChainLendingController(_addressesProvider.getCrossChainLendingController());
    }

    /**
     * @dev Initialize reserves in batch
     * @param input Array of InitReserveInput structs
     */
    function batchInitReserve(InitReserveInput[] calldata input) external onlyControllerOwner {
        for (uint256 i = 0; i < input.length; i++) {
            _initReserve(input[i]);
            _configureReserveAsCollateral(
                input[i].chainId,
                input[i].underlyingAsset,
                input[i].baseLTVAsCollateral,
                input[i].liquidationThreshold,
                input[i].liquidationBonus
            );
        }
    }

    /**
     * @dev Internal function to initialize a reserve
     * @param input The reserve initialization data
     */
    function _initReserve(InitReserveInput calldata input) internal {
        controller.addReserveToList(
            input.chainId,
            input.underlyingAsset
        );

        DataTypes.ReserveConfigurationMap memory currentConfig = 
            controller.getConfiguration(input.chainId, input.underlyingAsset);
            
        currentConfig.setDecimals(input.underlyingAssetDecimals);
        currentConfig.setActive(true);
        currentConfig.setFrozen(false);
        
        controller.setConfiguration(
            input.chainId,
            input.underlyingAsset,
            currentConfig.data
        );

        emit ReserveInitialized(
            input.chainId,
            input.underlyingAsset
        );
    }

    /**
     * @dev Configures the reserve collateralization parameters
     * @param chainId The chain ID
     * @param asset The address of the underlying asset
     * @param ltv The loan to value of the asset when used as collateral
     * @param liquidationThreshold The threshold at which loans using this asset as collateral will be considered undercollateralized
     * @param liquidationBonus The bonus liquidators receive to liquidate this asset
     */
    function configureReserveAsCollateral(
        uint256 chainId,
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) external onlyControllerUpdateManager {
        _configureReserveAsCollateral(
            chainId,
            asset,
            ltv,
            liquidationThreshold,
            liquidationBonus
        );
        
        emit ReserveConfiguredAsCollateral(
            chainId,
            asset,
            ltv,
            liquidationThreshold,
            liquidationBonus
        );
    }

    /**
     * @dev Internal function to configure reserve as collateral
     */
    function _configureReserveAsCollateral(
        uint256 chainId,
        address asset,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus
    ) internal {
        DataTypes.ReserveConfigurationMap memory currentConfig = controller.getConfiguration(chainId, asset);

        //validation of the parameters: the LTV can
        //only be lower or equal than the liquidation threshold
        require(ltv <= liquidationThreshold, Errors.CRC_INVALID_LTV_THRESHOLD);

        if (liquidationThreshold != 0) {
            //liquidation bonus must be bigger than 100.00%
            require(
                liquidationBonus > PercentageMath.PERCENTAGE_FACTOR,
                Errors.CRC_INVALID_BONUS
            );
            require(
                liquidationThreshold.percentMul(liquidationBonus) <= PercentageMath.PERCENTAGE_FACTOR,
                Errors.CRC_INVALID_THRESHOLD_BONUS_PRODUCT
            );
        } else {
            require(liquidationBonus == 0, Errors.CRC_INVALID_ZERO_BONUS);
            _checkNoLiquidity(chainId, asset);
        }

        currentConfig.setLtv(ltv);
        currentConfig.setLiquidationThreshold(liquidationThreshold);
        currentConfig.setLiquidationBonus(liquidationBonus);

        controller.setConfiguration(chainId, asset, currentConfig.data);
    }

    /**
     * @dev Enables borrowing on a reserve
     * @param chainId The chain ID
     * @param asset The address of the underlying asset
     * @param variableBorrowRateEnabled True if variable borrow rate needs to be enabled
     * @param stableBorrowRateEnabled True if stable borrow rate needs to be enabled
     */
    function setReserveBorrowingEnabled(
        uint256 chainId,
        address asset,
        bool variableBorrowRateEnabled,
        bool stableBorrowRateEnabled
    ) external onlyControllerOwner {
        DataTypes.ReserveConfigurationMap memory currentConfig = controller.getConfiguration(chainId, asset);
        currentConfig.setBorrowingEnabled(variableBorrowRateEnabled);
        currentConfig.setStableRateBorrowingEnabled(stableBorrowRateEnabled);

        controller.setConfiguration(chainId, asset, currentConfig.data);

        emit SetReserveBorrowingEnabled(chainId, asset, variableBorrowRateEnabled, stableBorrowRateEnabled);
    }

    /**
     * @dev Activates a reserve
     * @param chainId The chain ID
     * @param asset The address of the underlying asset
     * @param active True if set reserve active
     */
    function setReserveActive(uint256 chainId, address asset, bool active) external onlyControllerUpdateManager {
        DataTypes.ReserveConfigurationMap memory currentConfig = controller.getConfiguration(chainId, asset);

        currentConfig.setActive(active);

        controller.setConfiguration(chainId, asset, currentConfig.data);

        emit SetReserveActive(chainId, asset, active);
    }

    /**
     * @dev Freezes a reserve
     * @param chainId The chain ID
     * @param asset The address of the underlying asset
     * @param freeze True if set reserve frozen
     */
    function setReserveFrozen(uint256 chainId, address asset, bool freeze) external onlyControllerOwner {
        DataTypes.ReserveConfigurationMap memory currentConfig = controller.getConfiguration(chainId, asset);

        currentConfig.setFrozen(freeze);

        controller.setConfiguration(chainId, asset, currentConfig.data);

        emit SetReserveFrozen(chainId, asset, freeze);
    }

    /**
     * @dev Change reserve decimals, probably need this function because of some bug when add reserve
     * @param chainId The chain ID
     * @param asset The address of the underlying asset of the reserve
     * @param decimals new reserve decimals
     **/
    function setReserveDecimals(uint256 chainId, address asset, uint256 decimals) external onlyControllerOwner {
        DataTypes.ReserveConfigurationMap memory currentConfig = controller.getConfiguration(chainId, asset);

        currentConfig.setDecimals(decimals);

        controller.setConfiguration(chainId, asset, currentConfig.data);

        emit ReserveDecimalsChanged(chainId, asset, decimals);
    }

    function _checkNoLiquidity(uint256 chainId, address asset) internal view { //@dev: aave v3 using check no suppliers
        DataTypes.ReserveData memory reserveData = controller.getReserveData(chainId, asset);

        uint256 availableLiquidity = reserveData.balanceOfUnderlyingAsset;

        require(
            availableLiquidity == 0 && reserveData.currentLiquidityRate == 0,
            Errors.CRC_RESERVE_HAS_LIQUIDITY
        );
    }

    /**
     * @dev Sets the pause state of the pool
     * @param chainId The chain ID
     * @param val True to pause, false to unpause
     */
    function setPoolPause(uint256 chainId, bool val) external onlyControllerUpdateManager {
        controller.setPause(chainId, val);
    }

    /**
     * @dev Sets the pause state of the controller
     * @param val True to pause, false to unpause
     */
    function setControllerPause(bool val) external onlyControllerUpdateManager {
        controller.setPauseController(val);
    }

    /**
     * @dev Adds a new chain to the controller
     * @param chainId The ID of the chain to add
     */
    function addChainToController(uint256 chainId) external onlyControllerOwner {
        controller.addChain(chainId);
    }

    /**
     * @dev Drop a reserve from the list of reserves
     * @param chainId The chain ID
     * @param asset The address of the underlying asset of the reserve
     */
    function dropReserveFromList(uint256 chainId, address asset) external onlyControllerOwner {
        controller.dropReserveFromList(chainId, asset);
    }
} 