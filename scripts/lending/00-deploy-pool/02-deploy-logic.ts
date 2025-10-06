import { ethers, network } from 'hardhat';
import { writeToEnvFile } from '../../utils/helper';
import * as dotenv from 'dotenv';
dotenv.config();

const path = `contracts/lending-protocol/libraries/logic/`

async function deploy() {
    let networkName = network.name;

    // ========= Deploy logic =========
    console.log(`========= Deploy logic =========`);

    // ========= ReserveLogic =========
    const ReserveLogic = await ethers.getContractFactory(path + `ReserveLogic.sol:ReserveLogic`);
    const reserveLogic = await ReserveLogic.deploy();
    await reserveLogic.deployed();

    console.log(`${networkName.toUpperCase()}_RESERVE_LOGIC address: `, reserveLogic.address);
    writeToEnvFile(`${networkName.toUpperCase()}_RESERVE_LOGIC`, reserveLogic.address);

    // ========= SupplyLogic =========
    const SupplyLogic = await ethers.getContractFactory(path + `SupplyLogic.sol:SupplyLogic`);
    const supplyLogic = await SupplyLogic.deploy();
    await supplyLogic.deployed();

    console.log(`${networkName.toUpperCase()}_SUPPLY_LOGIC address: `, supplyLogic.address);
    writeToEnvFile(`${networkName.toUpperCase()}_SUPPLY_LOGIC`, supplyLogic.address);

    // ========= BorrowLogic =========
    const BorrowLogic = await ethers.getContractFactory(path + `BorrowLogic.sol:BorrowLogic`);
    const borrowLogic = await BorrowLogic.deploy();
    await borrowLogic.deployed();

    console.log(`${networkName.toUpperCase()}_BORROW_LOGIC address: `, borrowLogic.address);
    writeToEnvFile(`${networkName.toUpperCase()}_BORROW_LOGIC`, borrowLogic.address);

    // ========= LiquidationLogic =========
    const LiquidationLogic = await ethers.getContractFactory(path + `LiquidationLogic.sol:LiquidationLogic`);
    const liquidationLogic = await LiquidationLogic.deploy();
    await liquidationLogic.deployed();

    console.log(`${networkName.toUpperCase()}_LIQUIDATION_LOGIC address: `, liquidationLogic.address);
    writeToEnvFile(`${networkName.toUpperCase()}_LIQUIDATION_LOGIC`, liquidationLogic.address);

    // ========= PoolLogic =========
    const PoolLogic = await ethers.getContractFactory(path + `PoolLogic.sol:PoolLogic`, {
        libraries: {
            ReserveLogic: reserveLogic.address
        }
    });
    const poolLogic = await PoolLogic.deploy();
    await poolLogic.deployed();

    console.log(`${networkName.toUpperCase()}_POOL_LOGIC address: `, poolLogic.address);
    writeToEnvFile(`${networkName.toUpperCase()}_POOL_LOGIC`, poolLogic.address);
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

// npx hardhat run scripts/lending/00-deploy-pool/02-deploy-logic.ts --network bsc_testnet
// npx hardhat run scripts/lending/00-deploy-pool/02-deploy-logic.ts --network base_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/02-deploy-logic.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/00-deploy-pool/02-deploy-logic.ts --network bsc_mainnet