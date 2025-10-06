import { getUserAssetData } from './controller-functions/get-user-asset-data';
import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    user: '0x3655ad27b6b942511e2625872eedb6d79bd3ed4c',
    asset: '0x4200000000000000000000000000000000000006',
    chainId: 8453
}

async function main() {
    const data = await getUserAssetData(config.user, config.asset, config.chainId);

    // Print results
    console.log("\nUser Asset Data:");
    console.log("=================");
    console.log("User Address:",                    data.user);
    console.log("Asset Address:",                   data.asset);
    console.log("Chain ID:",                        data.chainId);
    console.log("\nAsset Specific Data:");
    console.log("- Income:",                        data.income);
    console.log("- Debt:",                          data.debt);
    console.log("- Scaled Income:",                 data.scaledIncome);
    console.log("- Scaled Debt:",                   data.scaledDebt);
    console.log("- Current Liquidity Index:",       data.currentLiquidityIndex);
    console.log("- Current Variable Borrow Index:", data.currentVariableBorrowIndex);
    console.log("- isBorrowing:",                   data.isBorrowing);
    console.log("- isUsingAsCollateral:",           data.isUsingAsCollateral);
    console.log("\nUser Account Data:");
    console.log("- Total Collateral USD:",          data.totalCollateralUSD);
    console.log("- Total Debt USD:",                data.totalDebtUSD);
    console.log("- Available Borrows USD:",         data.availableBorrowsUSD);
    console.log("- Current Liquidation Threshold:", data.currentLiquidationThreshold);
    console.log("- LTV:",                           data.ltv);
    console.log("- Health Factor:",                 data.healthFactor);
    console.log("- isBeingLiquidated:",             data.isBeingLiquidated);
    console.log("\nReserve Data:");
    console.log("- Liquidity Index:",               data.liquidityIndex);
    console.log("- Variable Borrow Index:",         data.variableBorrowIndex);
    console.log("- Current Liquidity Rate:",        data.currentLiquidityRate);
    console.log("- Current Variable Borrow Rate:",  data.currentVariableBorrowRate);
    console.log("- Current UnderlyingAsset:",       data.balanceOfUnderlyingAsset);
    console.log("- Current userConfig:",            data.userConfig);
    console.log("- Current apr:",                   data.apr);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/01-controller-scripts/get-user-asset-data.ts --network zeta_testnet
// npx hardhat run scripts/controller/01-controller-scripts/get-user-asset-data.ts --network zeta_mainnet
