// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

pragma experimental ABIEncoderV2;

import {IBEP20} from "../../dependencies/openzeppelin/contracts/IBEP20.sol";
import {SafeMath} from "../../dependencies/openzeppelin/contracts/SafeMath.sol";
import {SafeBEP20} from "../../dependencies/openzeppelin/contracts/SafeBEP20.sol";
import {IPool} from "../interfaces/IPool.sol";
import {ITToken} from "../interfaces/ITToken.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";
import {VersionedInitializable} from "../libraries/upgradeability/VersionedInitializable.sol";
import {IncentivizedBEP20} from "./IncentivizedBEP20.sol";
import {ITravaIncentivesController} from "../interfaces/ITravaIncentivesController.sol";

/**
 * @title Trava ERC20 TToken
 * @dev Implementation of the interest bearing token for the Trava
 * @author Trava
 */
contract TToken is
    VersionedInitializable,
    IncentivizedBEP20("TTOKEN_IMPL", "TTOKEN_IMPL", 0),
    ITToken
{
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using SafeBEP20 for IBEP20;

    bytes public constant EIP712_REVISION = bytes("1");
    bytes32 internal constant EIP712_DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    uint256 public constant TTOKEN_REVISION = 0x8;

    /// @dev owner => next valid nonce to submit with permit()
    mapping(address => uint256) public _nonces;

    /**
     * @dev Mapping user to his latest minting action block timestamp for 
     * the purpose of preventing flashloan action on the token
     */
    mapping(address => uint) internal previousBlock;

    bytes32 public DOMAIN_SEPARATOR;

    IPool internal _pool;
    address internal _treasury;
    address internal _underlyingAsset;
    ITravaIncentivesController internal _incentivesController;

    modifier onlyPool {
        require(
            _msgSender() == address(_pool),
            "Caller not pool"
        );
        _;
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return TTOKEN_REVISION;
    }

    /**
     * @dev Initializes the tToken
     * @param pool The address of the pool where this tToken will be used
     * @param treasury The address of the treasury, receiving the fees on this tToken
     * @param underlyingAsset The address of the underlying asset of this tToken (E.g. WETH for tWETH)
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
    ) external override initializer {
        uint256 chainId;

        //solium-disable-next-line
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN,
                keccak256(bytes(tTokenName)),
                keccak256(EIP712_REVISION),
                chainId,
                address(this)
            )
        );

        _setName(tTokenName);
        _setSymbol(tTokenSymbol);
        _setDecimals(tTokenDecimals);

        _pool = IPool(pool);
        _treasury = treasury;
        _underlyingAsset = underlyingAsset;
        _incentivesController = ITravaIncentivesController(incentivesController);

        emit Initialized(
            underlyingAsset,
            address(pool),
            treasury,
            address(incentivesController),
            tTokenDecimals,
            tTokenName,
            tTokenSymbol,
            params
        );
    }

    /**
     * @dev Burns tTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * - Only callable by the Pool, as extra state updates there need to be managed
     * @param user The owner of the tTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external override onlyPool {
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, "invaled scaled amount");
        _burn(user, amountScaled);

        IBEP20(_underlyingAsset).safeTransfer(receiverOfUnderlying, amount);

        emit Transfer(user, address(0), amount);
        emit Burn(user, receiverOfUnderlying, amount, index);
    }

    /**
     * @dev Mints `amount` tTokens to `user`
     * - Only callable by the Pool, as extra state updates there need to be managed
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external override onlyPool returns (bool) {
        uint256 previousBalance = super.balanceOf(user);

        uint256 amountScaled = amount.rayDiv(index);

        // Save the timestamp of the latest minting action
        previousBlock[user] = block.timestamp ;

        require(amountScaled != 0, "invalid scaled amount");
        _mint(user, amountScaled);

        emit Transfer(address(0), user, amount);
        emit Mint(user, amount, index);

        return previousBalance == 0;
    }

    /**
     * @dev Mints tTokens to the reserve treasury
     * - Only callable by the Pool
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external override onlyPool {
        if (amount == 0) {
            return;
        }

        address treasury = _treasury;

        // Compared to the normal mint, we don't check for rounding errors.
        // The amount to mint can easily be very small since it is a fraction of the interest ccrued.
        // In that case, the treasury will experience a (very small) loss, but it
        // wont cause potentially valid transactions to fail.
        _mint(treasury, amount.rayDiv(index));

        emit Transfer(address(0), treasury, amount);
        emit Mint(treasury, amount, index);
    }

    /**
     * @dev Transfers tTokens in the event of a borrow being liquidated, in case the liquidators reclaims the tToken
     * - Only callable by the Pool
     * @param from The address getting liquidated, current owner of the tTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external override onlyPool {
        // Being a normal transfer, the Transfer() and BalanceTransfer() are emitted
        // so no need to emit a specific event here
        _transfer(from, to, value, false);

        emit Transfer(from, to, value);
    }

    /**
     * @dev Calculates the balance of the user: principal balance + interest generated by the principal
     * @param user The user whose balance is calculated
     * @return The balance of the user
     **/
    function balanceOf(address user) public view override(IncentivizedBEP20, IBEP20) returns (uint256) {
        return
            super.balanceOf(user).rayMul(
                _pool.getReserveNormalizedIncome(_underlyingAsset)
            );
    }

    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view override returns (uint256) {
        return super.balanceOf(user);
    }

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user) external view override returns (uint256, uint256) {
        return (super.balanceOf(user), super.totalSupply());
    }

    /**
     * @dev calculates the total supply of the specific tToken
     * since the balance of every single user increases over time, the total supply
     * does that too.
     * @return the current total supply
     **/
    function totalSupply() public view override(IncentivizedBEP20, IBEP20) returns (uint256) {
        uint256 currentSupplyScaled = super.totalSupply();

        if (currentSupplyScaled == 0) {
            return 0;
        }

        return
            currentSupplyScaled.rayMul(
                _pool.getReserveNormalizedIncome(_underlyingAsset)
            );
    }

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return the scaled total supply
     **/
    function scaledTotalSupply() public view virtual override returns (uint256) {
        return super.totalSupply();
    }

    /**
     * @dev Returns the address of the treasury, receiving the fees on this tToken
     **/
    function RESERVE_TREASURY_ADDRESS() public view returns (address) {
        return _treasury;
    }

    /**
     * @dev Returns the address of the underlying asset of this tToken (E.g. WETH for tWETH)
     **/
    function UNDERLYING_ASSET_ADDRESS() public view override returns (address) {
        return _underlyingAsset;
    }

    /**
     * @dev Returns the address of the pool where this tToken is used
     **/
    function POOL() public view returns (IPool) {
        return _pool;
    }

    /**
     * @dev For internal usage in the logic of the parent contract IncentivizedERC20
     **/
    function _getIncentivesController() internal view override returns (ITravaIncentivesController) {
        return _incentivesController;
    }

    /**
     * @dev Returns the address of the incentives controller contract
     **/
    function getIncentivesController() external view override returns (address) {
        return address(_getIncentivesController());
    }

    /**
     * @dev Transfers the underlying asset to `target`. Used by the Pool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param target The recipient of the tTokens
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(address target, uint256 amount) external override onlyPool returns (uint256) {
        IBEP20(_underlyingAsset).safeTransfer(target, amount);
        return amount;
    }

    /**
     * @dev Invoked to execute actions on the tToken side after a repayment.
     * @param user The user executing the repayment
     * @param amount The amount getting repaid
     **/
    function handleRepayment(address user, uint256 amount) external override onlyPool {}

    /**
     * @dev implements the permit function as for
     * https://github.com/ethereum/EIPs/blob/8a34d644aacf0f9f8f00815307fd7dd5da07655f/EIPS/eip-2612.md
     * @param owner The owner of the funds
     * @param spender The spender
     * @param value The amount
     * @param deadline The deadline timestamp, type(uint256).max for max deadline
     * @param v Signature param
     * @param s Signature param
     * @param r Signature param
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(owner != address(0), "Invalid owner");
        //solium-disable-next-line
        require(block.timestamp <= deadline, "Invalid expiration");
        uint256 currentValidNonce = _nonces[owner];
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            value,
                            currentValidNonce,
                            deadline
                        )
                    )
                )
            );
        require(owner == ecrecover(digest, v, r, s), "Invalid signature");
        _nonces[owner] = currentValidNonce.add(1);
        _approve(owner, spender, value);
    }

    /**
     * @dev Transfers the tTokens between two users. Validates the transfer
     * (ie checks for valid HF after the transfer) if required
     * @param from The source address
     * @param to The destination address
     * @param amount The amount getting transferred
     * @param validate `true` if the transfer needs to be validated
     **/
    function _transfer(
        address from,
        address to,
        uint256 amount,
        bool validate
    ) internal {
        // The current timestamp must be greater than the previousBlock to transfer
        require( block.timestamp > previousBlock[msg.sender], "transfer not allowed in same block");

        address underlyingAsset = _underlyingAsset;
        IPool pool = _pool;

        uint256 index = pool.getReserveNormalizedIncome(underlyingAsset);

        // uint256 fromBalanceBefore = super.balanceOf(from).rayMul(index);
        // uint256 toBalanceBefore = super.balanceOf(to).rayMul(index);

        super._transfer(from, to, amount.rayDiv(index));

        // add param Pool adress
        if (validate) {
            revert("Transfer not supported");
        }

        emit BalanceTransfer(from, to, amount, index);
    }

    /**
     * @dev Overrides the parent _transfer to force validated transfer() and transferFrom()
     * @param from The source address
     * @param to The destination address
     * @param amount The amount getting transferred
     **/
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        _transfer(from, to, amount, true);
    }
}