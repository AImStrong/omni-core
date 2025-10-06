// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

import {IStakedToken} from "./IStakedToken.sol";

interface IStakedTokenWithConfig is IStakedToken {
    function STAKED_TOKEN() external view override returns (address);
}
