import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import * as dotenv from 'dotenv';
dotenv.config();

const path = "contracts/controller-protocol/libraries/logic/";

async function deploy() {
    let networkName = network.name;

    // ========= Deploy logic =========
    console.log("========= Deploy logic =========");

    // ========= GenericLogic =========
    const GenericLogic = await ethers.getContractFactory(path + "GenericLogic.sol:GenericLogic");
    const genericLogic = await GenericLogic.deploy();
    await genericLogic.deployed();

    console.log(`${networkName.toUpperCase()}_GENERIC_LOGIC address: `, genericLogic.address);
    writeToEnvFile(`${networkName.toUpperCase()}_GENERIC_LOGIC`, genericLogic.address);

    // ========= ValidationLogic =========
    const ValidationLogic = await ethers.getContractFactory(path + `ValidationLogic.sol:ValidationLogic`, {
        libraries: {
            GenericLogic: process.env[`${networkName.toUpperCase()}_GENERIC_LOGIC`]!
        }
    });
    const validationLogic = await ValidationLogic.deploy();
    await validationLogic.deployed();

    console.log(`${networkName.toUpperCase()}_VALIDATION_LOGIC address: `, validationLogic.address);
    writeToEnvFile(`${networkName.toUpperCase()}_VALIDATION_LOGIC`, validationLogic.address);

    // ========= LiquidationLogic =========
    const LiquidationLogic = await ethers.getContractFactory(path + `LiquidationLogic.sol:LiquidationLogic`, {
        libraries: {
            ValidationLogic: validationLogic.address
        }
    });
    const liquidationLogic = await LiquidationLogic.deploy();
    await liquidationLogic.deployed();

    console.log(`${networkName.toUpperCase()}_LIQUIDATION_LOGIC address: `, liquidationLogic.address);
    writeToEnvFile(`${networkName.toUpperCase()}_LIQUIDATION_LOGIC`, liquidationLogic.address);
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

// npx hardhat run scripts/controller/00-deploy-controller/02-deploy-logic.ts --network zeta_testnet
// npx hardhat run scripts/controller/00-deploy-controller/02-deploy-logic.ts --network zeta_mainnet