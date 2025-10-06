import { ethers, network } from "hardhat";
import * as dotenv from 'dotenv';
import { BigNumber } from "ethers";
dotenv.config();

const config = {
    chainId: 8453,
    user: "0x86A36A5baAa5C60036e758CAa1a4dAd32E6a5af4"
}

async function main() {
    const networkName = network.name;

    const universal = await ethers.getContractAt("UniversalMessenger", process.env[`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY`]!);
    const system = await ethers.getContractAt("ISystem", await universal.systemContract());
    const zrcAddress = await system.gasCoinZRC20ByChainId(config.chainId);
    const zrc20 = await ethers.getContractAt("IZRC20", zrcAddress);
    
    const balance = await zrc20.balanceOf(config.user);
    console.log("balance: ", balance);

    // const approveTx = await zrc20.approve(zrcAddress, 1e13);
    // await approveTx.wait();
    // console.log("approve hash: ", approveTx.hash);
    // console.log("allowance for zrcAddress: ", await zrc20.allowance(config.user, zrcAddress));

    // const withdrawTx = await zrc20.withdraw(config.user, balance.sub(1e13));
    // await withdrawTx.wait();
    // console.log("withdraw hash: ", withdrawTx.hash);
}
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 

// npx hardhat run scripts/controller/02-user-scripts/withdrawZRC20.ts --network zeta_testnet
// npx hardhat run scripts/controller/02-user-scripts/withdrawZRC20.ts --network zeta_mainnet
