import { ethers, network } from 'hardhat';
import { execute } from '../../../utils/multisig';
import { encode } from '../../../utils/encode';
import { writeToEnvFile } from '../../../utils/helper';
import * as dotenv from 'dotenv';
dotenv.config();

async function transferOwnership(newOwner: string, currentOwner: string) {
    let networkName = network.name;

    // ========= Replace owner in governance =========
    // console.log('========= Replace owner in governance =========');

    // const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);

    // console.log('current all owners: ', await multiSigWallet.getOwners());

    // const replaceOwnerData = encode('replaceOwner(address, address)', [currentOwner, newOwner]);
    // await execute(multiSigWallet.address, multiSigWallet.address, replaceOwnerData);

    // console.log('new all owners: ', await multiSigWallet.getOwners());

    // console.log('\n');

    // ========= Transfer ownership in Oracle =========
    // console.log('========= Transfer ownership in Oracle =========');

    // const oracle = await ethers.getContractAt('TravaOracle', process.env[`${networkName.toUpperCase()}_PRICE_ORACLE`]!);
    // console.log('current oracle owner: ', await oracle.owner());
    // const oracleTx = await oracle.transferOwnership(newOwner);
    // await oracleTx.wait();
    // console.log('transfer oracle ownership tx hash: ', oracleTx.hash);
    // console.log('new oracle owner: ', await oracle.owner());

    // console.log('\n');

    // ========= Transfer ownership in addresses provider =========
    console.log('========= Transfer ownership in addresses provider =========');
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const addressesProvider = await ethers.getContractAt(`contracts/controller-protocol/configuration/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    let data = encode("setControllerOwner(address)", [newOwner]);
    await execute(multiSigWallet.address, addressesProvider.address, data);

    data = encode("setControllerUpdateManager(address)", [newOwner]);
    await execute(multiSigWallet.address, addressesProvider.address, data);

    data = encode("setGovernance(address)", [newOwner]);
    await execute(multiSigWallet.address, addressesProvider.address, data);

    console.log("controller owner: ", await addressesProvider.getControllerOwner());
    console.log("controller update manager: ", await addressesProvider.getControllerUpdateManager());
    console.log("governance: ", await addressesProvider.getGovernance());
}

export {
    transferOwnership
}