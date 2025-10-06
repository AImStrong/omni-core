// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title IReserveInterestRateStrategyInterface interface
 * @dev Interface for the calculation of the interest rates
 * @author Trava
 */
interface IReserveInterestRateStrategy {
    function baseVariableBorrowRate() external view returns (uint256);

    function getMaxVariableBorrowRate() external view returns (uint256);

    function calculateInterestRates(
        uint256 availableLiquidity,
        uint256 totalVariableDebt,
        uint256 reserveFactor
    ) external view returns (uint256, uint256);

    function calculateInterestRates(
        address reserve,
        address tToken,
        uint256 liquidityAdded,
        uint256 liquidityTaken,
        uint256 totalVariableDebt,
        uint256 reserveFactor
    ) external view returns (uint256 liquidityRate, uint256 variableBorrowRate);
}
