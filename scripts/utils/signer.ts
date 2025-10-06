import { ethers } from 'hardhat';

async function getSigner(user: string) {
    const accounts = await ethers.getSigners();
    let i;
    for (i = 0; i < accounts.length; i++) {
        if (accounts[i].address.toLowerCase() === user.toLowerCase()) break;
    }
    if (i === accounts.length) {
        console.log('no signer');
        return null;
    }
    return accounts[i];
}

export {
    getSigner
}