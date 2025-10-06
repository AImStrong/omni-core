// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

/**
 * @title Errors library
 * @notice Defines the error messages emitted by the different contracts of the protocol
 * @dev Error messages prefix glossary:
 *  - CR = Controller (1-20)
 *  - CRC = ControllerConfiguration (21-40)
 *  - VL = ValidationLogic (41-80)
 *  - GL = GenericLogic (81-100)
 *  - LL = LiquidationLogic (101-120)
 *  - RC = ReserveConfiguration (121-140)
 *  - MATH = Math libraries (141-160)
 *  - UL = User Configuration (161 - 180)
 */
library Errors {
    // Controller errors (1-20)
    string public constant CR_IS_PAUSED = '1'; // Controller is paused
    string public constant CR_INVALID_HEADER_VALUE = '2'; // Invalid header value
    string public constant CR_USER_IN_LIQUIDATION = '3'; // User is in liquidation
    string public constant CR_NOT_ENOUGH_UNDERLYING_BALANCE = '4'; // Not enough underlying balance
    string public constant CR_WITHDRAW_BORROW_PENDING = '5'; // Withdraw/borrow pending
    string public constant CR_WITHDRAW_VALIDATION_FAILED = '6'; // Withdraw validation failed
    string public constant CR_BORROW_VALIDATION_FAILED = '7'; // Borrow validation failed
    string public constant CR_CHAIN_ALREADY_INITIALIZED = '8'; // Chain already initialized
    string public constant CR_CHAIN_NOT_INITIALIZED = '9'; // Chain not initialized
    string public constant CR_CALLER_NOT_CONTROLLER_CONFIGURATOR = '10'; // Caller not controller configurator
    string public constant CR_CALLER_NOT_UNIVERSAL_MESSENGER = '11'; // Caller not universal messenger
    string public constant CR_NO_MORE_RESERVES_ALLOWED = '12'; // No more reserves allowed
    string public constant CR_INVALID_MESSAGE_LENGTH = '13'; // Invalid message length
    string public constant CR_ZERO_ADDRESS = '14'; // zero address
    string public constant CR_ASSET_NOT_LISTED = '15'; // asset not listed

    // ControllerConfiguration errors (21-40)
    string public constant CRC_CALLER_NOT_CONTROLLER_OWNER = '21'; // Caller is not controller owner
    string public constant CRC_CALLER_NOT_UPDATE_MANAGER = '22'; // Caller is not update manager
    string public constant CRC_INVALID_LTV_THRESHOLD = '23'; // Invalid LTV threshold
    string public constant CRC_INVALID_BONUS = '24'; // Invalid bonus
    string public constant CRC_INVALID_THRESHOLD_BONUS_PRODUCT = '25'; // Invalid threshold bonus product
    string public constant CRC_INVALID_ZERO_BONUS = '26'; // Invalid zero bonus
    string public constant CRC_RESERVE_HAS_LIQUIDITY = '27'; // Reserve has liquidity

    // ValidationLogic errors (41-80)
    string public constant VL_INVALID_AMOUNT = '41'; // Amount must be greater than 0
    string public constant VL_NO_ACTIVE_RESERVE = '42'; // Action requires an active reserve
    string public constant VL_RESERVE_FROZEN = '43'; // Reserve is frozen
    string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '44'; // User cannot withdraw more than available balance
    string public constant VL_TRANSFER_NOT_ALLOWED = '45'; // Transfer cannot be allowed
    string public constant VL_COLLATERAL_BALANCE_IS_0 = '46'; // User has no collateral balance
    string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '47'; // Health factor is below liquidation threshold
    string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = '48'; // Collateral cannot cover the new borrow
    string public constant VL_NO_DEBT_OF_SELECTED_TYPE = '49'; // User has no debt of selected type
    string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '50'; // No explicit amount to repay on behalf
    string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '51'; // Underlying balance must be greater than 0
    string public constant VL_DEPOSIT_ALREADY_IN_USE = '52'; // Deposit is already being used as collateral
    string public constant VL_LIQUIDATION_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '53'; // Health factor is not below liquidation threshold
    string public constant VL_LIQUIDATION_COLLATERAL_CANNOT_BE_LIQUIDATED = '54'; // Collateral cannot be liquidated
    string public constant VL_LIQUIDATION_DEBT_MUST_BE_GT_0 = '55'; // User must have debt greater than 0 to be liquidated
    string public constant VL_BORROWING_NOT_ENABLED = '56'; // Borrowing is not enabled

    // GenericLogic errors (81-100)
    string public constant GL_INVALID_HEALTH_FACTOR = '81'; // Health factor is invalid
    string public constant GL_INVALID_LIQUIDATION_THRESHOLD = '82'; // Liquidation threshold is invalid
    string public constant GL_INVALID_BALANCE = '83'; // Balance is invalid

    // LiquidationLogic errors (101-120)
    string public constant LL_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = '101'; // Not enough liquidity to liquidate

    // ReserveConfiguration errors (121-140)
    string public constant RC_INVALID_LTV = '121'; // Invalid LTV value
    string public constant RC_INVALID_LIQ_THRESHOLD = '122'; // Invalid liquidation threshold
    string public constant RC_INVALID_LIQ_BONUS = '123'; // Invalid liquidation bonus
    string public constant RC_INVALID_DECIMALS = '124'; // Invalid decimals
    string public constant RC_INVALID_RESERVE_FACTOR = '125'; // Invalid reserve factor

    // Math errors (141-160)
    string public constant MATH_MULTIPLICATION_OVERFLOW = '141'; // Multiplication overflow
    string public constant MATH_ADDITION_OVERFLOW = '142'; // Addition overflow
    string public constant MATH_DIVISION_BY_ZERO = '143'; // Division by zero

   // UL (161-180)
   string public constant UL_INVALID_INDEX = '161'; // Invalid reserve index
   
}