// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

interface IPoolConfigurator {
    struct InitReserveInput {
        address tTokenImpl;
        address variableDebtTokenImpl;
        uint8 underlyingAssetDecimals;
        address interestRateStrategyAddress;
        address underlyingAsset;
        address treasury;
        address incentivesController;
        string underlyingAssetName;
        string tTokenName;
        string tTokenSymbol;
        string variableDebtTokenName;
        string variableDebtTokenSymbol;
        bytes params;
        uint256 reserveFactor;
    }

    struct UpdateTTokenInput {
        address asset;
        address treasury;
        address incentivesController;
        string name;
        string symbol;
        address implementation;
        bytes params;
    }

    struct UpdateDebtTokenInput {
        address asset;
        address incentivesController;
        string name;
        string symbol;
        address implementation;
        bytes params;
    }

    /**
     * @dev Emitted when a reserve is initialized.
     * @param asset The address of the underlying asset of the reserve
     * @param tToken The address of the associated tToken contract
     * @param variableDebtToken The address of the associated variable rate debt token
     * @param interestRateStrategyAddress The address of the interest rate strategy for the reserve
     **/
    event ReserveInitialized(
        address indexed asset,
        address indexed tToken,
        address variableDebtToken,
        address interestRateStrategyAddress
    );

    /**
     * @dev Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    event TokensRescued(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
     * dev drop reserve
     * @param asset address of reserve
     */
    event ReserveDropped(address indexed asset);

    /**
     * @dev Emitted when borrowing is enabled on a reserve
     * @param asset The address of the underlying asset of the reserve
     * @param variableBorrowRateEnabled True if variable borrow rate needs to be enabled by default on this reserve
     * @param stableBorrowRateEnabled True if stable borrow rate needs to be enabled by default on this reserve
     **/
    event SetReserveBorrowingEnabled(address indexed asset, bool variableBorrowRateEnabled, bool stableBorrowRateEnabled);

    /**
     * @dev Emitted when a reserve is activated
     * @param asset The address of the underlying asset of the reserve
     * @param active True if set reserve active
     **/
    event SetReserveActive(address indexed asset, bool active);

    /**
     * @dev Emitted when a reserve is frozen
     * @param asset The address of the underlying asset of the reserve
     * @param frozen True if set reserve freeze
     **/
    event SetReserveFrozen(address indexed asset, bool frozen);

    /**
     * @dev Emitted when a reserve factor is updated
     * @param asset The address of the underlying asset of the reserve
     * @param factor The new reserve factor
     **/
    event ReserveFactorChanged(address indexed asset, uint256 factor);

    /**
     * @dev Emitted when the reserve decimals are updated
     * @param asset The address of the underlying asset of the reserve
     * @param decimals The new decimals
     **/
    event ReserveDecimalsChanged(address indexed asset, uint256 decimals);

    /**
     * @dev Emitted when a reserve interest strategy contract is updated
     * @param asset The address of the underlying asset of the reserve
     * @param strategy The new address of the interest strategy contract
     **/
    event ReserveInterestRateStrategyChanged(
        address indexed asset,
        address strategy
    );

    /**
     * @dev Emitted when an tToken implementation is upgraded
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The tToken proxy address
     * @param implementation The new tToken implementation
     **/
    event TTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );

    /**
     * @dev Emitted when the implementation of a variable debt token is upgraded
     * @param asset The address of the underlying asset of the reserve
     * @param proxy The variable debt token proxy address
     * @param implementation The new tToken implementation
     **/
    event VariableDebtTokenUpgraded(
        address indexed asset,
        address indexed proxy,
        address indexed implementation
    );
}