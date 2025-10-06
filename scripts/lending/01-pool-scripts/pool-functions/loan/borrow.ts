import { ethers, network } from 'hardhat';
import { Signer, BigNumber } from 'ethers';
import { ReserveAssets } from '../../../../config/reserveAssets';
import * as dotenv from 'dotenv';
dotenv.config();

async function borrow(poolAddress: string, reserveAddress: string, account: Signer, amount: BigNumber, value: BigNumber) {
    const accountAddress = await account.getAddress();

    const networkName = network.name;
    
    const pool = await ethers.getContractAt("Pool", poolAddress);

    if (reserveAddress.toLocaleLowerCase() == '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee') {
        const borrowTx = await pool.connect(account).borrow(((ReserveAssets as any)[networkName]['WETH'] as any).underlyingAddress, amount, accountAddress, true, 0, {
            value: value,
        });
        await borrowTx.wait();
        console.log('borrow eth tx hash: ', borrowTx.hash);
    }
    else {
        const borrowTx = await pool.connect(account).borrow(reserveAddress, amount, accountAddress, false, 0, {
            value: value,
        });
        await borrowTx.wait();
        console.log('borrow tx hash: ', borrowTx.hash);
    }
}

export { borrow };