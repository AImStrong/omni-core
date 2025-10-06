import { ethers, network } from 'hardhat';
import { execute } from '../../../utils/multisig';
import { encode } from '../../../utils/encode';
import { BigNumber } from 'ethers';
import * as dotenv from 'dotenv';
dotenv.config();

async function rescueTokens(token: string, to: string, amount: BigNumber) {
    let networkName = network.name;
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);

    // ========= rescueTokens =========
    console.log("========= rescueTokens =========");

    const configReserveData = encode("rescueTokens(address,address,amount)", [token, to, amount]);
    await execute(multiSigWallet.address, process.env[`${networkName.toUpperCase()}_POOL_CONFIGURATOR_PROXY`]!, configReserveData);

    const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    const bep20 = await ethers.getContractAt('BEP20', token);
    console.log('balance of pool: ', await bep20.balanceOf(pool.address));
}

export {
    rescueTokens
}