// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title IInitializableTToken
 * @notice Interface for the initialize function on TToken
 * @author Trava
 **/
interface IInitializableTToken {
    /**
     * @dev Emitted when an tToken is initialized
     * @param underlyingAsset The address of the underlying asset
     * @param pool The address of the associated pool
     * @param treasury The address of the treasury
     * @param incentivesController The address of the incentives controller for this tToken
     * @param tTokenDecimals the decimals of the underlying
     * @param tTokenName the name of the tToken
     * @param tTokenSymbol the symbol of the tToken
     * @param params A set of encoded parameters for additional initialization
     **/
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address treasury,
        address incentivesController,
        uint8 tTokenDecimals,
        string tTokenName,
        string tTokenSymbol,
        bytes params
    );

    /**
     * @dev Initializes the tToken
     * @param pool The address of the pool where this tToken will be used
     * @param treasury The address of the Trava treasury, receiving the fees on this tToken
     * @param underlyingAsset The address of the underlying asset of this tToken (E.g. WETH for aWETH)
     * @param incentivesController The smart contract managing potential incentives distribution
     * @param tTokenDecimals The decimals of the tToken, same as the underlying asset's
     * @param tTokenName The name of the tToken
     * @param tTokenSymbol The symbol of the tToken
     */
    function initialize(
        address pool,
        address treasury,
        address underlyingAsset,
        address incentivesController,
        uint8 tTokenDecimals,
        string calldata tTokenName,
        string calldata tTokenSymbol,
        bytes calldata params
    ) external;
}
