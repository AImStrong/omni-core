import { 
    setAdmin,
    updateFunder,
    updateLendingPool,
    updateLendingIndex,
    updateRps,
    updateStakeTime,
    approveMax,
    retrieveFund,
    setVaultImpl
} from './pool-functions/reward';
import { ethers, network } from 'hardhat';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    // user: "0x3655ad27b6b942511e2625872eedb6d79bd3ed4c",
    asset: "0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2",
    // admin: "0x239b8ecc620B0DFa2340B7fb10D4feE793EF983c",
    funder: "0xF9Cf67D73a9f05f9Ed08D7602D90D7B2e2F70a0D",
    rewardToken: "0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2"
}

const assets = [
    '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c',
    '0x55d398326f99059fF775485246999027B3197955',
    '0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d'
]

async function main() {

    // await setAdmin(config.asset, config.admin, true);
    // await updateRps(config.asset, ethers.utils.parseUnits("31709791983764586504", 0));
    // await updateStakeTime(config.asset, ethers.utils.parseUnits("1756368000", 0), ethers.utils.parseUnits("1759071600000", 0));
    // await setVaultImpl(assets, process.env[`${network.name.toUpperCase()}_INCENTIVES_CONTROLLER_LOGIC`]!);
    // await retrieveFund(config.funder, assets);
    // await approveMax(assets, config.rewardToken);
    // await updateFunder(assets);

    const networkName = network.name;
    const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    const reward = await ethers.getContractAt(`IncentivesController`, await incentives.getVault(config.asset));
    const rewardToken = await ethers.getContractAt(`BEP20`, config.rewardToken);

    const funder = await reward.funder();
    console.log(funder);
    console.log(await rewardToken.balanceOf(funder), await rewardToken.allowance(funder, reward.address));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/01-pool-scripts/reward.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/reward.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/reward.ts --network base_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/reward.ts --network bsc_mainnet