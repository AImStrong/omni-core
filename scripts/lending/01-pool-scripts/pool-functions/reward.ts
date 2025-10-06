import { ethers, network } from 'hardhat';
import { BigNumber } from 'ethers';
import { encode } from '../../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function setAdmin(asset: string, admin: string, isAdmin: boolean) {
    let networkName = network.name;
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    const reward = await ethers.getContractAt(`IncentivesController`, await incentives.getVault(asset));

    const data = encode(`setAdmin(address,bool)`, [admin, isAdmin]);
    console.log(reward.address);
    console.log(data);

    console.log("is admin: ", await reward.admins(admin));
}

async function updateFunder(asset: string, funder: string) {
    let networkName = network.name;
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    const reward = await ethers.getContractAt(`IncentivesController`, await incentives.getVault(asset));

    const data = encode(`updateFunder(address)`, [funder]);
    // await execute(multiSigWallet.address, reward.address, data);
    console.log(data);

    console.log("funder: ", await reward.funder());
}

async function updateLendingPool(asset: string, lending: string) {
    let networkName = network.name;
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    const reward = await ethers.getContractAt(`IncentivesController`, await incentives.getVault(asset));

    const data = encode(`updateLendingPool(address)`, [lending]);
    console.log(data);

    console.log("lending: ", await reward.lendingPool());
}

async function updateLendingIndex(asset: string, index: BigNumber) {
    let networkName = network.name;
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    const reward = await ethers.getContractAt(`IncentivesController`, await incentives.getVault(asset));

    const data = encode(`updateLendingIndex(uint256)`, [index]);
    console.log(data);

    console.log("lending index: ", await reward.lendingIndexAtTimeStart());
}

async function updateRps(asset: string, rps: BigNumber) {
    let networkName = network.name;
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    const reward = await ethers.getContractAt(`IncentivesController`, await incentives.getVault(asset));

    const data = encode(`updateRps(uint256)`, [rps]);
    console.log(data);

    console.log("rps: ", await reward.rps());
}

async function updateStakeTime(asset: string, start: BigNumber, end: BigNumber) {
    let networkName = network.name;
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    const reward = await ethers.getContractAt(`IncentivesController`, await incentives.getVault(asset));

    const data = encode(`updateStakeTime(uint256,uint256)`, [start, end]);
    console.log(data);

    console.log("start: ", await reward.stakeStart());
    console.log("end: ", await reward.stakeEnd());
}

export {
    setAdmin,
    updateFunder,
    updateLendingPool,
    updateLendingIndex,
    updateRps,
    updateStakeTime
}