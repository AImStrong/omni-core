// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {IBEP20} from "../../dependencies/openzeppelin/contracts/IBEP20.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";
import {PoolStorage} from "./PoolStorage.sol";
import {IReserveInterestRateStrategy} from "../interfaces/IReserveInterestRateStrategy.sol";
import {VersionedInitializable} from '../libraries/upgradeability/VersionedInitializable.sol';
import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {SupplyLogic} from "../libraries/logic/SupplyLogic.sol";
import {BorrowLogic} from "../libraries/logic/BorrowLogic.sol";
import {PoolLogic} from "../libraries/logic/PoolLogic.sol";
import {LiquidationLogic} from "../libraries/logic/LiquidationLogic.sol";
import {IConnectedMessenger} from "../interfaces/IConnectedMessenger.sol";
import {IncentivesController} from "../incentives/IncentivesController.sol";
import {IncentivesFactory} from "../incentives/IncentivesFactory.sol";
import {ITToken} from "../interfaces/ITToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";

/**
 * @title Pool contract
 * @dev Main point of interaction with a protocol's market
 * - Users can:
 *   # Deposit
 *   # Withdraw
 *   # Borrow
 *   # Repay
 *   # Enable/disable their deposits as collateral rebalance stable rate borrow positions
 *   # Move assets to connected pool
 * - To be covered by a proxy contract, owned by the PoolAddressesProvider of the specific market
 * - All admin functions are callable by the PoolConfigurator contract defined also in the
 *   PoolAddressesProvider
 * @author Trava
 **/

