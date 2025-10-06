import { ethers, network } from 'hardhat';
import { encode } from '../../../utils/encode';
import { writeToEnvFile } from '../../../utils/helper';
import * as dotenv from 'dotenv';
dotenv.config();

async function updateControllerImpl(newAddress: string | null | undefined) {
    let networkName = network.name;

    // ========= Contracts required =========
    const addressesProvider = await ethers.getContractAt(`contracts/controller-protocol/configuration/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    // ========= Update Controller Implementation =========
    console.log('========= Updating CrossChainLendingController Implementation =========');

    if (!newAddress) {
        const ControllerLogic = await ethers.getContractFactory("CrossChainLendingController", {
            libraries: {
                LiquidationLogic: process.env[`${networkName.toUpperCase()}_LIQUIDATION_LOGIC`]!,
                ValidationLogic:  process.env[`${networkName.toUpperCase()}_VALIDATION_LOGIC`]!
            }
        });
        const controllerLogic = await ControllerLogic.deploy();
        await controllerLogic.deployed();
    
        console.log(`${networkName.toUpperCase()}_CONTROLLER_LOGIC address: `, controllerLogic.address);
        writeToEnvFile(`${networkName.toUpperCase()}_CONTROLLER_LOGIC`, controllerLogic.address);

        newAddress = controllerLogic.address;
    }

    const data = encode('setCrossChainLendingControllerImpl(address)', [newAddress]);
    console.log(data);

    console.log('Controller proxy address: ', await addressesProvider.getCrossChainLendingController());
    console.log('========= CrossChainLendingController Implementation Updated =========');
}

export {
    updateControllerImpl
} 