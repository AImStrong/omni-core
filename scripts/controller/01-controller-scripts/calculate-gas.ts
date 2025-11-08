import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
import { BigNumber } from 'ethers';
dotenv.config();

const config = {
    chainId: 42161,
    user: "0x135e94c43984B9d4D27B5D663F69a9d31d96f381"
}

async function main() {
    const universal = await ethers.getContractAt("UniversalMessenger", process.env[`${network.name.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY`]!);
    const system = await ethers.getContractAt("ISystem", process.env[`${network.name.toUpperCase()}_SYSTEM_CONTRACT`]!);
    const zrc20 = await ethers.getContractAt("IZRC20", await system.gasCoinZRC20ByChainId(config.chainId));

    const userGasBalance = await universal.getUserGasBalance(config.user, zrc20.address);

    let [, gasFee] = await zrc20.withdrawGasFeeWithGasLimit(await universal.gasLimit());
    gasFee = gasFee.mul(110).div(100);

    gasFee = (gasFee.gt(userGasBalance)) ? gasFee.sub(userGasBalance) : BigNumber.from(0);
    
    console.log('zrc20 balance: ', (await zrc20.balanceOf(config.user)).toString());
    console.log('current gas:   ', userGasBalance.toString());
    console.log('gas needed:    ', gasFee.toString());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/calculate-gas.ts --network zeta_mainnet