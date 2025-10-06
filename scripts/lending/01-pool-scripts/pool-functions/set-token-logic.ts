import { ethers, network } from 'hardhat';
import { execute } from '../../../utils/multisig';
import { encode } from '../../../utils/encode';
import { writeToEnvFile } from '../../../utils/helper';
import * as dotenv from 'dotenv';
dotenv.config();

interface UpdateTTokenInput {
    asset: string;
    treasury: string;
    incentivesController: string;
    name: string;
    symbol: string;
    implementation: string | null | undefined;
    params: string;
}

interface UpdateDebtTokenInput {
    asset: string;
    incentivesController: string;
    name: string;
    symbol: string;
    implementation: string | null | undefined;
    params: string;
}

async function updateTToken(updateTTokenInput: UpdateTTokenInput) {
    let networkName = network.name;
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const poolUpdateControl = await ethers.getContractAt("PoolUpdateControl", process.env[`${networkName.toUpperCase()}_POOL_UPDATE_CONTROL`]!);

    // ========= update tToken =========
    console.log(`========= update tToken =========`);

    if (!updateTTokenInput.implementation) {
        const TToken = await ethers.getContractFactory(`TToken`);
        const tToken = await TToken.deploy();
        await tToken.deployed();

        console.log(`${networkName.toUpperCase()}_T_TOKEN_LOGIC address: `, tToken.address);
        writeToEnvFile(`${networkName.toUpperCase()}_T_TOKEN_LOGIC`, tToken.address);

        updateTTokenInput.implementation = tToken.address;
    }

    const updateTTokenData = encode('updateTToken((address,address,address,string,string,address,bytes))', [
        [
            updateTTokenInput.asset,
            updateTTokenInput.treasury,
            updateTTokenInput.incentivesController,
            updateTTokenInput.name,
            updateTTokenInput.symbol,
            updateTTokenInput.implementation,
            updateTTokenInput.params
        ]
    ]);

    const submitTxData = encode("submitTransaction(bytes) external returns (uint256)", [updateTTokenData]);
    await execute(multiSigWallet.address, poolUpdateControl.address, submitTxData);

    var txId = (await poolUpdateControl.getTransactionCount()).sub(1);

    const [data, executed, numConfirmations] = await poolUpdateControl.getTransaction(txId);

    console.log("data before submit: ", updateTTokenData);
    console.log("data after submit:  ", data);

    const executeTxData = encode("executeTransaction(uint256)", [txId]);
    await execute(multiSigWallet.address, poolUpdateControl.address, executeTxData);

    const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    const reserveData = await pool.getReserveData(updateTTokenInput.asset);
    const token = await ethers.getContractAt("TToken", reserveData.tTokenAddress);

    console.log('treasury: ', await token.RESERVE_TREASURY_ADDRESS());
    console.log('incentives controller: ', await token.getIncentivesController());
    console.log('name: ', await token.name());
    console.log('symbol: ', await token.symbol());
    console.log('decimals: ', await token.decimals());
}

async function updateDebtToken(updateDebtTokenInput: UpdateDebtTokenInput) {
    let networkName = network.name;
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const poolUpdateControl = await ethers.getContractAt("PoolUpdateControl", process.env[`${networkName.toUpperCase()}_POOL_UPDATE_CONTROL`]!);

    // ========= update debtToken =========
    console.log(`========= update debtToken =========`);

    if (!updateDebtTokenInput.implementation) {
        const VariableDebtTokenLogic = await ethers.getContractFactory(`VariableDebtToken`);
        const variableDebtTokenLogic = await VariableDebtTokenLogic.deploy();
        await variableDebtTokenLogic.deployed();

        console.log(`${networkName.toUpperCase()}_VARIABLE_DEBT_TOKEN_LOGIC address: `, variableDebtTokenLogic.address);
        writeToEnvFile(`${networkName.toUpperCase()}_VARIABLE_DEBT_TOKEN_LOGIC`, variableDebtTokenLogic.address);

        updateDebtTokenInput.implementation = variableDebtTokenLogic.address;
    }

    const updateDebtTokenData = encode("updateVariableDebtToken((address,address,string,string,address,bytes))", [
        [
            updateDebtTokenInput.asset,
            updateDebtTokenInput.incentivesController,
            updateDebtTokenInput.name,
            updateDebtTokenInput.symbol,
            updateDebtTokenInput.implementation,
            updateDebtTokenInput.params
        ]
    ]);

    const submitTxData = encode("submitTransaction(bytes) external returns (uint256)", [updateDebtTokenData]);
    await execute(multiSigWallet.address, poolUpdateControl.address, submitTxData);

    var txId = (await poolUpdateControl.getTransactionCount()).sub(1);

    const [data, executed, numConfirmations] = await poolUpdateControl.getTransaction(txId);

    console.log("data before submit: ", updateDebtTokenData);
    console.log("data after submit:  ", data);

    const executeTxData = encode("executeTransaction(uint256)", [txId]);
    await execute(multiSigWallet.address, poolUpdateControl.address, executeTxData);

    const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    const reserveData = await pool.getReserveData(updateDebtTokenInput.asset);
    const token = await ethers.getContractAt("VariableDebtToken", reserveData.variableDebtTokenAddress);

    console.log('incentives controller: ', await token.getIncentivesController());
    console.log('name: ', await token.name());
    console.log('symbol: ', await token.symbol());
    console.log('decimals: ', await token.decimals());
}

export {
    UpdateTTokenInput,
    UpdateDebtTokenInput,
    updateTToken,
    updateDebtToken
}