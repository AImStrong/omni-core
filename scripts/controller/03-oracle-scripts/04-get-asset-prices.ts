import { ethers, network } from 'hardhat';
import { BigNumber } from 'ethers';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
    const networkName = network.name;
    const oracleAddress = process.env[`${networkName.toUpperCase()}_PRICE_ORACLE`];
    
    if (!oracleAddress) {
        throw new Error(`Oracle address not found for network ${networkName}`);
    }

    const oracle = await ethers.getContractAt("TravaOracle", oracleAddress);
    
    // Get single asset price
    // const assetAddress = "0x4200000000000000000000000000000000000006"; // arb aave eth
    // if (assetAddress) {
    //     try {
    //         const price = await oracle.getAssetPrice(assetAddress);
    //         console.log(`Price: ${price.toString()} USD`);
    //     } catch (error) {
    //         console.error(`Failed to get price:`, error);
    //     }
    // }

    // Get multiple asset prices
    const assetAddresses = [
        "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
        "0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2",
        "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
        "0x4200000000000000000000000000000000000006",
        "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
        "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9",
        '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c',
        '0x55d398326f99059ff775485246999027b3197955',
        '0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d',
        '0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf',
        '0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f'
    ].filter(Boolean) as string[];

    if (assetAddresses.length > 0) {
        try {
            const prices = await oracle.getAssetPrices(assetAddresses);
            console.log('\nMultiple Asset Prices:');
            assetAddresses.forEach((address, index) => {
                console.log(`Asset ${index + 1} (${address}): ${prices[index].toString()} USD`);
            });
        } catch (error) {
            console.error(`Failed to get multiple asset prices:`, error);
        }
    }

    // Get feed IDs
    // if (assetAddresses.length > 0) {
    //     try {
    //         const feedIds = await oracle.getFeedIds(assetAddresses);
    //         console.log('\nPrice Feed IDs:');
    //         assetAddresses.forEach((address, index) => {
    //             console.log(`Asset ${index + 1} (${address}): ${feedIds[index]}`);
    //         });
    //     } catch (error) {
    //         console.error(`Failed to get feed IDs:`, error);
    //     }
    // }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 

// npx hardhat run scripts/controller/03-oracle-scripts/04-get-asset-prices.ts --network zeta_testnet
// npx hardhat run scripts/controller/03-oracle-scripts/04-get-asset-prices.ts --network zeta_mainnet