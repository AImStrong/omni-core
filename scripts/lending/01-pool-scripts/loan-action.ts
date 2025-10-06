import { deposit, withdraw, borrow, repay } from './pool-functions/loan/index';
import { ethers, network } from 'hardhat';
import { getSigner } from '../../utils/signer';
import { BigNumber } from 'ethers';
import * as dotenv from 'dotenv';
dotenv.config();

const config = {
    user: '0x86A36A5baAa5C60036e758CAa1a4dAd32E6a5af4',
    // asset: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
    asset: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE', // for native
}

const UINT256_MAX = BigNumber.from("0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff");

async function main() {

    let networkName = network.name;

    // ========= get signer =========
    const signer = await getSigner(config.user);
    if (!signer) return;

    const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
    
    // ========= loan actions =========
    // await deposit(pool.address, config.asset, signer, ethers.utils.parseUnits('1', 6));
    // await withdraw(pool.address, config.asset, signer, UINT256_MAX, ethers.utils.parseEther('0.00002'));
    await borrow(pool.address, config.asset, signer, ethers.utils.parseUnits('0.000017', 18), ethers.utils.parseEther('0.000000002'));
    // await repay(pool.address, config.asset, signer, ethers.utils.parseUnits('0.4', 18));
    // await repay(pool.address, config.asset, signer, UINT256_MAX);

    // ========= set collateral =========
    // const setCollateral = await pool.setUserUseReserveAsCollateral(process.env.RALSEI_TOKEN!, true);
    // await setCollateral.wait();
    // console.log("set collateral hash: ", setCollateral.hash);

    // ========= approve =========
    // const bep20 = await ethers.getContractAt("BEP20", config.asset);
    // const approveTx = await bep20.connect(signer).approve(pool.address, UINT256_MAX);
    // await approveTx.wait();
    // console.log('approve tx hash: ', approveTx.hash);
    // console.log('allowance: ', await bep20.allowance(config.user, pool.address));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

// npx hardhat run scripts/lending/01-pool-scripts/loan-action.ts --network bsc_testnet
// npx hardhat run scripts/lending/01-pool-scripts/loan-action.ts --network base_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/loan-action.ts --network arbitrum_one_mainnet
// npx hardhat run scripts/lending/01-pool-scripts/loan-action.ts --network bsc_mainnet
