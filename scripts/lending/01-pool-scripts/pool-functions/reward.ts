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

async function updateFunder(assets: string[]) {
    let networkName = network.name;
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);

    for (let i = 0; i < assets.length; i++) {
        const data = encode(`updateFunder(address)`, [process.env[`${networkName.toUpperCase()}_FUNDER`]!]);
        console.log(await incentives.getVault(assets[i]));
        console.log(data);
    }

    for (let i = 0; i < assets.length; i++) {
        const reward = await ethers.getContractAt(`IncentivesController`, await incentives.getVault(assets[i]));
        console.log(await reward.funder());
    }
}

async function updateLendingPool(asset: string, lending: string) {
    let networkName = network.name;
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    const reward = await ethers.getContractAt(`IncentivesController`, await incentives.getVault(asset));

    const data = encode(`updateLendingPool(address)`, [lending]);
    console.log(reward.address);
    console.log(data);

    console.log("lending: ", await reward.lendingPool());
}

async function updateLendingIndex(asset: string, index: BigNumber) {
    let networkName = network.name;
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    const reward = await ethers.getContractAt(`IncentivesController`, await incentives.getVault(asset));

    const data = encode(`updateLendingIndex(uint256)`, [index]);
    console.log(reward.address);
    console.log(data);

    console.log("lending index: ", await reward.lendingIndexAtTimeStart());
}

async function updateRps(asset: string, rps: BigNumber) {
    let networkName = network.name;
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    const reward = await ethers.getContractAt(`IncentivesController`, await incentives.getVault(asset));

    const data = encode(`updateRps(uint256)`, [rps]);
    console.log(reward.address);
    console.log(data);

    console.log("rps: ", await reward.rps());
}

async function updateStakeTime(asset: string, start: BigNumber, end: BigNumber) {
    let networkName = network.name;
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    const reward = await ethers.getContractAt(`IncentivesController`, await incentives.getVault(asset));

    const data = encode(`updateStakeTime(uint256,uint256)`, [start, end]);
    console.log(reward.address);
    console.log(data);

    console.log("start: ", await reward.stakeStart());
    console.log("end: ", await reward.stakeEnd());
}

async function approveMax(assets: string[], rewardToken: string) {
    let networkName = network.name;
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    let funder = await ethers.getContractAt(`Funder`, process.env[`${networkName.toUpperCase()}_FUNDER`]!);

    let rewards = [];
    let rewardTokens = [];
    for (let i = 0; i < assets.length; i++) {
        rewards.push(await incentives.getVault(assets[i]));
        rewardTokens.push(rewardToken);
    }

    const data = encode("approveMaxBatch(address[] memory, address[] memory)", [rewards, rewardTokens]);
    console.log(funder.address);
    console.log(data);
}

async function retrieveFund(funder: string, assets: string[]) {
    let networkName = network.name;
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    
    for (let i = 0; i < assets.length; i++) {
        const reward = await ethers.getContractAt(`IncentivesController`, await incentives.getVault(assets[i]));
        const data = encode("retrieveFund(address)", [funder]);
        console.log(reward.address);
        console.log(data);
    }
}

async function setVaultImpl(assets: string[], impl: string) {
    let networkName = network.name;
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    console.log(incentives.address);

    for (let i = 0; i < assets.length; i++) {
        const data = encode("setVaultImpl(address, address)", [assets[i], impl]);
        console.log(data);
    }
}

export {
    setAdmin,
    updateFunder,
    updateLendingPool,
    updateLendingIndex,
    updateRps,
    updateStakeTime,
    approveMax,
    retrieveFund,
    setVaultImpl
}