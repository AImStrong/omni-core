// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

library DataTypes {
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
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
        // balance of underlying asset
        uint256 balanceOfUnderlyingAsset;

        uint40 lastUpdateTimestampConnectedChain;
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

    struct PoolData {
        mapping(address => ReserveData) reserves;
        // the list of the available reserves, structured as a mapping for gas savings reasons
        mapping(uint256 => address) reservesList;
        uint256 reservesCount;
        bool paused; // @review : dont use anywhere, may be can be delete in next version
        uint256 maxNumberOfReserves;
    }

    // Struct to store user reserve data
    struct UserReserveData {
        uint256 scaledInCome ;      // scaled aToken balance
        uint256 scaledDebt;         // scaled debt balance
    }

    struct UserConfigurationMap { //add description?
        uint256 data;
    }

    struct UserChainData {
        mapping(address => UserReserveData) userScaledBalances; // reserve address -> balance
        UserConfigurationMap userConfig;
    }
    
    struct UserGlobalData {
        mapping(uint256 => UserChainData) userChainsData; // chainID -> Pool Data
        bool isWithdrawalingorBorrowing;   
        bool isBeingLiquidated; 
    }
   
    enum MessageHeader {
        UpdateStateDeposit, //0

        ValidateWithdraw, //1
        UpdateStateWithdraw, //2
        
        ValidateBorrow, //3
        UpdateStateBorrow, //4
        
        UpdateStateRepay, //5

        ValidateSetUserUseReserveAsCollateral, //6

        ProcessLiquidationCallPhase2, //7

        ProcessLiquidationCallPhase3, //8
        
        UpdateStateLiquidationCallPhase3Case1, //9
        UpdateStateLiquidationCallPhase3Case2, //10

        RetryProcessLiquidationCallPhase3, //11

        EmergencyUpdateUser //12
    }
    
    struct ExecuteLiquidationCallParams {
        address user;
        uint256 chainsCount;
        address oracle;
        address debtAsset;
        address collateralAsset;
        uint256 debtChainId;
        uint256 collateralChainId;
        uint256 debtToCover;
        bool receiveTToken;
        address universalMessenger;
    }
}