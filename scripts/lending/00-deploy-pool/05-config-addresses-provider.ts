import { ethers, network } from 'hardhat';
import { execute } from '../../utils/multisig';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function deploy(id: string, newAddress: string) {
    let networkName = network.name;
    const addressesProvider = await ethers.getContractAt(`contracts/lending-protocol/factory/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    // ========= set address =========
    console.log(`========= set ${id} =========`);

    const data = encode(`set${id}(address)`, [newAddress]);
    // await execute(multiSigWallet.address, addressesProvider.address, data);
    console.log(data);

    const updatedAddress = await (addressesProvider as any)[`get${id}`]();
    console.log(`${id} address: `, updatedAddress);
}

async function main() {
    let networkName = network.name;

    await deploy('ConnectedMessenger', process.env[`${networkName.toUpperCase()}_CONNECTED_MESSENGER_PROXY`]!);
    await deploy('UniversalMessenger', process.env.ZETA_MAINNET_UNIVERSAL_MESSENGER_PROXY!);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/00-deploy-pool/05-config-addresses-provider.ts --network bsc_testnet
// npx hardhat run scripts/lending/00-deploy-pool/05-config-addresses-provider.ts --network base_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/05-config-addresses-provider.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/05-config-addresses-provider.ts --network bsc_mainnet