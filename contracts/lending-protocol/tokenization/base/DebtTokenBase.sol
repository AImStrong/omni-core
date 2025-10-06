// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {IPool} from "../../interfaces/IPool.sol";
import {SafeMath} from "../../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {ICreditDelegationToken} from "../../interfaces/ICreditDelegationToken.sol";
import {VersionedInitializable} from "../../libraries/upgradeability/VersionedInitializable.sol";
import {IncentivizedBEP20} from "../IncentivizedBEP20.sol";

/**
 * @title DebtTokenBase
 * @notice Base contract for different types of debt tokens, like StableDebtToken or VariableDebtToken
 */

abstract contract DebtTokenBase is
    IncentivizedBEP20("DEBTTOKEN_IMPL", "DEBTTOKEN_IMPL", 0),
    VersionedInitializable,
    ICreditDelegationToken
{
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) internal _borrowAllowances;

    /**
     * @dev Only pool can call functions marked by this modifier
     **/
    modifier onlyPool {
        require(
            _msgSender() == address(_getPool()),
            "Caller not pool"
        );
        _;
    }

    /**
     * @dev delegates borrowing power to a user on the specific debt token
     * @param delegatee the address receiving the delegated borrowing power
     * @param amount the maximum amount being delegated. Delegation will still
     * respect the liquidation constraints (even if delegated, a delegatee cannot
     * force a delegator HF to go below 1)
     **/
    function approveDelegation(address delegatee, uint256 amount) external override {
        _borrowAllowances[_msgSender()][delegatee] = amount;
        emit BorrowAllowanceDelegated(
            _msgSender(),
            delegatee,
            _getUnderlyingAssetAddress(),
            amount
        );
    }

    /**
     * @dev returns the borrow allowance of the user
     * @param fromUser The user to giving allowance
     * @param toUser The user to give allowance to
     * @return the current allowance of toUser
     **/
    function borrowAllowance(address fromUser, address toUser) external view override returns (uint256) {
        return _borrowAllowances[fromUser][toUser];
    }

    /**
     * @dev Being non transferrable, the debt token does not implement any of the
     * standard ERC20 functions for transfer and allowance.
     **/
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        recipient;
        amount;
        revert("NOT SUPPORTED");
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        owner;
        spender;
        revert("NOT SUPPORTED");
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        spender;
        amount;
        revert("NOT SUPPORTED");
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        sender;
        recipient;
        amount;
        revert("NOT SUPPORTED");
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        spender;
        addedValue;
        revert("NOT SUPPORTED");
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        spender;
        subtractedValue;
        revert("NOT SUPPORTED");
    }

    function _decreaseBorrowAllowance(
        address delegator,
        address delegatee,
        uint256 amount
    ) internal {
        uint256 newAllowance =
            _borrowAllowances[delegator][delegatee].sub(
                amount,
                "Borrow allowance not enough"
            );

        _borrowAllowances[delegator][delegatee] = newAllowance;

        emit BorrowAllowanceDelegated(
            delegator,
            delegatee,
            _getUnderlyingAssetAddress(),
            newAllowance
        );
    }

    function _getUnderlyingAssetAddress() internal view virtual returns (address);

    function _getPool() internal view virtual returns (IPool);
}