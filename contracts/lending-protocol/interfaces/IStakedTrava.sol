// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IStakedTrava {
    function stake(address to, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function cooldown() external;

    function claimRewards(address to, uint256 amount) external;
}
