// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IPool {

    event SetConfiguration (address indexed asset, uint256 indexedconfiguration);
    event Paused();
    event Unpaused();
    event OnCall(bool success, bytes err);

    /**
     * @dev handle message from connected messenger
     * @param header message header
     * @param data message payload
     */
    function handleInbound(
        uint8 header,
        bytes calldata data
    ) external;

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying tTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the tTokens
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent tTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     * @param to Address that will receive the underlying
     * @param returnNative Check if withdraw native
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to,
        bool returnNative
    ) external payable;

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 variable debt tokens
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt
     * @param returnNative Check if borrow native
     **/
    function borrow(
        address asset,
        uint256 amount,
        address onBehalfOf,
        bool returnNative,
        uint16 referralCode
    ) external payable;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset`
     * @param onBehalfOf Address of the user who will get his debt reduced/removed
     **/
    function repay(
        address asset,
        uint256 amount,
        address onBehalfOf
    ) external;

    /**
    * @dev Allows depositors to enable/disable a specific deposited asset as collateral
    * @param asset The address of the underlying asset deposited
    * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
    **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external payable;

    /**
     * @dev add reserve to pool
     * @param asset address of new reserve
     * @param tTokenAddress tToken address of new reserve
     * @param variableDebtAddress variableDebtToken address of new reserve
     * @param interestRateStrategyAddress interestRateStrategy address of new reserve
     */
    function initReserve(
        address asset,
        address tTokenAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    /**
     * @dev Rescue and transfer tokens locked in this contract
     * @param token The address of the token
     * @param to The address of the recipient
     * @param amount The amount of token to transfer
     */
    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external;

    /**
     * @dev drop reserve from reserves list
     * @param asset address of reserve
     */
    function dropReserve(address asset) external;

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    /**
     * @dev get all reserves in pool
     * @return Reserves list
     */
    function getReservesList() external view returns (address[] memory);

    /**
     * @dev get address provider
     * @return Address provider
     */
    function getAddressesProvider() external view returns (address);

    /**
     * @dev set rate strategy
     * @param reserve asset address
     * @param rateStrategyAddress new rate strategy
     */
    function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress) external;

    /**
     * @dev set configuration
     * @param reserve asset address
     * @param configuration new configuration
     */
    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset) external view returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev set pool pause
     * @param val pool pause true/false
     */
    function setPause(bool val) external;

    /**
     * @dev check if pool paused
     * @return Paused
     */
    function paused() external view returns (bool);

    /**
     * @dev pool owner use this function when zeta gateway failed, user token get stuck
     * @param user user address that has token stuck
     * @param asset user's asset 
     */
    function emergencyUpdateUserSupply(address user, address asset) external;
}