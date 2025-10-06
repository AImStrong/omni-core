import { ethers, network } from 'hardhat';
import { BigNumber } from 'ethers';
import * as dotenv from 'dotenv';
dotenv.config();

function decodeReserveConfiguration(data: BigNumber) {
 
    return {
        ltv:                    data.and("0xFFFF").toNumber(),             // bits 0-15
        liquidationThreshold:   data.shr(16).and("0xFFFF").toNumber(),     // bits 16-31
        liquidationBonus:       data.shr(32).and("0xFFFF").toNumber(),     // bits 32-47
        decimals:               data.shr(48).and("0xFF").toNumber(),       // bits 48-55
        isActive:               data.shr(56).and("0x1").eq(1),             // bit 56
        isFrozen:               data.shr(57).and("0x1").eq(1),             // bit 57
        borrowingEnabled:       data.shr(58).and("0x1").eq(1),             // bit 58
        stableBorrowingEnabled: data.shr(59).and("0x1").eq(1),             // bit 59
        reserveFactor:          data.shr(64).and("0xFFFF").toNumber(),     // bits 64-79
    };
 }

async function getControllerInfo() {
    let networkName = network.name;

    // ========= Contracts required ========= 
    const controller = await ethers.getContractAt(`CrossChainLendingController`, process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);
    const addressesProvider = await ethers.getContractAt("contracts/controller-protocol/configuration/AddressesProvider.sol:AddressesProvider", process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);
    const universalMessenger = await addressesProvider.getUniversalMessenger();
    console.log("Universal Messenger:", universalMessenger);
    // Get Supported Chain IDs
    const supportedChainIds = await addressesProvider.getSupportedChainIds();

    console.log("\nSupported Chain IDs:", supportedChainIds);

    // Get information for each supported chain
    for (const chainId of supportedChainIds) {
        console.log("\n========== Chain", chainId.toString(), "==========");
        
        // Get Pool Info
        const [reservesCount, paused, maxNumberOfReserves] = await controller.getPoolInfo(chainId);
        console.log("\nPool Information:");
        console.log("- Reserves Count:", reservesCount.toString());
        console.log("- Paused:", paused);
        console.log("- Max Number of Reserves:", maxNumberOfReserves.toString());

        // Get Connected Messenger
        const messenger = await addressesProvider.getConnectedMessengerForChain(chainId);
        console.log("- Connected Messenger:", messenger);
        
        // Get list of reserves
        const reservesList = await controller.getReservesList(chainId);
        console.log("\nReserves List:", reservesList);
        
        // Get detailed data for each reserve
        console.log("\nDetailed Reserve Data:");
        for (const asset of reservesList) {

            const reserveData = await controller.getReserveData(chainId, asset);

            console.log("\nAsset:",                             asset);
            console.log("- ID:",                                reserveData.id);
            console.log("- Liquidity Index:",                   reserveData.liquidityIndex.toString());
            console.log("- Variable Borrow Index:",             reserveData.variableBorrowIndex.toString());
            console.log("- Current Liquidity Rate:",            reserveData.currentLiquidityRate.toString());
            console.log("- Current Variable Borrow Rate:",      reserveData.currentVariableBorrowRate.toString());
            console.log("- Balance Of Underlying Asset:",       reserveData.balanceOfUnderlyingAsset.toString());
            console.log("- ConnectedChainLastUpdateTimeStamp:", reserveData.lastUpdateTimestampConnectedChain.toString());
            console.log("- ZetaChainLastUpdateTimeStamp:",      reserveData.lastUpdateTimestamp.toString());

            // Get configuration data
            const config = await controller.getConfiguration(chainId, asset);
            console.log("- Configuration Data:", config.data.toString());
            console.log(decodeReserveConfiguration(config.data));
        }
    }
}

export {
    decodeReserveConfiguration,
    getControllerInfo
}