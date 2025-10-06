import { oneRay } from './constant';
import { BigNumber } from 'ethers';

// ----------------
// RESERVES CONFIG
// ----------------
const reservesParamsConfig = {
    USDC: {
        baseLTVAsCollateral: 7500,
        liquidationThreshold: 7800,
        liquidationBonus: 10500,
        reserveFactor: 1000,
        utilizationOptimal: BigNumber.from(0.9*10**9).mul(oneRay).div(BigNumber.from(10**9)),
        BaseInterstRate: 0,
        slope1: BigNumber.from(0.065*10**9).mul(oneRay).div(BigNumber.from(10**9)),
        slope2: BigNumber.from(0.4*10**9).mul(oneRay).div(BigNumber.from(10**9))
    },
    USDT: {
        baseLTVAsCollateral: 7500,
        liquidationThreshold: 8000,
        liquidationBonus: 10500,
        reserveFactor: 1000,
        utilizationOptimal: BigNumber.from(0.9*10**9).mul(oneRay).div(BigNumber.from(10**9)),
        BaseInterstRate: 0,
        slope1: BigNumber.from(0.065*10**9).mul(oneRay).div(BigNumber.from(10**9)),
        slope2: BigNumber.from(0.4*10**9).mul(oneRay).div(BigNumber.from(10**9))
    },
    WETH: {
        baseLTVAsCollateral: 8000,
        liquidationThreshold: 8400,
        liquidationBonus: 10500,
        reserveFactor: 1500,
        utilizationOptimal: BigNumber.from(0.9*10**9).mul(oneRay).div(BigNumber.from(10**9)),
        BaseInterstRate: 0,
        slope1: BigNumber.from(0.027*10**9).mul(oneRay).div(BigNumber.from(10**9)),
        slope2: BigNumber.from(0.8*10**9).mul(oneRay).div(BigNumber.from(10**9))
    },
    WBNB: {
        baseLTVAsCollateral: 7000,
        liquidationThreshold: 7500,
        liquidationBonus: 10500,
        reserveFactor: 2000,
        utilizationOptimal: BigNumber.from(0.45*10**9).mul(oneRay).div(BigNumber.from(10**9)),
        BaseInterstRate: 0,
        slope1: BigNumber.from(0.07*10**9).mul(oneRay).div(BigNumber.from(10**9)),
        slope2: BigNumber.from(0.3*10**9).mul(oneRay).div(BigNumber.from(10**9))
    },
    cbBTC: {
        baseLTVAsCollateral: 7300,
        liquidationThreshold: 7800,
        liquidationBonus: 10750,
        reserveFactor: 5000,
        utilizationOptimal: BigNumber.from(0.8*10**9).mul(oneRay).div(BigNumber.from(10**9)),
        BaseInterstRate: 0,
        slope1: BigNumber.from(0.04*10**9).mul(oneRay).div(BigNumber.from(10**9)),
        slope2: BigNumber.from(0.6*10**9).mul(oneRay).div(BigNumber.from(10**9)),
        decimals: 8
    },
    WBTC: {
        baseLTVAsCollateral: 7300,
        liquidationThreshold: 7800,
        liquidationBonus: 10700,
        reserveFactor: 5000,
        utilizationOptimal: BigNumber.from(0.8*10**9).mul(oneRay).div(BigNumber.from(10**9)),
        BaseInterstRate: 0,
        slope1: BigNumber.from(0.04*10**9).mul(oneRay).div(BigNumber.from(10**9)),
        slope2: BigNumber.from(3*10**9).mul(oneRay).div(BigNumber.from(10**9)),
        decimals: 8
    }
}

export {
    reservesParamsConfig
};