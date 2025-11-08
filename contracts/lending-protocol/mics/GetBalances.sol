// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {BEP20} from "../../dependencies/openzeppelin/contracts/BEP20.sol";
import {CrossChainLendingController} from "../../controller-protocol/controller/CrossChainLendingController.sol";

contract GetBalances {
    function balances(address[] memory users, address token) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            result[i] = BEP20(token).balanceOf(users[i]);
        }
        return result;
    }

    function getIncome(address[] memory users, address controller, address token, uint256 chainId) public view returns (uint256[] memory) {
        uint256[] memory result = new uint256[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            (result[i],,) = CrossChainLendingController(controller).getUserAssetData(users[i], token, chainId);
        }
        return result;
    }
}