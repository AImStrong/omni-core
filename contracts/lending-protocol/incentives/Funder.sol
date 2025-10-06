// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IBEP20} from "../../dependencies/openzeppelin/contracts/IBEP20.sol";

contract Funder is Ownable {

    constructor() Ownable(msg.sender) {}

    function transfer(address spender, address asset, uint256 amount) external onlyOwner {
        IBEP20(asset).transfer(spender, amount);
    }

    function appove(address spender, address asset, uint256 amount) external onlyOwner {
        _approve(spender, asset, amount);
    }

    function approveMax(address spender, address asset) internal {
        _approve(spender, asset, type(uint256).max);
    }

    function approveMaxBatch(address[] memory spenders, address[] memory assets) external onlyOwner {
        for (uint256 i = 0; i < assets.length; i++) {
            _approve(spenders[i], assets[i], type(uint256).max);
        }
    }

    function _approve(address spender, address asset, uint256 amount) internal {
        IBEP20(asset).approve(spender, amount);
    }
}