import { configureReserveAsCollateral, addChainToController, setReserveDecimals } from './controller-functions/config-reserve';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    chainId: 97,
    asset: '0xF59b95AE9Ae4da20A36f48151D5574499DE73f88',
    ltv: 2000,
    liquidationThreshold: 2000, 
    liquidationBonus: 10500,
    decimals: 18
}

async function main() {
    // await configureReserveAsCollateral(config.chainId, config.asset, config.ltv, config.liquidationThreshold, config.liquidationBonus);
    // await setReserveDecimals(config.chainId, config.asset, config.decimals);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/config-reserve.ts --network zeta_testnet