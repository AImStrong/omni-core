import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import { execute } from '../../utils/multisig';
import { encode } from '../../utils/encode';
import * as dotenv from 'dotenv';
dotenv.config();

async function deploy() {
    let networkName = network.name;
    const multiSigWallet = await ethers.getContractAt(`MultiSigWallet`, process.env[`${networkName.toUpperCase()}_MULTISIG_WALLET`]!);
    const addressesProviderProxy = await ethers.getContractAt(`contracts/controller-protocol/configuration/AddressesProvider.sol:AddressesProvider`, process.env[`${networkName.toUpperCase()}_ADDRESSES_PROVIDER_PROXY`]!);

    // ========= Deploy controller logic =========
    console.log('========= Deploy controller logic =========');

    // ========= CrossChainLendingController logic =========
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
    console.log('\n');

    // ========= CrossChainLendingControllerConfigurator logic =========
    const ControllerConfiguratorLogic = await ethers.getContractFactory("CrossChainLendingControllerConfigurator");
    const controllerConfiguratorLogic = await ControllerConfiguratorLogic.deploy();
    await controllerConfiguratorLogic.deployed();

    console.log(`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_LOGIC address: `, controllerConfiguratorLogic.address);
    writeToEnvFile(`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_LOGIC`, controllerConfiguratorLogic.address);
    console.log('\n');

    // ========= Deploy controller proxy =========
    console.log('========= Deploy controller proxy =========');

    const initControllerData = encode('initController(address, address, address)', [
        controllerLogic.address,
        process.env[`${networkName.toUpperCase()}_PRICE_ORACLE`],
        controllerConfiguratorLogic.address
    ]);
    await execute(multiSigWallet.address, addressesProviderProxy.address, initControllerData);

    const controllerProxyAddress = await addressesProviderProxy.getCrossChainLendingController();
    console.log(`${networkName.toUpperCase()}_CONTROLLER_PROXY address: `, controllerProxyAddress);
    writeToEnvFile(`${networkName.toUpperCase()}_CONTROLLER_PROXY`, controllerProxyAddress);

    const controllerConfiguratorProxy = await addressesProviderProxy.getControllerConfigurator();
    console.log(`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_PROXY address: `, controllerConfiguratorProxy);
    writeToEnvFile(`${networkName.toUpperCase()}_CONTROLLER_CONFIGURATOR_PROXY`, controllerConfiguratorProxy);
    console.log('\n');

    // ========= setControllerOwner =========
    console.log('========= setControllerOwner =========');

    const setControllerOwnerData = encode('setControllerOwner(address)', [process.env.PUBLIC_KEY!]);
    await execute(multiSigWallet.address, addressesProviderProxy.address, setControllerOwnerData);

    console.log('addressesProvider.getControllerOwner: ', await addressesProviderProxy.getControllerOwner());
    console.log('\n');

    // ========= setControllerUpdateManager =========
    console.log('========= setControllerUpdateManager =========');

    const setControllerUpdateManagerData = encode('setControllerUpdateManager(address)', [process.env.PUBLIC_KEY!]);
    await execute(multiSigWallet.address, addressesProviderProxy.address, setControllerUpdateManagerData);

    console.log('addressesProvider.getControllerUpdateManager: ', await addressesProviderProxy.getControllerUpdateManager());
    console.log('\n');
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

// npx hardhat run scripts/controller/00-deploy-controller/04-deploy-controller.ts --network zeta_testnet