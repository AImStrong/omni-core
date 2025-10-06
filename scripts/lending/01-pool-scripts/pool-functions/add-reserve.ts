import { ethers, network } from 'hardhat';
import { ReserveAssets } from '../../../config/reserveAssets';
import { reservesParamsConfig } from '../../../config/reserveParamsConfig';
import { encode } from '../../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function addReserves(assets: string[]) {
    let networkName = network.name;
    const interestRateFactory = await ethers.getContractAt("InterestRateFactory", process.env[`${networkName.toUpperCase()}_INTEREST_RATE_FACTORY_PROXY`]!);
    const poolConfigurator = await ethers.getContractAt('PoolConfigurator', process.env[`${networkName.toUpperCase()}_POOL_CONFIGURATOR_PROXY`]!);

    // ========= add reserves =========
    console.log(`========= add reserves =========`);

    // // ========= add interestRateStrategy =========
    // console.log('========= add interestRateStrategy =========');

    // var ISConfigChosenToken = [];

    // for (let i = 0; i < assets.length; i++) {
    //     const _ISConfigChosenToken = {
    //         utilizationOptimal: reservesParamsConfig[assets[i] as keyof typeof reservesParamsConfig].utilizationOptimal,
    //         BaseInterstRate:    reservesParamsConfig[assets[i] as keyof typeof reservesParamsConfig].BaseInterstRate,
    //         slope1:             reservesParamsConfig[assets[i] as keyof typeof reservesParamsConfig].slope1,
    //         slope2:             reservesParamsConfig[assets[i] as keyof typeof reservesParamsConfig].slope2
    //     }
    //     ISConfigChosenToken.push(_ISConfigChosenToken);
    // }

    // const dataInitInterestRateStrategy = encode(
    //     'initInterestRateStrategy(address, (uint256, uint256, uint256, uint256)[]) external returns (address[])',
    //     [
    //         process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!,
    //         ISConfigChosenToken.map(({ utilizationOptimal, BaseInterstRate, slope1, slope2 }) => [
    //             utilizationOptimal,
    //             BaseInterstRate,
    //             slope1,
    //             slope2
    //         ])
    //     ]
    // );

    // console.log(dataInitInterestRateStrategy);

    // ========= add reserves to pool =========
    console.log('========= add reserves to pool =========');

    let listInterestRateStrategies = await interestRateFactory.getListInterestRateAddress();
    console.log(listInterestRateStrategies.length);
    listInterestRateStrategies = listInterestRateStrategies.slice(listInterestRateStrategies.length - assets.length);

    console.log("listInterestRateStrategies: ", listInterestRateStrategies);

    var initReserveInput = [];

    for (let i = 0; i < assets.length; i++) {
        const network = networkName as keyof typeof ReserveAssets;
        const asset = assets[i] as keyof typeof ReserveAssets[typeof network];

        const token = await ethers.getContractAt("BEP20", (ReserveAssets[network][asset] as any).underlyingAddress);
        const name = await token.name();

        const _initReserveInput = {
            tTokenImpl:                  process.env[`${networkName.toUpperCase()}_T_TOKEN_LOGIC`]!,
            variableDebtTokenImpl:       process.env[`${networkName.toUpperCase()}_VARIABLE_DEBT_TOKEN_LOGIC`]!,
            underlyingAssetDecimals:     await token.decimals(),
            interestRateStrategyAddress: listInterestRateStrategies[i],
            underlyingAsset:             (ReserveAssets[network][asset] as any).underlyingAddress,
            treasury:                    process.env[`${networkName.toUpperCase()}_TREASURY`]!,
            incentivesController:        process.env[`${networkName.toUpperCase()}_INCENTIVES_CONTROLLER`]!,
            underlyingAssetName:         name,
            tTokenName:                  'AImstrong interest bearing ' + name,
            tTokenSymbol:                't' + name,
            variableDebtTokenName:       'AImstrong debt bearing ' + name,
            variableDebtTokenSymbol:     'debt' + name,
            params:                      "0x12",
            reserveFactor:               reservesParamsConfig[assets[i] as keyof typeof reservesParamsConfig].reserveFactor
        };
        initReserveInput.push(_initReserveInput);
    }

    const dataBatchInitReserve = encode(
        'batchInitReserve((address,address,uint8,address,address,address,address,string,string,string,string,string,bytes,uint256)[])',
        [
            initReserveInput.map(({ tTokenImpl, variableDebtTokenImpl, underlyingAssetDecimals, interestRateStrategyAddress, underlyingAsset, treasury, incentivesController, underlyingAssetName, tTokenName, tTokenSymbol, variableDebtTokenName, variableDebtTokenSymbol, params, reserveFactor }) => [
                tTokenImpl, variableDebtTokenImpl, underlyingAssetDecimals, interestRateStrategyAddress, underlyingAsset, treasury, incentivesController, underlyingAssetName, tTokenName, tTokenSymbol, variableDebtTokenName, variableDebtTokenSymbol, params, reserveFactor
            ])
        ]
    )

    console.log(dataBatchInitReserve);

    const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    const reservesList = await pool.getReservesList();

    console.log("Pool.getReservesList: ", reservesList);

    console.log('\n');
}

async function dropReserve(asset: string) {
    let networkName = network.name;

    // ========= dropReserve =========
    console.log("========= dropReserve =========");

    const configReserveData = encode("dropReserve(address)", [asset]);
    console.log(configReserveData);

    const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    
    console.log("reserves list: ", await pool.getReservesList());
}

export {
    addReserves,
    dropReserve
}