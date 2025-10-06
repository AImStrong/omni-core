import { ethers, network } from 'hardhat';
import { Signer, BigNumber } from 'ethers';
import { ReserveAssets } from '../../../../config/reserveAssets';
import * as dotenv from 'dotenv';
dotenv.config();

async function withdraw(poolAddress: string, reserveAddress: string, account: Signer, amount: BigNumber, value: BigNumber) {
    const accountAddress = await account.getAddress();

    const networkName = network.name;

    const pool = await ethers.getContractAt("Pool", poolAddress);

    if (reserveAddress.toLocaleLowerCase() == '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee') {
        const withdrawTx = await pool.connect(account).withdraw(((ReserveAssets as any)[networkName]['WETH'] as any).underlyingAddress, amount, accountAddress, true, {
            value: value,
        });
        await withdrawTx.wait();
        console.log('withdraw eth tx hash: ', withdrawTx.hash);
    }
    else {
        const withdrawTx = await pool.connect(account).withdraw(reserveAddress, amount, accountAddress, false, {
            value: value,
        });
        await withdrawTx.wait();
        console.log('withdraw tx hash: ', withdrawTx.hash);
    }
}

export { withdraw };