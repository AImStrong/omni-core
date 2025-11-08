import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
    const networkName = network.name;
    const controller = await ethers.getContractAt("CrossChainLendingController", process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);
    const universal = await ethers.getContractAt("UniversalMessenger", process.env[`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY`]!);

    const sys = await ethers.getContractAt("ISystem", await universal.systemContract());
    const zrcBase = await sys.gasCoinZRC20ByChainId(8453);
    const zrcArb = await sys.gasCoinZRC20ByChainId(42161);

    console.log(await universal.getUserGasBalance("0x135e94c43984b9d4d27b5d663f69a9d31d96f381", zrcBase));
    console.log(await universal.getUserGasBalance("0x135e94c43984b9d4d27b5d663f69a9d31d96f381", zrcArb));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/test.ts --network zeta_testnet
// npx hardhat run scripts/controller/01-controller-scripts/test.ts --network zeta_mainnet