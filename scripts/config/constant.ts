import { BigNumber } from "ethers";
// ----------------
// MATH
// ----------------

const PERCENTAGE_FACTOR = '10000';
const HALF_PERCENTAGE = '5000';
const WAD = Math.pow(10, 18).toString();
const HALF_WAD = BigNumber.from(WAD).div(2).toString();
const RAY = BigNumber.from(10).pow(27).toString();
const HALF_RAY = BigNumber.from(RAY).div(2).toString();
const WAD_RAY_RATIO = Math.pow(10, 9).toString();
const oneEther = BigNumber.from(10).pow(18);
const oneRay = BigNumber.from(10).pow(27);

const MAX_UINT_AMOUNT =
  '115792089237316195423570985008687907853269984665640564039457584007913129639935';
const ONE_YEAR = '31536000';
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const ONE_ADDRESS = '0x0000000000000000000000000000000000000001';


export {
    PERCENTAGE_FACTOR,
    HALF_PERCENTAGE,
    WAD,
    HALF_WAD,
    RAY,
    HALF_RAY,
    WAD_RAY_RATIO,
    oneEther,
    oneRay,
    MAX_UINT_AMOUNT,
    ONE_YEAR,
    ZERO_ADDRESS,
    ONE_ADDRESS,
};
