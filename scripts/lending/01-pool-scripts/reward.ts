import { 
    setAdmin,
    updateFunder,
    updateLendingPool,
    updateLendingIndex,
    updateRps,
    updateStakeTime 
} from './pool-functions/reward';
import { ethers, network } from 'hardhat';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    user: "0x3655ad27b6b942511e2625872eedb6d79bd3ed4c",
    asset: "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf",
    admin: "0x239b8ecc620B0DFa2340B7fb10D4feE793EF983c",
    funder: "0xf6486bd1b09a88DA1A3a400d9c8D0cA89E4999Cd",
    rewardToken: "0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2"
}

async function main() {

    await setAdmin(config.asset, config.admin, true);
    // await updateRps(config.asset, ethers.utils.parseUnits("31709791983764586504", 0));
    // await updateStakeTime(config.asset, ethers.utils.parseUnits("1756368000", 0), ethers.utils.parseUnits("1759071600000", 0));
    // await updateFunder(config.asset, config.funder);

    // let networkName = network.name;
    // const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);
    // const reward = await ethers.getContractAt(`IncentivesController`, await incentives.getVault(config.asset));
    // const funder = await ethers.getContractAt(`Funder`, process.env[`${networkName.toUpperCase()}_FUNDER`]!);
    // const rewardToken = await ethers.getContractAt(`BEP20`, config.rewardToken);

    // console.log(await reward.ratePerSecond());
    // console.log(await reward.stakeStart());
    // console.log(await reward.stakeEnd());
    // const block = await ethers.provider.getBlock("latest");
    // console.log(block.timestamp);

    // console.log(await rewardToken.balanceOf(funder.address));
    

    // const tx = await reward.updateGlobalIndex();
    // await tx.wait();

    // console.log("hash: ", tx.hash);

    // console.log(await reward.globalIndex());

    // console.log("user reward: ", await reward.viewReward(config.user));
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