import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import { execute } from '../../utils/multisig';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function deploy() {
    let networkName = network.name;
    const WETHAddress = "0xbb4cdb9cbd36b01bd1cbaebf2de08d9173bc095c";

    // ========= deploy weth gateway =========
    // console.log('========= deploy weth gateway =========');

    // ========= WETHGateway =========
    // const Gateway = await ethers.getContractFactory(`WETHGateway`);
    // const gateway = await Gateway.deploy(WETHAddress);
    // await gateway.deployed();
    
    // console.log(`${networkName.toUpperCase()}_WETH_GATEWAY address: `, gateway.address);
    // writeToEnvFile(`${networkName.toUpperCase()}_WETH_GATEWAY`, gateway.address);

    // console.log('\n');

    // ========= setWeth =========
    console.log('========= set WETH =========');
  
    const addressesProvider = await ethers.getContractAt(`contracts/lending-protocol/factory/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    const data = encode(`setWeth(address)`, [WETHAddress]);
    // await execute(multiSigWallet.address, addressesProvider.address, data);
    console.log(data);

    const updatedAddress = await addressesProvider.getWeth();
    console.log(`weth address: `, updatedAddress);
}

async function main() {
    await deploy();
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/00-deploy-pool/07-deploy-weth-gateway.ts --network bsc_testnet
// npx hardhat run scripts/lending/00-deploy-pool/07-deploy-weth-gateway.ts --network base_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/07-deploy-weth-gateway.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/07-deploy-weth-gateway.ts --network bsc_mainnet