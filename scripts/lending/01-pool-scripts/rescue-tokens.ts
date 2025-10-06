import { rescueTokens } from './pool-functions/rescue-tokens';
import { ethers } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    token: process.env.RALSEI_TOKEN!, 
    to: process.env.PUBLIC_KEY!, 
    amount: ethers.utils.parseEther('0.01')
}

async function main() {
    await rescueTokens(config.token, config.to, config.amount);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/01-pool-scripts/rescue-tokens.ts --network bsc_testnet