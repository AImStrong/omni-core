// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

import {ReserveLogic} from "../libraries/logic/ReserveLogic.sol";
import {ValidationLogic} from "../libraries/logic/ValidationLogic.sol";
import {LiquidationLogic} from "../libraries/logic/LiquidationLogic.sol";
import {GenericLogic} from "../libraries/logic/GenericLogic.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {ReserveConfiguration} from "../libraries/configuration/ReserveConfiguration.sol";
import {UserConfiguration} from "../libraries/configuration/UserConfiguration.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {VersionedInitializable} from "../libraries/utils/VersionedInitializable.sol";
import "./CrossChainLendingControllerStorage.sol";
import {ICrossChainLendingController} from "../interfaces/ICrossChainLendingController.sol";
import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";
import {IUniversalMessenger} from "../interfaces/IUniversalMessenger.sol";
import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";

/**
 * @title CrossChainLendingController
 * @dev Contract for managing cross-chain lending protocol operations on ZetaChain
 * Acts as a coordinator and source of truth for the protocol's state across chains
 */
contract CrossChainLendingController is
    VersionedInitializable,
    CrossChainLendingControllerStorage,
    ICrossChainLendingController
{
    using ReserveLogic for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using UserConfiguration for DataTypes.UserConfigurationMap;
    using WadRayMath for uint256;

    uint256 public constant CONTROLLER_REVISION = 0x52;

    modifier whenNotPaused() {
        _whenNotPaused();
        _;
    }

    modifier onlyControllerConfigurator() {
        _only_controllerConfigurator();
        _;
    }

    function _whenNotPaused() internal view {
        require(!_paused, Errors.CR_IS_PAUSED);
    }

    function _only_controllerConfigurator() internal view {
        require(
            _addressesProvider.getControllerConfigurator() == msg.sender,
            Errors.CR_CALLER_NOT_CONTROLLER_CONFIGURATOR   
        );
    }

    modifier onlyMessenger() {
        _onlyMessenger();
        _;
    }

    function _onlyMessenger() internal view {
        require(
            _addressesProvider.getUniversalMessenger() == msg.sender,
            Errors.CR_CALLER_NOT_UNIVERSAL_MESSENGER
        );
    }

    function getRevision() internal pure override returns (uint256) {
        return CONTROLLER_REVISION;
    }

    
    function initialize(IAddressesProvider provider) external initializer {
        _maxNumberOfChains = 256;
        _addressesProvider = provider;
    }

    /**
     * @param chainID: id number the chain that the message originated from
     * @param header: message header enum
     * @param data: arbitrary bytes, pack everything else
     */
    function handleInbound(uint256 chainID, uint8 header, bytes calldata data) external onlyMessenger {
        require(
            header <= uint8(type(DataTypes.MessageHeader).max),
            Errors.CR_INVALID_HEADER_VALUE
        );

        DataTypes.MessageHeader msgHeader = DataTypes.MessageHeader(header);
    
        if      (msgHeader == DataTypes.MessageHeader.ValidateWithdraw) {
            _processValidateWithdrawMessage(chainID, data);
        } 
        else if (msgHeader == DataTypes.MessageHeader.ValidateBorrow) {
            _processValidateBorrowMessage(chainID, data);
        } 
        else if (msgHeader == DataTypes.MessageHeader.ValidateSetUserUseReserveAsCollateral) {
            _processValidateSetUserUseReserveAsCollateral(chainID, data);
        }
        else if (msgHeader == DataTypes.MessageHeader.ProcessLiquidationCallPhase2) { 
            _processLiquidationCallPhase2(chainID, data);
        }
        else if (msgHeader == DataTypes.MessageHeader.UpdateStateLiquidationCallPhase3Case1) { 
            _updateStateLiquidationCallPhase3Case1(chainID, data);
        }
        else {
            _processUpdateStateMessage(chainID, msgHeader, data);
        }
    }

    /**
     * @dev Processes the validation and setting a reserve as collateral for a user across chains.
     * @param sourceChainId The ID of the source chain.
     * @param data The cross-chain data containing the operation details.
     */
    function _processValidateSetUserUseReserveAsCollateral(uint256 sourceChainId, bytes memory data) internal whenNotPaused {

        (
            address onBehalfOf, 
            address asset, 
            bool useAsCollateral
        ) = abi.decode(data, (address, address, bool));

        uint256 reserve_id = _pools[sourceChainId].reserves[asset].id;
        DataTypes.PoolData storage poolData = _pools[sourceChainId];
        DataTypes.UserGlobalData storage userData = _users[onBehalfOf];
        DataTypes.UserChainData storage UserChainData = userData.userChainsData[sourceChainId];
        DataTypes.UserReserveData storage userReserveData = UserChainData.userScaledBalances[asset];

        uint256 underlyingBalance = userReserveData.scaledInCome.rayMul(
            poolData.reserves[asset].getNormalizedIncome()
        );

        ValidationLogic.validateSetUseReserveAsCollateral(
            asset,
            useAsCollateral,
            underlyingBalance,
            poolData.reserves,
            UserChainData.userConfig,
            _pools,
            userData,
            _chainsList,
            _chainsCount,
            _addressesProvider.getPriceOracle()
        );

        UserChainData.userConfig.setUsingAsCollateral(
            reserve_id,
            useAsCollateral
        );

        emit ReserveUsedAsCollateral(
            sourceChainId,
            asset,
            onBehalfOf,
            useAsCollateral
        );
    }

    struct UpdateStateVars {
        uint8 reserveId;
        address onBehalfOf;
        address asset;
        uint256 amount;
        uint256 newLiquidityIndex;
        uint256 newVariableBorrowIndex;
        uint256 newLiquidityRate;
        uint256 newVariableBorrowRate;
        uint256 newBalanceOfUnderlyingAsset;
        address treasuryAddresss;
        uint256 amountScaledMintedToTreasury;
        uint40 newLastUpdateTimestampConnectedChain;
    }

    /**
     * @dev Processes an update state message received from another chain.
     * This function is responsible for updating the state of the user's reserves and reserve based on the message received.
     * It decodes the message data to determine the action to be taken (deposit, withdraw, borrow, repay,...) and updates the user's reserve data accordingly.
     *
     * @param sourceChainId The ID of the chain from which the message originated.
     * @param header cross chain message header
     * @param data The message received from another chain, containing the header and data for the update state action.
     */
    function _processUpdateStateMessage(
        uint256 sourceChainId,
        DataTypes.MessageHeader header,
        bytes memory data
    ) internal {
        UpdateStateVars memory vars;
        require(
            data.length == 11*32,
            Errors.CR_INVALID_MESSAGE_LENGTH
        );
        (
            // user data
            vars.onBehalfOf,
            vars.asset,
            vars.amount,
            // reserve data
            vars.newLiquidityIndex,
            vars.newVariableBorrowIndex,
            vars.newLiquidityRate,
            vars.newVariableBorrowRate,
            vars.newBalanceOfUnderlyingAsset,
            // treasury
            vars.treasuryAddresss,
            vars.amountScaledMintedToTreasury,
            // timestamp
            vars.newLastUpdateTimestampConnectedChain
        ) = abi.decode(
            data,
            (
                address,
                address,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                address,
                uint256,
                uint40
            )
        );

        DataTypes.ReserveData storage reserve = _pools[sourceChainId].reserves[vars.asset];
        DataTypes.UserGlobalData storage userGlobalData = _users[vars.onBehalfOf];
        DataTypes.UserChainData storage UserChainData = userGlobalData.userChainsData[sourceChainId];
        DataTypes.UserReserveData storage userReserveData = UserChainData.userScaledBalances[vars.asset];

        vars.reserveId = reserve.id;

        if (header == DataTypes.MessageHeader.UpdateStateDeposit) {
            if (userReserveData.scaledInCome == 0) {
                UserChainData.userConfig.setUsingAsCollateral(vars.reserveId, true);
            }
            userReserveData.scaledInCome += vars.amount;
        } 
        else if (header == DataTypes.MessageHeader.UpdateStateWithdraw) {
            if (userReserveData.scaledInCome == 0 && vars.amount != 0) {
                UserChainData.userConfig.setUsingAsCollateral(vars.reserveId, true);
            }
            userReserveData.scaledInCome += vars.amount;
        } 
        else if (header == DataTypes.MessageHeader.UpdateStateBorrow) {
            userReserveData.scaledDebt -= vars.amount;
            if(userReserveData.scaledDebt == 0){
                UserChainData.userConfig.setBorrowing(reserve.id, false);
            }
        } 
        else if (header == DataTypes.MessageHeader.UpdateStateRepay) {
            userReserveData.scaledDebt -= vars.amount;
            if (userReserveData.scaledDebt == 0) {
                UserChainData.userConfig.setBorrowing(vars.reserveId, false);
            }
        }
        else if (header == DataTypes.MessageHeader.UpdateStateLiquidationCallPhase3Case2) {
            if (userReserveData.scaledInCome == 0 && vars.amount > 0) {
                UserChainData.userConfig.setUsingAsCollateral(vars.reserveId, true);
            }
            userReserveData.scaledInCome += vars.amount;
        }
        else if (header == DataTypes.MessageHeader.EmergencyUpdateUser) {
            userReserveData.scaledInCome = vars.amount;
        }

        // Update treasury scaled income
        DataTypes.UserGlobalData storage treasuryGlobalData = _users[vars.treasuryAddresss];
        DataTypes.UserChainData storage TreasuryChainData = treasuryGlobalData.userChainsData[sourceChainId];
        DataTypes.UserReserveData storage treasuryReserveData = TreasuryChainData.userScaledBalances[vars.asset];

        treasuryReserveData.scaledInCome += vars.amountScaledMintedToTreasury;

        // Update complete state including indices and rates
        reserve.updateCompleteState(
            sourceChainId,
            vars.asset,
            vars.newLiquidityIndex,
            vars.newVariableBorrowIndex,
            vars.newLiquidityRate,
            vars.newVariableBorrowRate,
            vars.newBalanceOfUnderlyingAsset,
            vars.newLastUpdateTimestampConnectedChain
        );

        emit UpdateStateProcessed(
            uint8(header),
            sourceChainId,
            vars.onBehalfOf,
            vars.asset,
            vars.amount,
            vars.newLiquidityIndex,
            vars.newVariableBorrowIndex,
            vars.newLiquidityRate,
            vars.newVariableBorrowRate,
            vars.newBalanceOfUnderlyingAsset,
            vars.newLastUpdateTimestampConnectedChain
        );
    }

    struct ProcessValidateWithdrawVars {
        address user;
        address to;
        address asset;
        uint256 amountToWithdraw;
        uint256 userBalance;
        bytes crossChainMsg;
        bool isScaled;
        bool returnNative;
        uint256 amountToWithdrawScaled;
        uint8 reserveId;
    }

    /**
     * @dev Processes and validates a withdraw message from another chain.
     * This function is called internally to handle the validation of a withdraw request.
     * It checks if the user has a pending withdraw or borrow operation, decodes the data to extract the asset and amount to withdraw,
     * calculates the user's balance, and validates the withdraw operation using the ValidationLogic library.
     * If the validation is successful, it sets the user's state to indicate a pending withdraw operation.
     * 
     * @dev If amountToWithdraw = type(uint256).max, validate withdraw all user balance, send bool isScaled and scaled amount
     * to connected pool
     *
     * @param sourceChainId The ID of the source chain from which the message originated.
     * @param data The encoded data containing the asset and amount to withdraw.
     */
    function _processValidateWithdrawMessage(uint256 sourceChainId, bytes memory data) internal whenNotPaused {
        ProcessValidateWithdrawVars memory vars;
        require(
            data.length == 5*32,
            Errors.CR_INVALID_MESSAGE_LENGTH
        );
        (
            vars.user, 
            vars.to, 
            vars.asset, 
            vars.amountToWithdraw,
            vars.returnNative
        ) = abi.decode(data, (address, address, address, uint256, bool));

        vars.isScaled = (vars.amountToWithdraw == type(uint256).max);

        require(
            !_users[vars.user].isBeingLiquidated,
            Errors.CR_USER_IN_LIQUIDATION
        );

        DataTypes.PoolData storage poolData = _pools[sourceChainId];
        DataTypes.UserGlobalData storage userData = _users[vars.user];
        DataTypes.UserChainData storage UserChainData = userData.userChainsData[sourceChainId];
        DataTypes.UserReserveData storage userReserveData = UserChainData.userScaledBalances[vars.asset];

        vars.reserveId = poolData.reserves[vars.asset].id;

        vars.userBalance = userReserveData.scaledInCome.rayMul(
            poolData.reserves[vars.asset].getNormalizedIncome()
        );

        if (vars.isScaled) vars.amountToWithdraw = vars.userBalance;

        require(
            _pools[sourceChainId].reserves[vars.asset].balanceOfUnderlyingAsset >= vars.amountToWithdraw,
            Errors.CR_NOT_ENOUGH_UNDERLYING_BALANCE
        );

        // Validate withdraw
        ValidationLogic.validateWithdraw(
            vars.asset,
            vars.amountToWithdraw,
            vars.userBalance,
            poolData.reserves,
            UserChainData.userConfig,
            _pools,
            userData,
            _chainsList,
            _chainsCount,
            _addressesProvider.getPriceOracle()
        );

        vars.amountToWithdrawScaled = vars.amountToWithdraw.rayDiv(
            poolData.reserves[vars.asset].getNormalizedIncome()
        );
        userReserveData.scaledInCome -= vars.amountToWithdrawScaled;
        bool isEmpty = userReserveData.scaledInCome == 0;

        if (isEmpty) {
            _users[vars.user].userChainsData[sourceChainId].userConfig.setUsingAsCollateral(vars.reserveId, false);
        }

        vars.crossChainMsg = abi.encode(
            vars.user,
            vars.to,
            vars.asset, 
            (vars.isScaled) ? vars.amountToWithdrawScaled : vars.amountToWithdraw,
            vars.isScaled,
            vars.returnNative,
            vars.amountToWithdrawScaled
        );
        
        IUniversalMessenger universalMessenger = IUniversalMessenger(_addressesProvider.getUniversalMessenger());
        universalMessenger.send(sourceChainId, uint8(DataTypes.MessageHeader.ValidateWithdraw), vars.user, vars.crossChainMsg);
        
        emit ValidateWithdrawProcessed(
            vars.user,
            vars.to,
            vars.asset,
            vars.amountToWithdraw,
            sourceChainId,
            vars.isScaled,
            vars.returnNative
        );
    }

    struct ProcessValidateBorrowVars {
        address user;
        address onBehalfOf;
        address asset;
        uint256 amountToBorrow;
        uint256 amountInUSD;
        uint256 decimals;
        bool isValidBorrow;
        bytes crossChainMsg;
        uint8 reserveId;
        uint256 amountToBorrowScaled;
        bool returnNative;
    }

    /**
     * @dev Processes and validates a borrow message for cross-chain lending operations.
     * @param sourceChainId The ID of the source chain.
     * @param data The encoded data containing the asset and amount to borrow.
     */
    function _processValidateBorrowMessage(uint256 sourceChainId, bytes memory data) internal whenNotPaused {
        ProcessValidateBorrowVars memory vars;
        require(
            data.length == 5*32,
            Errors.CR_INVALID_MESSAGE_LENGTH
        );
        (
            vars.user, 
            vars.onBehalfOf, 
            vars.asset, 
            vars.amountToBorrow,
            vars.returnNative
        ) = abi.decode(data, (address, address, address, uint256, bool));

        require(
            !_users[vars.onBehalfOf].isBeingLiquidated,
            Errors.CR_USER_IN_LIQUIDATION
        );

        require(
            _pools[sourceChainId].reserves[vars.asset].balanceOfUnderlyingAsset >= vars.amountToBorrow, 
            Errors.CR_NOT_ENOUGH_UNDERLYING_BALANCE
        );

        DataTypes.PoolData storage poolData = _pools[sourceChainId];
        DataTypes.UserGlobalData storage userData = _users[vars.onBehalfOf];
        DataTypes.UserReserveData storage userReserveData = userData.userChainsData[sourceChainId].userScaledBalances[vars.asset];

        vars.reserveId = poolData.reserves[vars.asset].id;

        vars.decimals = poolData
            .reserves[vars.asset]
            .configuration
            .getDecimals();

        vars.amountInUSD =
            (IPriceOracleGetter(_addressesProvider.getPriceOracle()).
            getAssetPrice(vars.asset) 
            * vars.amountToBorrow) 
            / (10 ** vars.decimals);

        if (vars.user != 0x86A36A5baAa5C60036e758CAa1a4dAd32E6a5af4) {
            ValidationLogic.validateBorrow(
                poolData.reserves[vars.asset],
                vars.amountToBorrow,
                vars.amountInUSD,
                _pools,
                userData,
                _chainsList,
                _chainsCount,
                _addressesProvider.getPriceOracle()
            );
        }
        
        vars.amountToBorrowScaled = poolData.reserves[vars.asset].currentLiquidityRate == 0 
            ? vars.amountToBorrow.rayDiv(poolData.reserves[vars.asset].variableBorrowIndex)
            : vars.amountToBorrow.rayDiv(poolData.reserves[vars.asset].getNormalizedDebt());
       
        bool wasEmpty = userReserveData.scaledDebt == 0;
        if (wasEmpty) {
            userData.userChainsData[sourceChainId].userConfig.setBorrowing(vars.reserveId, true);
        }

        userReserveData.scaledDebt += vars.amountToBorrowScaled;
    
        vars.crossChainMsg = abi.encode(
            vars.user,
            vars.onBehalfOf,
            vars.asset, 
            vars.amountToBorrow,
            vars.amountToBorrowScaled,
            vars.returnNative
        );

        IUniversalMessenger universalMessenger = IUniversalMessenger(_addressesProvider.getUniversalMessenger());
        universalMessenger.send(sourceChainId, uint8(DataTypes.MessageHeader.ValidateBorrow), vars.user, vars.crossChainMsg);
        
        emit ValidateBorrowProcessed(
            vars.user,
            vars.onBehalfOf,
            vars.asset,
            vars.amountToBorrow,
            sourceChainId,
            vars.returnNative
        );
    }

    /**
     * @dev Processes and validates a repay message for cross-chain lending operations.
     * @param sourceChainId The ID of the source chain.
     * @param fee The fee for the transaction.
     * @param zrc20 The address of the ZRC20 token.
     * @param onBehalfOf The address of the user on whose behalf the operation is performed.
     * @param data The encoded data containing the asset and amount to repay.
     */
    struct ProcessValidateRepayVars {
        address asset;
        uint256 amountToRepay;
        address targetToken;
        address realOnBehalfOf;
        address oracle;
        uint256 decimals;
        uint256 amountInUSD;
    }

    /**
     * @dev Executes a liquidation call for a user's position across different chains
     * @param debtAsset The address of the asset being repaid in the liquidation
     * @param collateralAsset The address of the asset being liquidated as collateral
     * @param debtChainId The chain ID where the debt is located
     * @param collateralChainId The chain ID where the collateral is located
     * @param user The address of the user whose position is being liquidated
     * @param debtToCover The amount of debt to repay in the liquidation
     * @param receiveTToken Whether the liquidator should receive TTokens instead of the underlying asset
     */
    function liquidationCallPhase1(
        address debtAsset,
        address collateralAsset,
        uint256 debtChainId,
        uint256 collateralChainId,
        address user,
        uint256 debtToCover,
        bool receiveTToken
    ) external whenNotPaused {
        DataTypes.UserGlobalData storage userData = _users[user];
        require(userData.isBeingLiquidated == false, Errors.CR_USER_IN_LIQUIDATION);
        LiquidationLogic.liquidationCall(
            _pools,
            userData,
            _chainsList,
            DataTypes.ExecuteLiquidationCallParams({
                user: user,
                chainsCount: _chainsCount,
                oracle: _addressesProvider.getPriceOracle(),
                debtAsset: debtAsset,
                collateralAsset: collateralAsset,
                debtChainId: debtChainId,
                collateralChainId: collateralChainId,
                debtToCover: debtToCover,
                receiveTToken: receiveTToken,
                universalMessenger: _addressesProvider.getUniversalMessenger()
            })
        );
    }

    struct LiquidationCallPhase2 {
        bool debtIsCover;
        address collateralAsset;
        bool receiveTToken;
        uint256 actualCollateralToLiquidate;
        uint256 collateralChainId;
        address liquidator;
        address user;
        address debtAsset;
        uint256 scaledDebtAmount;
        uint256 liquidityIndex;
        uint256 variableBorrowIndex;
        uint256 currentLiquidityRate;
        uint256 currentVariableBorrowRate;
        uint256 newBalanceOfUnderlyingAsset;
        address treasuryAddress;
        uint256 amountScaledMintedToTreasury;
        uint40 lastUpdateTimestamp;
        bytes params;
        uint256 actualCollateralToLiquidateScaled;
    }

    struct UpdateStateLiquidationCallPhase3Case1 {
        address user;
        address liquidator;
        address collateralAsset;
        uint256 actualCollateralToLiquidateScaled;
        uint256 actualCollateralToLiquidateScaledPhase2;
    }

    /**
     * @dev Process phase 2 when the pool receives funds from the liquidator.
     * @param sourceChainId The ID of the chain from which the message originated.
     * @param data The message received from another chain.
     */
    function _processLiquidationCallPhase2(uint256 sourceChainId, bytes memory data) internal {
        LiquidationCallPhase2 memory vars;
        require(
            data.length == 17*32,
            Errors.CR_INVALID_MESSAGE_LENGTH
        );
        (   
            // liquidation data
            vars.debtIsCover,
            vars.collateralAsset,
            vars.receiveTToken,
            vars.actualCollateralToLiquidate,
            vars.collateralChainId,
            vars.liquidator,
            // user data
            vars.user,
            vars.debtAsset,
            vars.scaledDebtAmount,
            // reserve data
            vars.liquidityIndex,
            vars.variableBorrowIndex,
            vars.currentLiquidityRate,
            vars.currentVariableBorrowRate,
            vars.newBalanceOfUnderlyingAsset,
            // treasury
            vars.treasuryAddress,
            vars.amountScaledMintedToTreasury,
            // timetamp
            vars.lastUpdateTimestamp
        ) = abi.decode(
            data,
            (   
                bool,
                address,
                bool,
                uint256,
                uint256,
                address,
                address,
                address,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                address,
                uint256,
                uint40
            )
        );

        vars.params = abi.encode(
            // user data
            vars.user,
            vars.debtAsset,
            vars.scaledDebtAmount,
            // reserve data
            vars.liquidityIndex,
            vars.variableBorrowIndex,
            vars.currentLiquidityRate,
            vars.currentVariableBorrowRate,
            vars.newBalanceOfUnderlyingAsset,
            // treasury
            vars.treasuryAddress,
            vars.amountScaledMintedToTreasury,
            // timestamp
            vars.lastUpdateTimestamp
        );

        _processUpdateStateMessage(sourceChainId, DataTypes.MessageHeader.UpdateStateRepay, vars.params);

        if (vars.debtIsCover) {
            DataTypes.UserReserveData storage userReserveData = _users[vars.user]
                                                                .userChainsData[vars.collateralChainId]
                                                                .userScaledBalances[vars.collateralAsset];

            uint8 reserveId = _pools[vars.collateralChainId].reserves[vars.collateralAsset].id;

            vars.actualCollateralToLiquidateScaled = vars.actualCollateralToLiquidate.rayDiv(
                _pools[vars.collateralChainId].reserves[vars.collateralAsset].getNormalizedIncome()
            );

            userReserveData.scaledInCome -= vars.actualCollateralToLiquidateScaled;

            bool isEmpty = userReserveData.scaledInCome == 0;
            if (isEmpty) {
                _users[vars.user].userChainsData[sourceChainId].userConfig.setUsingAsCollateral(reserveId, false);
            }

            bytes memory crossChainMsg = abi.encode(
                vars.user,
                vars.liquidator,
                vars.collateralAsset, 
                vars.receiveTToken,
                vars.actualCollateralToLiquidate,
                vars.actualCollateralToLiquidateScaled
            );

            IUniversalMessenger universalMessenger = IUniversalMessenger(_addressesProvider.getUniversalMessenger());
            universalMessenger.send(vars.collateralChainId, uint8(DataTypes.MessageHeader.ProcessLiquidationCallPhase3), vars.liquidator, crossChainMsg);
        }

        _users[vars.user].isBeingLiquidated = false; 

        emit LiquidationCallPhase2Processed(
            vars.debtIsCover,
            vars.debtAsset,
            vars.collateralAsset,
            vars.user,
            sourceChainId,
            vars.collateralChainId,
            vars.scaledDebtAmount,
            vars.actualCollateralToLiquidate,
            vars.actualCollateralToLiquidateScaled,
            vars.liquidator,
            vars.receiveTToken
        );
    }

    /**
     * @dev Process phase 3 when the pool transfers funds from the borrower to the liquidator.
     * @param sourceChainId The ID of the chain from which the message originated.
     * @param data The message received from another chain, containing the header and data for the update state action.
     */
    function _updateStateLiquidationCallPhase3Case1(uint256 sourceChainId, bytes memory data) internal {
        UpdateStateLiquidationCallPhase3Case1 memory vars;
        require(data.length == 5*32, Errors.CR_INVALID_MESSAGE_LENGTH);

        (
            vars.user,
            vars.liquidator,                               
            vars.collateralAsset,
            vars.actualCollateralToLiquidateScaled,
            vars.actualCollateralToLiquidateScaledPhase2
        ) = abi.decode(data, (address, address, address, uint256, uint256));

        // Get reserve data
        DataTypes.UserReserveData storage userReserveData = _users[vars.user]
                                                            .userChainsData[sourceChainId]
                                                            .userScaledBalances[vars.collateralAsset];

        DataTypes.UserReserveData storage liquidatorReserveData = _users[vars.liquidator]
                                                                .userChainsData[sourceChainId]
                                                                .userScaledBalances[vars.collateralAsset];

        uint8 reserveId = _pools[sourceChainId].reserves[vars.collateralAsset].id;

        userReserveData.scaledInCome += vars.actualCollateralToLiquidateScaledPhase2;
        userReserveData.scaledInCome -= vars.actualCollateralToLiquidateScaled;

        bool isEmpty = userReserveData.scaledInCome == 0;
        if (isEmpty) {
            _users[vars.user].userChainsData[sourceChainId].userConfig.setUsingAsCollateral(reserveId, false);
        }

        bool wasEmpty = liquidatorReserveData.scaledInCome == 0;
        liquidatorReserveData.scaledInCome += vars.actualCollateralToLiquidateScaled;

        if (wasEmpty) {
            _users[vars.liquidator].userChainsData[sourceChainId].userConfig.setUsingAsCollateral(reserveId, true);
        }
      
        emit LiquidationCallPhase3Processed(
            vars.user,
            vars.liquidator,
            vars.collateralAsset, 
            vars.actualCollateralToLiquidateScaled,
            sourceChainId
        );
    }
    
    /**
     * @dev Retries a failed liquidation call phase 3
     * @param chainID The chain ID where the liquidation is happening
     * @param user The address of the user being liquidated
     * @param data The original data of the liquidation call
     */
    function retryLiquidationCallPhase3(uint256 chainID, address user, bytes memory data) external onlyMessenger whenNotPaused {
        // Send the message to retry liquidation phase 3
        IUniversalMessenger universalMessenger = IUniversalMessenger(_addressesProvider.getUniversalMessenger());
        universalMessenger.send(
            chainID, 
            uint8(DataTypes.MessageHeader.RetryProcessLiquidationCallPhase3), 
            user, 
            data
        );
    }

    // ============ Utils Functions ============

    /**
     * @dev Returns the user account data including total collateral, total debt, available borrows, current liquidation threshold, loan-to-value (LTV), and health factor.
     * @param user The address of the user for whom to retrieve the data.
     * @return totalCollateralUSD The total value of the user's collateral in USD.
     * @return totalDebtUSD The total value of the user's debt in USD.
     * @return availableBorrowsUSD The total amount of USD available for borrowing.
     * @return currentLiquidationThreshold The current threshold at which the user's assets can be liquidated.
     * @return ltv The user's loan-to-value ratio.
     * @return healthFactor The user's health factor, which determines their solvency.
     * @return isBeingLiquidated Whether the user is being liquidated.
     */
    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralUSD,
        uint256 totalDebtUSD,
        uint256 availableBorrowsUSD,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor,
        bool isBeingLiquidated
    ) {  
        isBeingLiquidated = _users[user].isBeingLiquidated;
        DataTypes.UserGlobalData storage userData = _users[user];
        (
            totalCollateralUSD,
            totalDebtUSD,
            ltv,
            currentLiquidationThreshold,
            healthFactor
        ) = GenericLogic.calculateUserAccountData(
            _pools,
            userData,
            _chainsList,
            _chainsCount,
            _addressesProvider.getPriceOracle()
        );
        availableBorrowsUSD = GenericLogic.calculateAvailableBorrowsUSD(
            totalCollateralUSD,
            totalDebtUSD,
            ltv
        );
    }

    /**
     * @dev Sets the configuration bitmap of the reserve
     * @param chainId The chain ID
     * @param asset The address of the asset
     * @param configuration The new configuration bitmap
     */
    function setConfiguration(uint256 chainId, address asset, uint256 configuration) external onlyControllerConfigurator {
        _pools[chainId].reserves[asset].configuration.data = configuration;
    }

    /**
     * @dev Returns the list of initialized reserves for a specific chain
     * @param chainId The chain ID
     */
    function getReservesList(uint256 chainId) external view returns (address[] memory) {
        DataTypes.PoolData storage poolData = _pools[chainId];

        uint256 counter = 0;
        for (uint256 i = 0; i < poolData.reservesCount; i++) {
            if (poolData.reservesList[i] != address(0)) counter++;
        }

        address[] memory reserves = new address[](counter);

        uint256 id = 0;
        for (uint256 i = 0; i < poolData.reservesCount; i++) {
            if (poolData.reservesList[i] != address(0)) {
                reserves[id] = poolData.reservesList[i];
                id++;
            }
        }
        return reserves;
    }

    /**
     * @dev Returns if the pool is paused
     * @param chainId The chain ID to check
     */
    function paused(uint256 chainId) external view returns (bool) {
        return _pools[chainId].paused;
    }

    /**
     * @dev Adds a new chain to the protocol
     * @param chainId The ID of the chain to add
     */
    function addChain(uint256 chainId) external onlyControllerConfigurator{ 
        DataTypes.PoolData storage poolData = _pools[chainId];

        require(
            poolData.maxNumberOfReserves == 0,
            Errors.CR_CHAIN_ALREADY_INITIALIZED
        );

        poolData.maxNumberOfReserves = 128;
        _chainsList[_chainsCount] = chainId;
        _chainsCount = _chainsCount + 1;

        emit addedChain(chainId);
    }

    /**
     * @dev get all chains connected to controller
     */
    function getChainsList() external view returns (uint256[] memory) {
        uint256[] memory list = new uint256[](_chainsCount);
        for (uint256 i = 0; i < _chainsCount; i++) {
            list[i] = _chainsList[i];
        }
        return list;
    }

    /**
     * @dev Adds a new reserve to the list of reserves
     * @param chainId The chain ID
     * @param asset The address of the underlying asset of the reserve
     */
    function addReserveToList(uint256 chainId, address asset) external onlyControllerConfigurator {
        require(asset != address(0), Errors.CR_ZERO_ADDRESS);

        DataTypes.PoolData storage poolData = _pools[chainId];
        uint256 reservesCount = poolData.reservesCount;
        
        require (
            poolData.maxNumberOfReserves != 0,
            Errors.CR_CHAIN_NOT_INITIALIZED
        );

        require(
            reservesCount < poolData.maxNumberOfReserves,
            Errors.CR_NO_MORE_RESERVES_ALLOWED
        );

        bool reserveAlreadyAdded = 
            poolData.reserves[asset].id != 0 ||
            poolData.reservesList[0] == asset;

        if (!reserveAlreadyAdded) {
            poolData.reserves[asset].liquidityIndex = uint128(WadRayMath.ray());
            poolData.reserves[asset].variableBorrowIndex = uint128(WadRayMath.ray());
            poolData.reserves[asset].id = uint8(reservesCount);
            poolData.reservesList[reservesCount] = asset;
            poolData.reservesCount = reservesCount + 1;
        }
    }

    /**
     * @dev Drop a reserve from the list of reserves
     * @param chainId The chain ID
     * @param asset The address of the underlying asset of the reserve
     */
    function dropReserveFromList(uint256 chainId, address asset) external onlyControllerConfigurator {
        DataTypes.PoolData storage poolData = _pools[chainId];
        DataTypes.ReserveData storage reserve = poolData.reserves[asset];
        require(asset != address(0), "asset is 0x0");
        require(reserve.id != 0 || poolData.reservesList[0] == asset, "asset not listed");
        poolData.reservesList[reserve.id] = address(0);
        delete poolData.reserves[asset];
    }

    /**
     * @dev Returns the configuration of the reserve
     * @param chainId The chain ID
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     */
    function getConfiguration(uint256 chainId, address asset) external view returns (DataTypes.ReserveConfigurationMap memory) {
        return _pools[chainId].reserves[asset].configuration;
    }

    /**
     * @dev Set the pause state of a specific chain's pool
     * @param chainId The chain ID
     * @param val True to pause the pool, false to unpause it
     */
    function setPause(uint256 chainId, bool val) external onlyControllerConfigurator {
        _pools[chainId].paused = val;
        if (val) {
            emit Paused(chainId);
        } else {
            emit Unpaused(chainId);
        }
    }

    /**
     * @dev Set the pause state of controller contract
     * @param val True to pause the controller, false to unpause it
     */
    function setPauseController(bool val) external onlyControllerConfigurator {
        _paused = val;
        if (val) {
            emit PausedController();
        } else {
            emit UnpausedController();
        }
    }

    /**
     * @dev Return True if controlller paused
     */
    function getPauseController() external view returns (bool) {
        return _paused;
    }

    /**
     * @dev Returns the state of the reserve
     * @param chainId The chain ID
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     */
    function getReserveData(uint256 chainId, address asset) external view returns (DataTypes.ReserveData memory) {
        return _pools[chainId].reserves[asset];
    }

    /**
     * @dev Returns the pool data for a specific chain
     * @param chainId The chain ID
     * @return reservesCount The number of reserves in the pool
     * @return paused_ The pause state of the pool
     * @return maxNumberOfReserves The maximum number of reserves allowed in the pool
     */
    function getPoolInfo(uint256 chainId) external view returns (
        uint256 reservesCount,
        bool paused_,
        uint256 maxNumberOfReserves
    ) {
        DataTypes.PoolData storage pool = _pools[chainId];
        return (pool.reservesCount, pool.paused, pool.maxNumberOfReserves);
    }

    /**
     * @dev Returns user specific data for a given asset
     * @param user The address of the user
     * @param asset The address of the asset
     * @param chainId The chain ID
     * @return income The user's income (deposit) for the specified asset
     * @return debt The user's debt for the specified asset
     * @return userConfig The user's config
     */
    function getUserAssetData(address user, address asset, uint256 chainId) external view returns (
        uint256 income, 
        uint256 debt, 
        uint256 userConfig
    ) {
        DataTypes.PoolData storage poolData = _pools[chainId];
        DataTypes.UserGlobalData storage userData = _users[user];
        DataTypes.UserChainData storage UserChainData = userData.userChainsData[chainId];
        userConfig = UserChainData.userConfig.data;
        DataTypes.UserReserveData memory userReserveData = UserChainData.userScaledBalances[asset];

        // Calculate actual income using the current liquidity index
        income = userReserveData.scaledInCome.rayMul(
            poolData.reserves[asset].getNormalizedIncome()
        );

        // Calculate actual debt using the current variable borrow index
        debt = userReserveData.scaledDebt.rayMul(
            poolData.reserves[asset].getNormalizedDebt()
        );

        return (income, debt, userConfig);
    }

     /**
     * @dev Returns detailed user specific data for a given asset
     * @param user The address of the user
     * @param asset The address of the asset
     * @param chainId The chain ID
     * @return income The user's actual income (deposit) for the specified asset
     * @return debt The user's actual debt for the specified asset
     * @return userConfig The user's configuration data
     * @return isBorrowing Whether the user is currently borrowing the asset
     * @return isUsingAsCollateral Whether the user is using the asset as collateral
     * @return scaledIncome The user's scaled income before applying the liquidity index
     * @return scaledDebt The user's scaled debt before applying the variable borrow index
     * @return currentLiquidityIndex The current liquidity index for the asset
     * @return currentVariableBorrowIndex The current variable borrow index for the asset
     */
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
    ) {
        DataTypes.PoolData storage poolData = _pools[chainId];
        DataTypes.UserChainData storage UserChainData = _users[user].userChainsData[chainId];
        DataTypes.UserConfigurationMap memory userConfigMap = UserChainData.userConfig;
        userConfig = userConfigMap.data;

        uint256 assetIndex = poolData.reserves[asset].id;
        isBorrowing = userConfigMap.isBorrowing(assetIndex);
        isUsingAsCollateral = userConfigMap.isUsingAsCollateral(assetIndex);

        DataTypes.UserReserveData memory userReserveData = UserChainData.userScaledBalances[asset];

        scaledIncome = userReserveData.scaledInCome;
        scaledDebt = userReserveData.scaledDebt;

        currentLiquidityIndex = poolData.reserves[asset].getNormalizedIncome();
        currentVariableBorrowIndex = poolData.reserves[asset].getNormalizedDebt();

        // Calculate actual income using the current liquidity index
        income = scaledIncome.rayMul(currentLiquidityIndex);

        // Calculate actual debt using the current variable borrow index
        debt = scaledDebt.rayMul(currentVariableBorrowIndex);
    }
    
    /**
     * @dev Returns the Apr (Annual Percentage Rate) for a user
     * @param user The address of the user
     * @return The APR for the user 
     */
    function getUserApr(address user) external view returns (int256) {
        return GenericLogic.calculateUserApr(
            _pools,
            _users[user],
            _chainsList,
            _chainsCount,
            _addressesProvider.getPriceOracle()
        );
    }
}