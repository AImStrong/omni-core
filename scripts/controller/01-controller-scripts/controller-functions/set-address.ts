import { ethers, network } from 'hardhat';
import { execute } from '../../../utils/multisig';
import { encode } from '../../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function setAddress(id: string, newAddress: string) {
    let networkName = network.name;

    // ========= Contracts required =========
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const addressesProvider = await ethers.getContractAt(`contracts/controller-protocol/configuration/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    // ========= set address =========
    console.log(`========= set ${id} =========`);

    const data = encode(`set${id}(address)`, [newAddress]);
    await execute(multiSigWallet.address, addressesProvider.address, data);

    const updatedAddress = await (addressesProvider as any)[`get${id}`]();
    console.log(`${id} address: `, updatedAddress);
}

export { setAddress };
// await setAddress('UniversalMessenger', process.env[`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY`]!);