// SPDX-License-Identifier: MIT
// pragma solidity 0.6.12;
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {IBEP20} from '../../dependencies/openzeppelin/contracts/IBEP20.sol';
import {IWETH} from '../interfaces/IWETH.sol';
import {IWETHGateway} from '../interfaces/IWETHGateway.sol';
import {IPool} from '../interfaces/IPool.sol';
import {ITToken} from '../interfaces/ITToken.sol';
import {ReserveConfiguration} from '../libraries/configuration/ReserveConfiguration.sol';
import {Helpers} from '../libraries/helpers/Helpers.sol';
import {DataTypes} from '../libraries/types/DataTypes.sol';

contract WETHGateway is IWETHGateway {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    address public immutable weth;

    /**
     * @dev Sets the WETH address and the LendingPoolAddressesProvider address. Infinite approves lending pool.
     * @param _weth Address of the Wrapped Ether contract
     **/
    constructor(address _weth) {
        weth = _weth;
    }

    // @inheritdoc IWETHGateway
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable override {
        IWETH(weth).deposit{value: msg.value}();

        // Approve WETH to the lending pool
        IWETH(weth).approve(pool, msg.value);

        // Deposit WETH into the lending pool
        IPool(pool).deposit(address(weth), msg.value, onBehalfOf, referralCode);

        emit DepositETH(pool, onBehalfOf, referralCode);
    }

    // @inheritdoc IWETHGateway
    function repayETH(
        address pool,
        uint256 amount,
        address onBehalfOf
    ) external payable override {
        
        uint256 paybackAmount = Helpers.getUserCurrentDebtMemory(
            onBehalfOf,
            IPool(pool).getReserveData(address(weth))
        );

        if (amount < paybackAmount) {
            paybackAmount = amount;
        }

        require(msg.value >= paybackAmount, 'msg.value is less than repayment amount');
        IWETH(weth).deposit{value: paybackAmount}();

        // Approve WETH to the lending pool 
        IWETH(weth).approve(pool, paybackAmount);
        IPool(pool).repay(weth, paybackAmount, onBehalfOf);

        // refund remaining dust eth
        if (msg.value > paybackAmount) _safeTransferETH(msg.sender, msg.value - paybackAmount);

        emit RepayETH(pool, amount, onBehalfOf);
    }

    /**
    * @dev transfer ETH to an address, revert if it fails.
    * @param to recipient of the transfer
    * @param value the amount to send
    */
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }

    /**
    * @dev Only WETH contract is allowed to transfer ETH here. Prevent other addresses to send Ether to this contract.
    */
    receive() external payable {
        require(msg.sender == address(weth), 'Receive not allowed');
    }

    /**
    * @dev Revert fallback calls
    */
    fallback() external payable {
        revert('Fallback not allowed');
    }
}