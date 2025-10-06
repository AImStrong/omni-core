import { ethers, network } from 'hardhat';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function main() {
    const networkName = network.name;
    const oracleAddress = process.env[`${networkName.toUpperCase()}_PRICE_ORACLE`];
    
    if (!oracleAddress) {
        throw new Error(`Oracle address not found for network ${networkName}`);
    }

    const oracle = await ethers.getContractAt("TravaOracle", oracleAddress);
    
    // Example price feed configuration - replace with actual addresses and feed IDs
    const priceFeeds = [
        {
            token: "0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf",
            feedId: "0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43"
        },
        {
            token: "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f",
            feedId: "0xe62df6c8b4a85fe1a67db44dc12de5db330f7ac66b72dc658afedf0f4a415b43"
        },
    ];

    // Set price feeds one by one
    // for (const feed of priceFeeds) {
    //     if (!feed.token || !feed.feedId) {
    //         console.log(`Skipping feed - missing token address or feed ID`);
    //         continue;
    //     }

    //     console.log(`Setting price feed for token ${feed.token}...`);
    //     const tx = await oracle.setPriceFeed(feed.token, feed.feedId);
    //     await tx.wait();
    //     console.log(`Price feed set for token ${feed.token}`);
    // }

    // Alternatively, you can set multiple price feeds at once
    const tokens = priceFeeds.map(feed => feed.token).filter(Boolean);
    const feedIds = priceFeeds.map(feed => feed.feedId).filter(Boolean);

    if (tokens.length > 0 && feedIds.length > 0) {
        console.log(`Setting multiple price feeds...`);
        const data = encode("setMultiplePriceFeeds(address[],bytes32[])", [tokens as string[], feedIds as string[]]);
        console.log(data);
        console.log(`Multiple price feeds set successfully`);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 

// npx hardhat run scripts/controller/03-oracle-scripts/01-set-price-feed-addresses.ts --network zeta_testnet
// npx hardhat run scripts/controller/03-oracle-scripts/01-set-price-feed-addresses.ts --network zeta_mainnet