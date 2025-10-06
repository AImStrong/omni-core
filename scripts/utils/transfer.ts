import { ethers } from 'hardhat';
import { BigNumber } from 'ethers';

async function transfer(to: string, asset: string, amount: BigNumber) {
    const accounts = await ethers.getSigners();

    if (asset.toLowerCase() === '0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee') {

        console.log(`${accounts[0].address} balance before transfer: `, await ethers.provider.getBalance(accounts[0].address));
        console.log(`${to} balance before transfer: `, await ethers.provider.getBalance(to));

        const tx = await accounts[0].sendTransaction({
            to: to,
            value: amount,
        });

        await tx.wait();
        console.log('transfer tx hash: ', tx.hash);

        console.log(`${accounts[0].address} balance after transfer: `, await ethers.provider.getBalance(accounts[0].address));
        console.log(`${to} balance after transfer: `, await ethers.provider.getBalance(to));
    }
    else {
        const bep20 = await ethers.getContractAt('BEP20', asset);

        console.log(`${accounts[0].address} balance before transfer: `, await bep20.balanceOf(accounts[0].address));
        console.log(`${to} balance before transfer: `, await bep20.balanceOf(to));

        const tx = await bep20.connect(accounts[0]).transfer(to, amount);

        await tx.wait();
        console.log('tranfer tx hash: ', tx.hash);

        console.log(`${accounts[0].address} balance after transfer: `, await bep20.balanceOf(accounts[0].address));
        console.log(`${to} balance after transfer: `, await bep20.balanceOf(to));
    }
}

export {
    transfer
}