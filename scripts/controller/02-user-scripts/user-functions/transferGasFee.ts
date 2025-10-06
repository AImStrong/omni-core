import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import { Signer } from "ethers";

async function transferGasFee(
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

    // Get balances before transfer
    const senderBalanceBefore = await universalMessenger.getUserGasBalance(accountAddress, gasTokenAddress);
    const receiverBalanceBefore = await universalMessenger.getUserGasBalance(to, gasTokenAddress);
    console.log('Sender gas balance before transfer: ', senderBalanceBefore.toString());
    console.log('Receiver gas balance before transfer: ', receiverBalanceBefore.toString());

    // Transfer gas fee
    const transferTx = await universalMessenger.connect(account).transferGasBalance(
        chainId,
        amount,
        to
    );
    await transferTx.wait();
    console.log('transfer gas fee tx hash: ', transferTx.hash);

    // Get balances after transfer
    const senderBalanceAfter = await universalMessenger.getUserGasBalance(accountAddress, gasTokenAddress);
    const receiverBalanceAfter = await universalMessenger.getUserGasBalance(to, gasTokenAddress);
    console.log('Sender gas balance after transfer: ', senderBalanceAfter.toString());
    console.log('Receiver gas balance after transfer: ', receiverBalanceAfter.toString());
}

export { transferGasFee }; 