contract Pool is VersionedInitializable, IPool, PoolStorage {
    using ReserveLogic for DataTypes.ReserveData;
    using WadRayMath for uint256;

    uint256 public constant POOL_REVISION = 0x26;

    modifier whenNotPaused() {
        _whenNotPaused();
        _;
    }

    modifier onlyPoolConfigurator() {
        _onlyPoolConfigurator();
        _;
    }

    modifier onlyConnectedMessenger() {
        require(
            _addressesProvider.getConnectedMessenger() == msg.sender,
            "caller not connected messenger"
        );
        _;
    }

    modifier onlyGovernance() {
        require(
            _addressesProvider.getGovernance() == msg.sender,
            "caller not governance"
        );
        _;
    }

    function _whenNotPaused() internal view {
        require(!_paused, "pool paused");
    }

    function _onlyPoolConfigurator() internal view {
        require(
            _addressesProvider.getPoolConfigurator() == msg.sender,
            "Caller not pool configurator"
        );
    }

    function getRevision() internal pure override returns (uint256) {
        return POOL_REVISION;
    }

    // @inheritdoc IPool
    function initialize(IAddressesProvider provider) external initializer {
        _addressesProvider = provider;
        _maxNumberOfReserves = 128;
    }

    // @inheritdoc IPool
    function handleInbound(
        uint8 header,
        bytes calldata data
    ) external override onlyConnectedMessenger {

        require(header <= uint8(type(DataTypes.MessageHeader).max), "invalid message header");
        DataTypes.MessageHeader msgHeader = DataTypes.MessageHeader(header);

        if      (msgHeader == DataTypes.MessageHeader.ValidateWithdraw)                      _withdrawOnCall(data);
        else if (msgHeader == DataTypes.MessageHeader.ValidateBorrow)                        _borrowOnCall(data);
        else if (msgHeader == DataTypes.MessageHeader.ProcessLiquidationCallPhase2)          _receiveLiquidatorUnderlying(data);
        else if (msgHeader == DataTypes.MessageHeader.ProcessLiquidationCallPhase3)          _liquidateCollateral(data);
        else if (msgHeader == DataTypes.MessageHeader.RetryProcessLiquidationCallPhase3)     _liquidateCollateral(data);
        else {
            revert("invalid message header");
        }
    }

    // @inheritdoc IPool
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external override whenNotPaused {

        IConnectedMessenger connectedMessenger = IConnectedMessenger(payable(_addressesProvider.getConnectedMessenger()));
        require(
            address(connectedMessenger) != address(0), 
            "connected messenger not set"
        );

        IncentivesFactory factory = IncentivesFactory(IAddressesProvider(_addressesProvider).getAddress("INCENTIVES_FACTORY"));
        if (address(factory) != address(0)) {
            IncentivesController reward = IncentivesController(factory.getVault(asset));
            if (address(reward) != address(0)) reward.poolTrigger(onBehalfOf);
        }

        SupplyLogic.executeDeposit(
            _reserves, 
            connectedMessenger,
            _addressesProvider.getUniversalMessenger(),
            DataTypes.ExecuteDepositParams({
                asset: asset,
                amount: amount,
                onBehalfOf: onBehalfOf,
                referralCode: referralCode
            })
        );
    }

    // @inheritdoc IPool
    function withdraw(
        address asset,
        uint256 amount,
        address to,
        bool returnNative
    ) external payable override whenNotPaused {

        if (returnNative) {
            require(asset == _addressesProvider.getWeth(), "asset not weth");
        }

        IConnectedMessenger connectedMessenger = IConnectedMessenger(payable(_addressesProvider.getConnectedMessenger()));
        require(
            address(connectedMessenger) != address(0), 
            "connected messenger not set"
        );

        SupplyLogic.executeWithdraw(
            _reserves,
            connectedMessenger,
            _addressesProvider.getUniversalMessenger(),
            DataTypes.ExecuteWithdrawParams({
                asset: asset,
                amount: amount,
                to: to,
                returnNative: returnNative
            })
        );
    }
    
    // validate withdraw success
    function _withdrawOnCall(bytes memory data) internal {
        IConnectedMessenger connectedMessenger = IConnectedMessenger(payable(_addressesProvider.getConnectedMessenger()));
        require(
            address(connectedMessenger) != address(0), 
            "connected messenger not set"
        );
        
        (
            address user,
            address to,
            address asset,
            uint256 amount,
            bool isScaled,
            bool returnNative,
            uint256 amountToWithdrawScaled
        ) = abi.decode(data, (address, address, address, uint256, bool, bool, uint256));

        IncentivesFactory factory = IncentivesFactory(IAddressesProvider(_addressesProvider).getAddress("INCENTIVES_FACTORY"));
        if (address(factory) != address(0)) {
            IncentivesController reward = IncentivesController(factory.getVault(asset));
            if (address(reward) != address(0)) reward.poolTrigger(user);
        }

        try SupplyLogic.executeWithdrawOnCall(
            _reserves, 
            connectedMessenger,
            _addressesProvider.getUniversalMessenger(),
            _addressesProvider.getWeth(),
            DataTypes.ExecuteWithdrawOnCallParams({
                user: user,
                to: to,
                asset: asset,
                amount: amount,
                isScaled: isScaled,
                returnNative: returnNative,
                amountToWithdrawScaled: amountToWithdrawScaled
            })
        ) {
            emit OnCall(true, "");
        }
        catch (bytes memory err) {
            SupplyLogic.executeWithdrawOnCallFailed(
                _reserves, 
                connectedMessenger,
                _addressesProvider.getUniversalMessenger(),
                DataTypes.ExecuteWithdrawOnCallParams({
                    user: user,
                    to: to,
                    asset: asset,
                    amount: amount,
                    isScaled: isScaled,
                    returnNative: returnNative,
                    amountToWithdrawScaled: amountToWithdrawScaled
                })
            );

            emit OnCall(false, err);
        }
    }

    // @inheritdoc IPool
    function borrow(
        address asset,
        uint256 amount,
        address onBehalfOf,
        bool returnNative,
        uint16 referralCode
    ) external payable override whenNotPaused {

        if (returnNative) {
            require(asset == _addressesProvider.getWeth(), "asset not weth");
        }

        IConnectedMessenger connectedMessenger = IConnectedMessenger(payable(_addressesProvider.getConnectedMessenger()));
        require(
            address(connectedMessenger) != address(0), 
            "connected messenger not set"
        );

        BorrowLogic.executeBorrow(
            _reserves,
            connectedMessenger,
            _addressesProvider.getUniversalMessenger(),
            DataTypes.ExecuteBorrowParams({
                asset: asset,
                amount: amount,
                returnNative: returnNative,
                referralCode: referralCode,
                onBehalfOf: onBehalfOf
            })
        );
    }

    // validate borrow success
    function _borrowOnCall(bytes memory data) internal {
        IConnectedMessenger connectedMessenger = IConnectedMessenger(payable(_addressesProvider.getConnectedMessenger()));
        require(
            address(connectedMessenger) != address(0), 
            "connected messenger not set"
        );

        (
            address user,
            address onBehalfOf,
            address asset,
            uint256 amount,
            uint256 amountToBorrowScaled,
            bool returnNative
        ) = abi.decode(data, (address, address, address, uint256, uint256, bool));

        try BorrowLogic.executeBorrowOnCall(
            _reserves,
            connectedMessenger,
            _addressesProvider.getUniversalMessenger(),
            _addressesProvider.getWeth(),
            DataTypes.ExecuteBorrowOnCallParams({
                user: user,
                onBehalfOf: onBehalfOf,
                asset: asset,
                amount: amount,
                amountToBorrowScaled: amountToBorrowScaled,
                returnNative: returnNative
            })
        ) {
            emit OnCall(true, "");
        } 
        catch (bytes memory err) {
            BorrowLogic.executeBorrowOnCallFailed(
                _reserves, 
                connectedMessenger, 
                _addressesProvider.getUniversalMessenger(), 
                DataTypes.ExecuteBorrowOnCallParams({
                    user: user,
                    onBehalfOf: onBehalfOf,
                    asset: asset,
                    amount: amount,
                    amountToBorrowScaled: amountToBorrowScaled,
                    returnNative: returnNative
                })
            );

            emit OnCall(false, err);
        }
    }
    
    // @inheritdoc IPool
    function repay(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external override whenNotPaused {

        IConnectedMessenger connectedMessenger = IConnectedMessenger(payable(_addressesProvider.getConnectedMessenger()));
        require(
            address(connectedMessenger) != address(0), 
            "connected messenger not set"
        );

        BorrowLogic.executeRepay(
            _reserves,
            connectedMessenger,
            _addressesProvider.getUniversalMessenger(),
            DataTypes.ExecuteRepayParams({
                asset: asset,
                amount: amount,
                onBehalfOf: onBehalfOf
            })
        );
    }

    // @inheritdoc IPool
    function setUserUseReserveAsCollateral(
        address asset, 
        bool useAsCollateral
    ) external payable override whenNotPaused {
        IConnectedMessenger connectedMessenger = IConnectedMessenger(payable(_addressesProvider.getConnectedMessenger()));
        require(
            address(connectedMessenger) != address(0),
            "connected messenger not set"
        );

        SupplyLogic.executeUseReserveAsCollateral(
            connectedMessenger, 
            _addressesProvider.getUniversalMessenger(), 
            asset, 
            useAsCollateral
        );
    }

    // liquidation call phase 2
    function _receiveLiquidatorUnderlying(bytes memory data) internal {
        IConnectedMessenger connectedMessenger = IConnectedMessenger(payable(_addressesProvider.getConnectedMessenger()));
        require(
            address(connectedMessenger) != address(0), 
            "connected messenger not set"
        );

        (
            address collateralAsset,
            address debtAsset,
            address user,
            address liquidator,
            bool receiveTToken,
            uint256 actualCollateralToLiquidate,
            uint256 actualDebtToLiquidate,
            uint256 collateralChainId
        ) = abi.decode(data, (address, address, address, address, bool, uint256, uint256, uint256));

        try LiquidationLogic.executeReceiveLiquidatorUnderlying(
            _reserves,
            connectedMessenger,
            _addressesProvider.getUniversalMessenger(),
            DataTypes.ReceiveLiquidatorUnderlyingParams({
                collateralAsset: collateralAsset,
                debtAsset: debtAsset,
                user: user,
                liquidator: liquidator,
                receiveTToken: receiveTToken,
                actualCollateralToLiquidate: actualCollateralToLiquidate,
                actualDebtToLiquidate: actualDebtToLiquidate,
                collateralChainId: collateralChainId
            })
        ) {
            emit OnCall(true, "");
        }
        catch (bytes memory err) {
            LiquidationLogic.executeReceiveLiquidatorUnderlyingFailed(
                _reserves,
                connectedMessenger,
                _addressesProvider.getUniversalMessenger(),
                DataTypes.ReceiveLiquidatorUnderlyingParams({
                    collateralAsset: collateralAsset,
                    debtAsset: debtAsset,
                    user: user,
                    liquidator: liquidator,
                    receiveTToken: receiveTToken,
                    actualCollateralToLiquidate: actualCollateralToLiquidate,
                    actualDebtToLiquidate: actualDebtToLiquidate,
                    collateralChainId: collateralChainId
                })
            );

            emit OnCall(false, err);
        }
    }

    // liquidaton call phase 3
    function _liquidateCollateral(bytes memory data) internal {
        IConnectedMessenger connectedMessenger = IConnectedMessenger(payable(_addressesProvider.getConnectedMessenger()));
        require(
            address(connectedMessenger) != address(0), 
            "connected messenger not set"
        );

        (
            address user,
            address liquidator,
            address collateralAsset,
            bool receiveTToken,
            uint256 actualCollateralToLiquidate,
            uint256 actualCollateralToLiquidateScaled
        ) = abi.decode(data, (address, address, address, bool, uint256, uint256));

        LiquidationLogic.executeLiquidateCollateral(
            _reserves,
            connectedMessenger,
            _addressesProvider.getUniversalMessenger(),
            DataTypes.LiquidateCollateralParams({
                collateralAsset: collateralAsset,
                user: user,
                liquidator: liquidator,
                receiveTToken: receiveTToken,
                actualCollateralToLiquidate: actualCollateralToLiquidate,
                actualCollateralToLiquidateScaled: actualCollateralToLiquidateScaled
            })
        );
    }

    // @inheritdoc IPool
    function initReserve(
        address asset,
        address tTokenAddress,
        address variableDebtTokenAddress,
        address reserveInterestRateStrategyAddress
    ) external override onlyPoolConfigurator{
        if (
            PoolLogic.executeInitReserve(
                _reserves,
                _reservesList,
                DataTypes.InitReserveParams({
                    asset: asset,
                    tTokenAddress: tTokenAddress,
                    variableDebtTokenAddress: variableDebtTokenAddress,
                    reserveInterestRateStrategyAddress: reserveInterestRateStrategyAddress,
                    reservesCount: _reservesCount,
                    maxNumberOfReserves: _maxNumberOfReserves
                })
            )
        ) {
            _reservesCount++;
        }
    }

    // @inheritdoc IPool
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external override onlyPoolConfigurator {
        PoolLogic.executeRescueTokens(token, to, amount);
    }

    // @inheritdoc IPool
    function dropReserve(address asset) external onlyPoolConfigurator {
        PoolLogic.executeDropReserve(_reserves, _reservesList, asset);
    }

    // @inheritdoc IPool
    function getReserveNormalizedIncome(address asset) external view virtual override returns (uint256) {
        return _reserves[asset].getNormalizedIncome();
    }

    // @inheritdoc IPool
    function getConfiguration(address asset) external view override returns (DataTypes.ReserveConfigurationMap memory) {
        return _reserves[asset].configuration;
    }

    // @inheritdoc IPool
    function setConfiguration(address asset, uint256 configuration) external override onlyPoolConfigurator {
        _reserves[asset].configuration.data = configuration;
        emit SetConfiguration(asset,configuration);
    }

    // @inheritdoc IPool
    function getReserveData(address asset) external view override returns (DataTypes.ReserveData memory) {
        return _reserves[asset];
    }

    // @inheritdoc IPool
    function getReserveNormalizedVariableDebt(address asset) external view override returns (uint256) {
        return _reserves[asset].getNormalizedDebt();
    }

    // @inheritdoc IPool
    function getReservesList() external view override returns (address[] memory) {

        uint256 counter = 0;
        for (uint256 i = 0; i < _reservesCount; i++) {
            if(_reservesList[i] != address(0)) counter++;
        }

        address[] memory _activeReserves = new address[](counter);
        
        uint256 id = 0;
        for (uint256 i = 0; i < _reservesCount; i++) {
            if(_reservesList[i] != address(0)) {
                _activeReserves[id] = _reservesList[i];
                id++;
            }
        }
        return _activeReserves;
    }

    // @inheritdoc IPool
    function getAddressesProvider() external view override returns (address) {
        return address(_addressesProvider);
    }

    // @inheritdoc IPool
    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    ) external override onlyPoolConfigurator {
        _reserves[asset].interestRateStrategyAddress = rateStrategyAddress;
    }

    // @inheritdoc IPool
    function setPause(bool val) external override onlyPoolConfigurator {
        _paused = val;
        if (_paused) emit Paused();
        else         emit Unpaused();
    }

    // @inheritdoc IPool
    function paused() external view override returns (bool) {
        return _paused;
    }

    // @inheritdoc IPool
    function emergencyUpdateUserSupply(address user, address asset) external onlyGovernance {
        IConnectedMessenger connectedMessenger = IConnectedMessenger(payable(_addressesProvider.getConnectedMessenger()));
        DataTypes.ReserveData memory reserve = _reserves[asset];

        ITToken tToken = ITToken(reserve.tTokenAddress);

        bytes memory crossChainMsg = abi.encode(
            // user data
            user,
            asset, 
            tToken.scaledBalanceOf(user), 
            // reserve data
            reserve.liquidityIndex,
            reserve.variableBorrowIndex,
            reserve.currentLiquidityRate,
            reserve.currentVariableBorrowRate,
            IBEP20(asset).balanceOf(address(tToken)),
            // treasury
            ITToken(tToken).RESERVE_TREASURY_ADDRESS(),
            0,
            // timestamp
            uint40(block.timestamp)
        );

        connectedMessenger.send(
            msg.sender,
            _addressesProvider.getUniversalMessenger(),
            uint8(DataTypes.MessageHeader.EmergencyUpdateUser),
            crossChainMsg
        );
    }

    // enable to receive native
    receive() external payable {}
    fallback() external payable {}
}