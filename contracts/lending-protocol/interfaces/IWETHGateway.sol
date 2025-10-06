// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWETHGateway {

    event DepositETH(
        address pool, 
        address onBehalfOf, 
        uint16 referralCode
    );

    event RepayETH(
        address pool, 
        uint256 amount, 
        address onBehalfOf
    );

    /**
    * @dev deposits WETH into the reserve, using native ETH. A corresponding amount of the overlying asset (aTokens)
    * is minted.
    * @param pool address of the targeted underlying lending pool
    * @param onBehalfOf address of the user who will receive the aTokens representing the deposit
    * @param referralCode integrators are assigned a referral code and can potentially receive rewards.
    **/
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    /**
    * @dev repays a borrow on the WETH reserve, for the specified amount (or for the whole amount, if uint256(-1) is specified).
    * @param lendingPool address of the targeted underlying lending pool
    * @param amount the amount to repay, or uint256(-1) if the user wants to repay everything
    * @param onBehalfOf the address for which msg.sender is repaying
    */
    function repayETH(
        address lendingPool,
        uint256 amount,
        address onBehalfOf
    ) external payable;
}