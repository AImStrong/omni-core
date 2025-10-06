import { ethers, network } from 'hardhat';
import { encode } from '../../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function setConnectedMessengersForChains(chainIds: number[], messengerAddrs: string[]) {
    let networkName = network.name;

    // ========= Contracts required =========
    const addressesProvider = await ethers.getContractAt(`contracts/controller-protocol/configuration/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    // ========= setConnectedMessengersForChains =========
    console.log(`========= setConnectedMessengersForChains =========`);

    const data = encode(`setConnectedMessengersForChains(uint256[], address[])`, [chainIds, messengerAddrs]);
    console.log(data);

    console.log(`getSupportedChainIds: `, await addressesProvider.getSupportedChainIds());

    for (let i = 0; i < chainIds.length; i++) {
        console.log(`getConnectedMessengerForChain ${chainIds[i]}: `, await addressesProvider.getConnectedMessengerForChain(chainIds[i]));
    }
}

export { setConnectedMessengersForChains };