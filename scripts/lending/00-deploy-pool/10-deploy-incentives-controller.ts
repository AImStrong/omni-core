import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    asset: "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf",
    funder: "0x7eD73a49D29cD66B93b1772E818607a7dC69eD98",
    lendingIndex: ethers.utils.parseUnits("1", 27),
    tokenRewards: "0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2",
    tokenStaked: "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf",
    rps: 0,
    start: 1756368000,
    end: 1759071600000,
}

async function deploy() {
    let networkName = network.name;
    // const incentives = await ethers.getContractAt(`IncentivesFactory`, process.env[`${networkName.toUpperCase()}_INCENTIVES_FACTORY`]!);

    const RewardImpl = await ethers.getContractFactory(`IncentivesController`);
    const rewardImpl = await RewardImpl.deploy("0x81ff99181d4Bdd14f64dC1a0e1A98EF81688bA0a");
    await rewardImpl.deployed();
    console.log(`${networkName.toUpperCase()}_INCENTIVES_CONTROLLER_LOGIC address: `, rewardImpl.address);
    writeToEnvFile(`${networkName.toUpperCase()}_INCENTIVES_CONTROLLER_LOGIC`, rewardImpl.address);

    // let data = encode("setVaultImpl(address,address)", [config.asset, process.env[`${networkName.toUpperCase()}_INCENTIVES_CONTROLLER_LOGIC`]!]);
    // console.log(data);

    // const rewardAddress = await incentives.getVault(config.asset)
    // console.log("getVault: ", rewardAddress);

    // const reward = await ethers.getContractAt(`IncentivesController`, rewardAddress);

    // const lendingPoolAddress = process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!;

    // let datae = encode("setData(address,address,uint256,address,address,uint256,uint256,uint256)", [
    //     config.funder,
    //     lendingPoolAddress,
    //     config.lendingIndex,
    //     config.tokenRewards,
    //     config.tokenStaked,
    //     config.rps,
    //     config.start,
    //     config.end
    // ]);
    // console.log(datae);

    // console.log("funder: ", await reward.funder());
    // console.log("lendingPool: ", await reward.lendingPool());
    // console.log("lendingIndex: ", await reward.lendingIndexAtTimeStart());
    // console.log("tokenRewards: ", await reward.tokenRewards());
    // console.log("tokenStaked: ", await reward.tokenStaked());
    // console.log("rps: ", await reward.rps());
    // console.log("start: ", await reward.stakeStart());
    // console.log("end: ", await reward.stakeEnd());
}

async function main() {
    await deploy();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/00-deploy-pool/10-deploy-incentives-controller.ts --network bsc_testnet
// npx hardhat run scripts/lending/00-deploy-pool/10-deploy-incentives-controller.ts --network base_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/10-deploy-incentives-controller.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/10-deploy-incentives-controller.ts --network bsc_mainnet