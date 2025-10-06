import { ethers, network } from 'hardhat';
import { BigNumber } from "ethers";
import * as dotenv from 'dotenv';
dotenv.config();

const DECIMALS_MASK = BigNumber.from("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF");
const ACTIVE_MASK = BigNumber.from("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF");
const FROZEN_MASK = BigNumber.from("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF");
const BORROWING_MASK = BigNumber.from("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF");
const STABLE_BORROWING_MASK = BigNumber.from("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF");
const RESERVE_FACTOR_MASK = BigNumber.from("0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF");

const RESERVE_DECIMALS_START_BIT_POSITION = 48;
const IS_ACTIVE_START_BIT_POSITION = 56;
const IS_FROZEN_START_BIT_POSITION = 57;
const BORROWING_ENABLED_START_BIT_POSITION = 58;
const STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
const RESERVE_FACTOR_START_BIT_POSITION = 64;

const UINT256_MAX = BigNumber.from("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");

function not(x: BigNumber): BigNumber {
    return UINT256_MAX.sub(x);
}

function decodeConfiguration(config: BigNumber) {
    const decimals = config.and(not(DECIMALS_MASK)).shr(RESERVE_DECIMALS_START_BIT_POSITION);

    const isActive = !config.and(not(ACTIVE_MASK)).eq(0);
    const isFrozen = !config.and(not(FROZEN_MASK)).eq(0);
    const borrowingEnabled = !config.and(not(BORROWING_MASK)).eq(0);
    const stableBorrowingEnabled = !config.and(not(STABLE_BORROWING_MASK)).eq(0);

    const reserveFactor = config.and(not(RESERVE_FACTOR_MASK)).shr(RESERVE_FACTOR_START_BIT_POSITION);

    return {
        decimals: decimals.toNumber(),
        isActive,
        isFrozen,
        borrowingEnabled,
        stableBorrowingEnabled,
        reserveFactor: reserveFactor.toNumber(),
    };
}

export {
    decodeConfiguration
}