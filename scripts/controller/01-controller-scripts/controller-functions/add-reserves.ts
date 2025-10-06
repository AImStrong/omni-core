import { ethers, network } from 'hardhat';
import { ReserveAssets } from '../../../config/reserveAssets';
import { reservesParamsConfig } from '../../../config/reserveParamsConfig';
import { encode } from '../../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function addReserves(connectedNetworkName: string, chainId: number, initialReserves: string[]) {
    let networkName = network.name;

    // ========= Contracts required =========
    const controllerConfigurator = await ethers.getContractAt('CrossChainLendingControllerConfigurator', process.env[`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_PROXY`]!);
    const controller = await ethers.getContractAt(`CrossChainLendingController`, process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);
    const addressesProvider = await ethers.getContractAt(`contracts/controller-protocol/configuration/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    // ========= add reserves to controller =========
    console.log('========= add reserves to controller =========');

    let initReserveInput = [];
    
    for (let i = 0; i < initialReserves.length; i++) {
        const network = networkName as keyof typeof ReserveAssets;
        const asset = initialReserves[i] as keyof typeof ReserveAssets[typeof network];

        let _initReserveInput = {
            chainId:                 chainId,
            underlyingAsset:         (ReserveAssets[connectedNetworkName as keyof typeof ReserveAssets][asset] as any).underlyingAddress, 
            underlyingAssetDecimals: (reservesParamsConfig[initialReserves[i] as keyof typeof reservesParamsConfig] as any).decimals,
            baseLTVAsCollateral:     reservesParamsConfig[initialReserves[i] as keyof typeof reservesParamsConfig].baseLTVAsCollateral, 
            liquidationThreshold:    reservesParamsConfig[initialReserves[i] as keyof typeof reservesParamsConfig].liquidationThreshold, 
            liquidationBonus:        reservesParamsConfig[initialReserves[i] as keyof typeof reservesParamsConfig].liquidationBonus
        };
        initReserveInput.push(_initReserveInput);
    }

    const data = encode("batchInitReserve((uint256,address,uint8,uint256,uint256,uint256)[])", [
        initReserveInput.map(({chainId, underlyingAsset, underlyingAssetDecimals, baseLTVAsCollateral, liquidationThreshold, liquidationBonus}) => [
            chainId, underlyingAsset, underlyingAssetDecimals, baseLTVAsCollateral, liquidationThreshold, liquidationBonus
        ])
    ]);

    console.log(data);

    console.log('========= add reserves success =========');

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
        console.log("\nAsset:", asset);
        console.log("- ID:", reserveData.id.toString());
        console.log("- Liquidity Index:", reserveData.liquidityIndex.toString());
        console.log("- Variable Borrow Index:", reserveData.variableBorrowIndex.toString());
        console.log("- Current Liquidity Rate:", reserveData.currentLiquidityRate.toString());
        console.log("- Current Variable Borrow Rate:", reserveData.currentVariableBorrowRate.toString());
        console.log("- Balance Of Underlying Asset:", reserveData.balanceOfUnderlyingAsset.toString());
        
        // Get configuration data
        const config = await controller.getConfiguration(chainId, asset);
        console.log("- Configuration Data:", config.data.toString());
    }
}

export {
    addReserves
}