// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {Context} from "../../dependencies/openzeppelin/contracts/Context.sol";
import {IBEP20} from "../../dependencies/openzeppelin/contracts/IBEP20.sol";
import {SafeMath} from "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {ITravaIncentivesController} from "../interfaces/ITravaIncentivesController.sol";

/**
 * @title ERC20
 * @notice Basic ERC20 implementation
 **/
abstract contract IncentivizedBEP20 is Context, IBEP20 {
    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _owner;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _owner = msg.sender;
    }

    /**
     * @return The name of the token
     **/
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @return The symbol of the token
     **/
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @return The decimals of the token
     **/
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view override returns (address) {
        return _owner;
    }

    /**
     * @return The total supply of the token
     **/
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @return The balance of the token
     **/
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @return Abstract function implemented by the child tToken/debtToken.
     * Done this way in order to not break compatibility with previous versions of tTokens/debtTokens
     **/
    function _getIncentivesController() internal view virtual returns (ITravaIncentivesController);

    /**
     * @dev Executes a transfer of tokens from _msgSender() to recipient
     * @param recipient The recipient of the tokens
     * @param amount The amount of tokens being transferred
     * @return `true` if the transfer succeeds, `false` otherwise
     **/
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        emit Transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Returns the allowance of spender on the tokens owned by owner
     * @param owner The owner of the tokens
     * @param spender The user allowed to spend the owner's tokens
     * @return The amount of owner's tokens spender is allowed to spend
     **/
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev Allows `spender` to spend the tokens owned by _msgSender()
     * @param spender The user allowed to spend _msgSender() tokens
     * @return `true`
     **/
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Executes a transfer of token from sender to recipient, if _msgSender() is allowed to do so
     * @param sender The owner of the tokens
     * @param recipient The recipient of the tokens
     * @param amount The amount of tokens being transferred
     * @return `true` if the transfer succeeds, `false` otherwise
     **/
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount)
        );
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev Increases the allowance of spender to spend _msgSender() tokens
     * @param spender The user allowed to spend on behalf of _msgSender()
     * @param addedValue The amount being added to the allowance
     * @return `true`
     **/
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Decreases the allowance of spender to spend _msgSender() tokens
     * @param spender The user allowed to spend on behalf of _msgSender()
     * @param subtractedValue The amount being subtracted to the allowance
     * @return `true`
     **/
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue)
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "sender cannot be 0 address");
        require(recipient != address(0), "recipient cannot be 0 address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 oldSenderBalance = _balances[sender];
        _balances[sender] = oldSenderBalance.sub(amount);
        uint256 oldRecipientBalance = _balances[recipient];
        _balances[recipient] = _balances[recipient].add(amount);

        if (address(_getIncentivesController()) != address(0)) {
            uint256 currentTotalSupply = _totalSupply;
            _getIncentivesController().handleAction(
                sender,
                currentTotalSupply,
                oldSenderBalance
            );
            if (sender != recipient) {
                _getIncentivesController().handleAction(
                    recipient,
                    currentTotalSupply,
                    oldRecipientBalance
                );
            }
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "account cannot be 0 address");

        _beforeTokenTransfer(address(0), account, amount);

        uint256 oldTotalSupply = _totalSupply;
        _totalSupply = oldTotalSupply.add(amount);

        uint256 oldAccountBalance = _balances[account];
        _balances[account] = oldAccountBalance.add(amount);
        if (address(_getIncentivesController()) != address(0)) {
            _getIncentivesController().handleAction(
                account,
                oldTotalSupply,
                oldAccountBalance
            );
        }
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "account cannot be 0 address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 oldTotalSupply = _totalSupply;
        _totalSupply = oldTotalSupply.sub(amount);

        uint256 oldAccountBalance = _balances[account];
        _balances[account] = oldAccountBalance.sub(amount);

        if (address(_getIncentivesController()) != address(0)) {
            _getIncentivesController().handleAction(
                account,
                oldTotalSupply,
                oldAccountBalance
            );
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "owner cannot be 0 address");
        require(spender != address(0), "spender cannot be 0 address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setName(string memory newName) internal {
        _name = newName;
    }

    function _setSymbol(string memory newSymbol) internal {
        _symbol = newSymbol;
    }

    function _setDecimals(uint8 newDecimals) internal {
        _decimals = newDecimals;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}