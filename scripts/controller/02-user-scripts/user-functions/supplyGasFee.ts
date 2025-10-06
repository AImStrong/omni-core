import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import { Signer } from "ethers";

async function supplyGasFee(
    universalMessengerAddress: string,
    chainId: number,
    account: Signer,
    amount: BigNumber,
    onBehalfOf: string
) {
    const accountAddress = await account.getAddress();
    
    const universalMessenger = await ethers.getContractAt("UniversalMessenger", universalMessengerAddress);
    const systemContract = await ethers.getContractAt("ISystem", await universalMessenger.systemContract());
    const gasTokenAddress = await systemContract.gasCoinZRC20ByChainId(chainId);

    // Approve gas token
    const gasToken = await ethers.getContractAt("IZRC20", gasTokenAddress);
    const approveTx = await gasToken.connect(account).approve(universalMessengerAddress, amount);
    await approveTx.wait();
    console.log('approve tx hash: ', approveTx.hash);

    // Supply gas fee
    const supplyTx = await universalMessenger.connect(account).depositGasBalance(
        chainId, 
        amount, 
        onBehalfOf
    );
    await supplyTx.wait();
    console.log('supply gas fee tx hash: ', supplyTx.hash);

    // Get user's gas balance
    const balance = await universalMessenger.getUserGasBalance(onBehalfOf, gasTokenAddress);
    console.log('User gas balance: ', balance.toString());
}

export { supplyGasFee }; 