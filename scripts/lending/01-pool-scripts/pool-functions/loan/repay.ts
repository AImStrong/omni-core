import { ethers, network } from 'hardhat';
import { Signer, BigNumber } from 'ethers';
import * as dotenv from 'dotenv';
dotenv.config();

async function repay(poolAddress: string, reserveAddress: string, account: Signer, amount: BigNumber) {
    const accountAddress = await account.getAddress();

    const networkName = network.name;
    
    if (reserveAddress.toLowerCase() == '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee') {
        const gateway = await ethers.getContractAt('WETHGateway', process.env[`${networkName.toUpperCase()}_WETH_GATEWAY`]!);

        const pool = await ethers.getContractAt("Pool", process.env[`${networkName.toUpperCase()}_POOL_PROXY`]!);
        const reserve = await pool.getReserveData(process.env[`${networkName.toUpperCase()}_WETH`]!);

        const BEP20 = await ethers.getContractAt('BEP20', reserve.variableDebtTokenAddress);
        let amountToRepay = await BEP20.balanceOf(accountAddress);
        if (greater(amountToRepay, amount)) amountToRepay = amount;
        amountToRepay = amountToRepay.add(amountToRepay.div(100));

        const tx = await gateway.repayETH(poolAddress, amount, accountAddress, {
            value: amountToRepay
        });
        await tx.wait();
        console.log('repay eth tx hash: ', tx.hash);
    }
    else {
        const bep20 = await ethers.getContractAt('BEP20', reserveAddress);
        const approveTx = await bep20.connect(account).approve(poolAddress, amount);
        await approveTx.wait();
        console.log('approve tx hash: ', approveTx.hash);

        const pool = await ethers.getContractAt("Pool", poolAddress);
        const repayTx = await pool.connect(account).repay(reserveAddress, amount, accountAddress);
        await repayTx.wait();
        console.log('repay tx hash: ', repayTx.hash);
    }
}

function greater(a: BigNumber, b: BigNumber) {
    if (a.toString().length > b.toString().length) return true;
    if (a.toString().length < b.toString().length) return false;
    return (a > b);
}

export { repay };