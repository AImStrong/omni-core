import { addReserves } from './controller-functions/add-reserves';
import { encode } from '../../utils/encode';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    reserves: ['cbBTC'],
    chainId: 42161,
    connectedNetworkName: 'base_mainnet',
    // asset: "0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d"
}

async function main() {
    // await addReserves(config.connectedNetworkName, config.chainId, config.reserves);

    const networkName = network.name;

    const controller = await ethers.getContractAt("CrossChainLendingController", process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);
    console.log('reserves list: ', await controller.getReservesList(config.chainId));

    // const data = encode("dropReserveFromList(uint256,address)", [config.chainId, config.asset]);
    // console.log(data);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/add-reserves.ts --network zeta_testnet
// npx hardhat run scripts/controller/01-controller-scripts/add-reserves.ts --network zeta_mainnet