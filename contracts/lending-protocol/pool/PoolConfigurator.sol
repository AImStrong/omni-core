// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

pragma experimental ABIEncoderV2;

import {SafeMath} from "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {VersionedInitializable} from "../libraries/upgradeability/VersionedInitializable.sol";
import {
    InitializableImmutableAdminUpgradeabilityProxy
} from "../libraries/upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IBEP20} from "../../dependencies/openzeppelin/contracts/IBEP20.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IInitializableDebtToken} from "../interfaces/IInitializableDebtToken.sol";
import {IInitializableTToken} from "../interfaces/IInitializableTToken.sol";
import {ITravaIncentivesController} from "../interfaces/ITravaIncentivesController.sol";
import {IPoolConfigurator} from "../interfaces/IPoolConfigurator.sol";

/**
 * @title PoolConfigurator contract
 * @author Trava
 * @dev Implements the configuration methods for the Trava protocol
 **/

contract PoolConfigurator is VersionedInitializable,IPoolConfigurator {
    using SafeMath for uint256;
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    
    IAddressesProvider internal addressesProvider;
    IPool internal pool;

    modifier onlyGovernance {
        require(
            addressesProvider.getGovernance() == msg.sender,
            "Caller not pool owner"
        );
        _;
    }
    
    uint256 public constant CONFIGURATOR_REVISION = 0x5;

    /**
     * @dev Get the revision of the poolConfigurator
     * @return The CONFIGURATOR_REVISION
     **/
    function getRevision() internal pure override returns (uint256) {
        return CONFIGURATOR_REVISION;
    }

    /**
     * @dev Function is invoked by the proxy contract when the PoolConfigurator contract is added to the
     * AddressProviderFactory of the market.
     * @param provider The address of the PoolAddressesProvider
     **/
    function initialize(address provider) external initializer {   
        addressesProvider = IAddressesProvider(provider);
        pool = IPool(addressesProvider.getPool());
    }

    /**
     * @dev Initializes reserves in batch
     * It includes 3 steps: _initReserve, _configureReserveAsCollateral, _setReserveFactor
     * @param input The InitReserveInput, see the detail in IPoolConfigurator
     **/
    function batchInitReserve(InitReserveInput[] calldata input) external onlyGovernance() {
        IPool cachedPool = pool;
        for (uint256 i = 0; i < input.length; i++) {
            _initReserve(cachedPool, input[i]);
            _setReserveFactor(
                input[i].underlyingAsset,
                input[i].reserveFactor
            );
        }
    }

    /**
     * @dev Initializes reserve
     **/
    function _initReserve(IPool _pool, InitReserveInput calldata input) internal {
        address tTokenProxyAddress =
            _initTokenWithProxy(
                input.tTokenImpl,
                abi.encodeWithSelector(
                    IInitializableTToken.initialize.selector,
                    _pool,
                    input.treasury,
                    input.underlyingAsset,
                    ITravaIncentivesController(input.incentivesController),
                    input.underlyingAssetDecimals,
                    input.tTokenName,
                    input.tTokenSymbol,
                    input.params
                )
            );
        address variableDebtTokenProxyAddress =
            _initTokenWithProxy(
                input.variableDebtTokenImpl,
                abi.encodeWithSelector(
                    IInitializableDebtToken.initialize.selector,
                    _pool,
                    input.underlyingAsset,
                    ITravaIncentivesController(input.incentivesController),
                    input.underlyingAssetDecimals,
                    input.variableDebtTokenName,
                    input.variableDebtTokenSymbol,
                    input.params
                )
            );
        require(input.underlyingAsset != address(0), "underlyingAsset cannot be 0 address");
        require(tTokenProxyAddress != address(0), "tToken cannot be 0 address");
        require(variableDebtTokenProxyAddress != address(0), "variableDebt cannot be 0 address");
        address asset = input.underlyingAsset;

        _pool.initReserve(
            asset,
            tTokenProxyAddress,
            variableDebtTokenProxyAddress,
            input.interestRateStrategyAddress        
        );
        DataTypes.ReserveConfigurationMap memory currentConfig =
            _pool.getConfiguration(input.underlyingAsset);
        currentConfig.setDecimals(input.underlyingAssetDecimals);
        currentConfig.setActive(true);
        currentConfig.setFrozen(false);
        _pool.setConfiguration(input.underlyingAsset, currentConfig.data);
        emit ReserveInitialized(
            input.underlyingAsset,
            tTokenProxyAddress,
            variableDebtTokenProxyAddress,
            input.interestRateStrategyAddress
        );
    }

    /**
     * @dev rescue tokens
     */
    function rescueTokens(address token, address to, uint256 amount) external onlyGovernance {
        pool.rescueTokens(token, to, amount);
        emit TokensRescued(token, to, amount);
    }

    /**
     * @dev drop reserve
     */
    function dropReserve(address asset) external onlyGovernance {
        pool.dropReserve(asset);
        emit ReserveDropped(asset);
    }

    /**
     * @dev Updates the tToken implementation for the reserve
     **/
    function updateTToken(UpdateTTokenInput calldata input) external onlyGovernance {
        IPool cachedPool = pool;

        DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

        uint256 decimals = cachedPool.getConfiguration(input.asset).getDecimalsMemory();

        bytes memory encodedCall =
            abi.encodeWithSelector(
                IInitializableTToken.initialize.selector,
                cachedPool,
                input.treasury,
                input.asset,
                input.incentivesController,
                decimals,
                input.name,
                input.symbol,
                input.params
            );

        _upgradeTokenImplementation(
            reserveData.tTokenAddress,
            input.implementation,
            encodedCall
        );

        emit TTokenUpgraded(
            input.asset,
            reserveData.tTokenAddress,
            input.implementation
        );
    }

    /**
     * @dev Updates the variable debt token implementation for the asset
     **/
    function updateVariableDebtToken(UpdateDebtTokenInput calldata input) external onlyGovernance {
        IPool cachedPool = pool;

        DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

        uint256 decimals = cachedPool.getConfiguration(input.asset).getDecimalsMemory();

        bytes memory encodedCall =
            abi.encodeWithSelector(
                IInitializableDebtToken.initialize.selector,
                cachedPool,
                input.asset,
                input.incentivesController,
                decimals,
                input.name,
                input.symbol,
                input.params
            );

        _upgradeTokenImplementation(
            reserveData.variableDebtTokenAddress,
            input.implementation,
            encodedCall
        );

        emit VariableDebtTokenUpgraded(
            input.asset,
            reserveData.variableDebtTokenAddress,
            input.implementation
        );
    }

    /**
     * @dev Enables borrowing on a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param variableBorrowRateEnabled True if variable borrow rate needs to be enabled by default on this reserve
     * @param stableBorrowRateEnabled True if stable borrow rate needs to be enabled by default on this reserve
     **/
    function setReserveBorrowingEnabled(
        address asset,
        bool variableBorrowRateEnabled,
        bool stableBorrowRateEnabled
    ) external onlyGovernance {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        currentConfig.setBorrowingEnabled(variableBorrowRateEnabled);
        currentConfig.setStableRateBorrowingEnabled(stableBorrowRateEnabled);

        pool.setConfiguration(asset, currentConfig.data);

        emit SetReserveBorrowingEnabled(asset, variableBorrowRateEnabled, stableBorrowRateEnabled);
    }

    /**
     * @dev Activates a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param active True if set reserve active
     **/
    function setReserveActive(address asset, bool active) external onlyGovernance {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        currentConfig.setActive(active);

        pool.setConfiguration(asset, currentConfig.data);

        emit SetReserveActive(asset, active);
    }

    /**
     * @dev Freezes a reserve. A frozen reserve doesn't allow any new deposit, borrow or rate swap
     *  but allows repayments, liquidations, rate rebalances and withdrawals
     * @param asset The address of the underlying asset of the reserve
     * @param frozen True if set reserve freeze
     **/
    function setReserveFrozen(address asset, bool frozen) external onlyGovernance {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        currentConfig.setFrozen(frozen);

        pool.setConfiguration(asset, currentConfig.data);

        emit SetReserveFrozen(asset, frozen);
    }

    /**
     * @dev Change reserve decimals, probably need this function because of some bug when add reserve
     * @param asset The address of the underlying asset of the reserve
     * @param decimals new reserve decimals
     **/
    function setReserveDecimals(address asset, uint256 decimals) external onlyGovernance {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        currentConfig.setDecimals(decimals);

        pool.setConfiguration(asset, currentConfig.data);

        emit ReserveDecimalsChanged(asset, decimals);
    }

    /**
     * @dev Updates the reserve factor of a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param reserveFactor The new reserve factor of the reserve
     **/
    function _setReserveFactor(address asset, uint256 reserveFactor) internal {
        DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(asset);

        currentConfig.setReserveFactor(reserveFactor);

        pool.setConfiguration(asset, currentConfig.data);

        emit ReserveFactorChanged(asset, reserveFactor);
    }

    function setReserveFactor(address asset, uint256 reserveFactor) external onlyGovernance{
        _setReserveFactor(asset, reserveFactor);
    }
  
    /**
     * @dev Sets the interest rate strategy of a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param rateStrategyAddress The new address of the interest strategy contract
     **/
    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    ) external onlyGovernance {
        pool.setReserveInterestRateStrategyAddress(asset, rateStrategyAddress);
        emit ReserveInterestRateStrategyChanged(asset, rateStrategyAddress);
    }

    /**
     * @dev pauses or unpauses all the actions of the protocol, including tToken transfers
     * @param val true if protocol needs to be paused, false otherwise
     **/
    function setPoolPause(bool val) external onlyGovernance {
        pool.setPause(val);
    }

    function _initTokenWithProxy(
        address implementation,
        bytes memory initParams
    ) internal returns (address) {
        InitializableImmutableAdminUpgradeabilityProxy proxy =
            new InitializableImmutableAdminUpgradeabilityProxy(address(this));

        proxy.initialize(implementation, initParams);

        return address(proxy);
    }

    function _upgradeTokenImplementation(
        address proxyAddress,
        address implementation,
        bytes memory initParams
    ) internal {
        InitializableImmutableAdminUpgradeabilityProxy proxy =
            InitializableImmutableAdminUpgradeabilityProxy(
                payable(proxyAddress)
            );

        proxy.upgradeToAndCall(implementation, initParams);
    }

    function _checkNoLiquidity(address asset) internal view {
        DataTypes.ReserveData memory reserveData = pool.getReserveData(asset);

        uint256 availableLiquidity = IBEP20(asset).balanceOf(reserveData.tTokenAddress);

        require(
            availableLiquidity == 0 && reserveData.currentLiquidityRate == 0,
            "pool liquidity not 0"
        );
    }
}