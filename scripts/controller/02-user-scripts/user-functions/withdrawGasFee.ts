import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import { Signer } from "ethers";

async function withdrawGasFee(
    universalMessengerAddress: string,
    chainId: number,
    account: Signer,
    amount: BigNumber,
    to: string
) {
    const accountAddress = await account.getAddress();
    
    const universalMessenger = await ethers.getContractAt("UniversalMessenger", universalMessengerAddress);
    const systemContract = await ethers.getContractAt("ISystem", await universalMessenger.systemContract());
    const gasTokenAddress = await systemContract.gasCoinZRC20ByChainId(chainId);

    // Get user's gas balance before withdrawal
    const balanceBefore = await universalMessenger.getUserGasBalance(accountAddress, gasTokenAddress);
    console.log('User gas balance before withdrawal: ', balanceBefore.toString());

    // Withdraw gas fee
    const withdrawTx = await universalMessenger.connect(account).withdrawGasBalance(
        chainId,
        amount,
        to
    );
    await withdrawTx.wait();
    console.log('withdraw gas fee tx hash: ', withdrawTx.hash);

    // Get receiver's gas balance after withdrawal
    const receiverBalanceAfter = await universalMessenger.getUserGasBalance(to, gasTokenAddress);
    console.log('Receiver gas balance after withdrawal: ', receiverBalanceAfter.toString());

    // Get user's gas balance after withdrawal
    const userBalanceAfter = await universalMessenger.getUserGasBalance(accountAddress, gasTokenAddress);
    console.log('User gas balance after withdrawal: ', userBalanceAfter.toString());
}

export { withdrawGasFee }; 