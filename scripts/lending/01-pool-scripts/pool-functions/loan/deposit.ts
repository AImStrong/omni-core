import { ethers, network } from 'hardhat';
import { Signer, BigNumber } from 'ethers';
import * as dotenv from 'dotenv';
dotenv.config();

async function deposit(poolAddress: string, reserveAddress: string, account: Signer, amount: BigNumber) {
    const accountAddress = await account.getAddress();

    const networkName = network.name;

    if (reserveAddress.toLowerCase() == '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee') {
        const gateway = await ethers.getContractAt('WETHGateway', process.env[`${networkName.toUpperCase()}_WETH_GATEWAY`]!);
        const tx = await gateway.depositETH(poolAddress, accountAddress, 0, {
            value: amount
        });
        await tx.wait();
        console.log('deposit eth tx hash: ', tx.hash);
    }
    else {
        const bep20 = await ethers.getContractAt('BEP20', reserveAddress);
        const approveTx = await bep20.connect(account).approve(poolAddress, amount);
        await approveTx.wait();
        console.log('approve tx hash: ', approveTx.hash);

        const pool = await ethers.getContractAt("Pool", poolAddress);
        const depositTx = await pool.connect(account).deposit(reserveAddress, amount, accountAddress, 0);
        await depositTx.wait();
        console.log('deposit tx hash: ', depositTx.hash);
    }
}

export { deposit };