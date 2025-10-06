// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        // uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address tTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {NONE, VARIABLE}   // Update InterestRateMode : delete STABLE MODE

    enum MessageHeader {

        UpdateStateDeposit,

        ValidateWithdraw,
        UpdateStateWithdraw,
        
        ValidateBorrow,
        UpdateStateBorrow,
        
        UpdateStateRepay,

        ValidateSetUserUseReserveAsCollateral,

        ProcessLiquidationCallPhase2,

        ProcessLiquidationCallPhase3,
        
        UpdateStateLiquidationCallPhase3Case1,
        UpdateStateLiquidationCallPhase3Case2,

        RetryProcessLiquidationCallPhase3,

        EmergencyUpdateUser
    }

    struct ExecuteDepositParams {
        address asset;
        address onBehalfOf;
        uint16 referralCode;
        uint256 amount;
    }

    struct ExecuteWithdrawParams {
        address asset;
        address to;
        uint256 amount;
        bool returnNative;
    }

    struct ExecuteWithdrawOnCallParams {
        address user;
        address to;
        address asset;
        uint256 amount;
        bool isScaled;
        bool returnNative;
        uint256 amountToWithdrawScaled;
    }

    struct ExecuteBorrowParams {
        address asset;
        address onBehalfOf;
        uint16 referralCode;
        bool returnNative;
        uint256 amount;
    }

    struct ExecuteBorrowOnCallParams {
        address user;
        address onBehalfOf;
        address asset;
        uint256 amount;
        uint256 amountToBorrowScaled;
        bool returnNative;
    }

    struct ExecuteRepayParams {
        address asset;
        address onBehalfOf;
        uint256 amount;
    }

    struct InitReserveParams {
        address asset;
        address tTokenAddress;
        address variableDebtTokenAddress;
        address reserveInterestRateStrategyAddress;
        uint256 reservesCount;
        uint256 maxNumberOfReserves;
    }

    struct ReceiveLiquidatorUnderlyingParams {
        address collateralAsset;
        address debtAsset;
        address user;
        address liquidator;
        bool receiveTToken;
        uint256 actualCollateralToLiquidate;
        uint256 actualDebtToLiquidate;
        uint256 collateralChainId;
    }

    struct LiquidateCollateralParams {
        address collateralAsset;
        address user;
        address liquidator;
        bool receiveTToken;
        uint256 actualCollateralToLiquidate;
        uint256 actualCollateralToLiquidateScaled;
    }
}