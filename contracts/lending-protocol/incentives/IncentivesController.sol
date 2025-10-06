// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import {IPool} from "../interfaces/IPool.sol";
import {ITToken} from "../interfaces/ITToken.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {WadRayMath} from "../libraries/math/WadRayMath.sol";

contract IncentivesController is Pausable {
    using SafeERC20 for IERC20;
    using WadRayMath for uint256;

    struct StakerInfo {
        uint256 index; // index for staking
        uint256 pendingReward;
        uint256 lastTimeUpdated;
        uint256 lastLendingIndex; // index for calculate true underlying token: underyling token = scale amount * index lending;
    }

    // storage
    address public governance;
    address public funder;
    address public lendingPool;
    uint256 public lendingIndexAtTimeStart;
    address public tokenStaked;
    address public tokenRewards;
    uint256 public globalIndex;
    uint256 public lastUpdated;
    uint256 public rps; // rate per second for 1 unit of token, rps decimals = CALCULATE_PRECISION
    uint256 public totalStaker;
    uint256 public stakeStart;
    uint256 public stakeEnd;

    uint256 public constant CALCULATE_PRECISION = 1e27;

    mapping(address => StakerInfo) public stakers;
    mapping(address => bool) public newStakers;
    mapping(address => bool) public admins;

    // event
    event Staked(address indexed user);
    event Unstaked(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount);

    // modifier
    modifier onlyGovernance() {
        require(msg.sender == governance, "caller not governance");
        _;
    }

    modifier onlyAdmin() {
        require(
            admins[msg.sender] || msg.sender == governance,
            "caller not admin"
        );
        _;
    }

    modifier onlyLendingPool() {
        require(msg.sender == lendingPool, "caller not lending pool");
        _;
    }

    // constructor
    constructor(address governance_) {
        require(governance_ != address(0), "governance cannot be 0 address");
        governance = governance_;
    }

    // in case this contract is upgradeable, constructer is unuseable, use this function instead
    function initialize(address governance_) external {
        require(governance == address(0), "governance already initialized");
        require(governance_ != address(0), "governance cannot be 0 address");
        governance = governance_;
    }

    // setter
    function setGovernance(address governance_) external onlyGovernance {
        require(governance_ != address(0), "governance cannot be 0 address");
        governance = governance_;
    }

    function setAdmin(address admin, bool isAdmin) external onlyGovernance {
        admins[admin] = isAdmin;
    }

    function setData(
        address _funder,
        address _lendingPool,
        uint256 _lendingIndex,
        address _tokenRewards,
        address _tokenStaked,
        uint256 _rps,
        uint256 _stakeStart,
        uint256 _stakeEnd
    ) external onlyAdmin {
        require(_lendingIndex >= WadRayMath.ray(), "lending index must >= 1");

        funder = _funder;
        lendingPool = _lendingPool;
        lendingIndexAtTimeStart = _lendingIndex;
        tokenRewards = _tokenRewards;
        tokenStaked = _tokenStaked;
        rps = _rps;
        stakeStart = _stakeStart;
        stakeEnd = _stakeEnd;
    }

    function updateFunder(address _funder) public onlyAdmin {
        funder = _funder;
    }

    function updateLendingPool(address _lendingPool) public onlyAdmin {
        lendingPool = _lendingPool;
    }

    function updateLendingIndex(uint256 _index) public onlyAdmin {
        require(_index >= WadRayMath.ray(), "lending index must >= 1");
        lendingIndexAtTimeStart = _index;
    }

    function updateRps(uint256 _rps) public onlyAdmin {
        updateGlobalIndex();
        rps = _rps;
    }

    function updateStakeTime(uint256 _start, uint256 _end) public onlyAdmin {
        stakeStart = _start;
        stakeEnd = _end;
    }

    // incentives functions

    function poolTrigger(address user) public onlyLendingPool {
        _trigger(user);
        emit Staked(user);
    }

    function updateGlobalIndex() public {
        uint256 currentTime = block.timestamp;
        uint256 timePassed = currentTime - lastUpdated;

        if (timePassed > 0) globalIndex += ratePerSecond() * timePassed;

        if (block.timestamp <= stakeStart) {
            IPool pool = IPool(lendingPool);
            uint256 currentPoolIndex = pool.getReserveNormalizedIncome(tokenStaked);
            if (lendingIndexAtTimeStart < currentPoolIndex) lendingIndexAtTimeStart = currentPoolIndex;
        }
        lastUpdated = currentTime;
    }

    function updateReward(address account) public {
        updateGlobalIndex();
        StakerInfo storage stakeData = stakers[account];
        uint256 userBalance = balanceOf(account);
        stakeData.pendingReward +=
            ((globalIndex - stakeData.index) * userBalance) /
            CALCULATE_PRECISION;
        stakeData.index = globalIndex;

        IPool pool = IPool(lendingPool);
        uint256 mulFactor = pool.getReserveNormalizedIncome(tokenStaked);
        stakeData.lastLendingIndex = mulFactor;
        stakeData.lastTimeUpdated = lastUpdated;
    }

    function claimReward() public {
        _claimReward(msg.sender);
    }

    function viewReward(address account) public view returns (uint256) {
        StakerInfo storage stakeData = stakers[account];
        uint256 currentTime = block.timestamp;
        uint256 timePassed = currentTime - lastUpdated;
        uint256 globalIndexNow = globalIndex;
        if (timePassed > 0) globalIndexNow += ratePerSecond() * timePassed;
        uint256 claimable = stakeData.pendingReward +
            ((globalIndexNow - stakeData.index) * balanceOf(account)) /
            CALCULATE_PRECISION;
        return claimable;
    }

    function emergencyWithdraw(
        address token,
        uint256 amount
    ) public onlyGovernance {
        // this contract shouldn't hold any token, if any token stuck, use this function
        _transfer(address(this), governance, token, amount);
    }

    function ratePerSecond() public view returns (uint256) {
        if (block.timestamp < stakeStart || block.timestamp > stakeEnd)
            return 0;
        return rps;
    }

    function balanceOf(address user) public view returns (uint256) {
        IPool pool = IPool(lendingPool);
        DataTypes.ReserveData memory reserve = pool.getReserveData(tokenStaked);
        ITToken tToken = ITToken(reserve.tTokenAddress);
        uint256 scaledBalance = tToken.scaledBalanceOf(user);

        StakerInfo memory stakeData = stakers[user];
        // first time trigger
        if (stakeData.lastTimeUpdated == 0) {
            return scaledBalance.rayMul(lendingIndexAtTimeStart);
        }
        return scaledBalance.rayMul(stakeData.lastLendingIndex);
    }

    // internal functions
    function _transfer(
        address from,
        address to,
        address token,
        uint256 amount
    ) internal {
        IERC20(token).transferFrom(from, to, amount);
    }

    function _updateTotalStaker(address account) internal {
        if (!newStakers[account]) {
            newStakers[account] = true;
            totalStaker += 1;
        }
    }

    function _trigger(address user) internal {
        updateReward(user);
        _updateTotalStaker(user);
    }

    function _claimReward(address user) internal {
        updateReward(user);
        StakerInfo storage stakeData = stakers[user];
        uint256 claimable = stakeData.pendingReward;
        stakeData.pendingReward = 0;
        _transfer(funder, user, tokenRewards, claimable);
        emit Claimed(user, claimable);
    }

    function pause() public onlyGovernance {
        _pause();
    }

    function unpause() public onlyGovernance {
        _unpause();
    }
}
