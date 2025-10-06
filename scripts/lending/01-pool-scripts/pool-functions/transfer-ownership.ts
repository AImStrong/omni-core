import { ethers, network } from 'hardhat';
import { execute } from '../../../utils/multisig';
import { encode } from '../../../utils/encode';
import { writeToEnvFile } from '../../../utils/helper';
import * as dotenv from 'dotenv';
dotenv.config();

async function transferOwnership(newOwner: string, currentOwner: string) {
    let networkName = network.name;

    // ========= Replace owner in governance =========
    console.log('========= Replace owner in governance =========');

    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);

    console.log('current all owners: ', await multiSigWallet.getOwners());

    const replaceOwnerData = encode('replaceOwner(address, address)', [currentOwner, newOwner]);
    await execute(multiSigWallet.address, multiSigWallet.address, replaceOwnerData);

    console.log('new all owners: ', await multiSigWallet.getOwners());

    console.log('\n');
}

async function transferGovernance(newGovernance: string) {

    const networkName = network.name;

    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const addressesProvider = await ethers.getContractAt(`contracts/lending-protocol/factory/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);
    const factory = await ethers.getContractAt("contracts/lending-protocol/factory/FactoryRegistry.sol:FactoryRegistry", "0xb0F9E5708A95D7D873e5F2442ddeDc67636FcF04");

    // let data = encode("setAddress(bytes32,address)", [ethers.utils.formatBytes32String("POOL_OWNER"), newGovernance]);
    // await execute(multiSigWallet.address, addressesProvider.address, data);
    // console.log("pool owner: ", await addressesProvider.getPoolOwner());
    // console.log(data);

    // data = encode("setGovernance(address)", [newGovernance]);
    // await execute(multiSigWallet.address, addressesProvider.address, data);
    // console.log("governance: ", await addressesProvider.getGovernance());
    // console.log(data);

    let data = encode("transferGovernance(address)", [newGovernance]);
    await execute(multiSigWallet.address, factory.address, data);
    console.log(await factory.getGovernance());
}

export {
    transferOwnership,
    transferGovernance
}