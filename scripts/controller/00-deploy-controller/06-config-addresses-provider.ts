import { ethers, network } from 'hardhat';
import { execute } from '../../utils/multisig';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function setAddress(id: string, newAddress: string) {
    let networkName = network.name;
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const addressesProviderProxy = await ethers.getContractAt(`contracts/controller-protocol/configuration/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    // ========= set address =========
    console.log(`========= set ${id} =========`);

    const data = encode(`set${id}(address)`, [newAddress]);
    await execute(multiSigWallet.address, addressesProviderProxy.address, data);

    const updatedAddress = await (addressesProviderProxy as any)[`get${id}`]();
    console.log(`${id} address: `, updatedAddress);
}

async function main() {
    let networkName = network.name;

    await setAddress('UniversalMessenger', process.env[`${networkName.toUpperCase()}_UNIVERSAL_MESSENGER_PROXY`]!);
    // await setAddress('PriceOracle', process.env[`${networkName.toUpperCase()}_PRICE_ORACLE`]!);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/controller/00-deploy-controller/06-config-addresses-provider.ts --network zeta_testnet