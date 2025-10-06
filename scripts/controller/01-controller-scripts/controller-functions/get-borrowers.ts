import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

async function getBorrowers(start: number, end: number) {
    const networkName = network.name;

    const controller = await ethers.getContractAt(`CrossChainLendingController`, process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);

    const latestBlock = await ethers.provider.getBlockNumber();
    const filter = controller.filters.ValidateBorrowProcessed();
    const logs = await controller.queryFilter(filter, start, end);
    const borrowers = logs.map(log => log.args.onBehalfOf);

    return ([...new Set(borrowers)]);
}

export {
    getBorrowers
}