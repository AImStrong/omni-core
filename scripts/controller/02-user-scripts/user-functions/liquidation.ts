import { ethers } from "hardhat";
import { BigNumber } from "ethers";
import { Signer } from "ethers";

async function liquidationCallPhase1(
    controllerAddress: string,
    debtAsset: string,
    collateralAsset: string,
    debtChainId: number,
    collateralChainId: number,
    user: string,
    debtToCover: BigNumber,
    receiveTToken: boolean,
    account: Signer
) {
    const controller = await ethers.getContractAt("CrossChainLendingController", controllerAddress);
    
    const liquidateTx = await controller.connect(account).liquidationCallPhase1(
        debtAsset,
        collateralAsset,
        debtChainId,
        collateralChainId,
        user,
        debtToCover,
        receiveTToken
    );
    await liquidateTx.wait();
    console.log('liquidation phase 1 tx hash: ', liquidateTx.hash);
}

async function retryLiquidationCallPhase3(
    universalMessengerAddress: string,
    chainId: number,
    countId: number,
    user: string,
    data: string,
    account: Signer
) {
    const universalMessenger = await ethers.getContractAt("UniversalMessenger", universalMessengerAddress);
    
    const retryTx = await universalMessenger.connect(account).retryLiquidationCallPhase3(
        chainId,
        countId,
        user,
        data
    );
    await retryTx.wait();
    console.log('retry liquidation phase 3 tx hash: ', retryTx.hash);
}

async function getFailedLiquidationPhase3Messages(
    universalMessengerAddress: string,
    chainId: number,
    countId: number
) {
    const universalMessenger = await ethers.getContractAt("UniversalMessenger", universalMessengerAddress);
    
    const messageHash = await universalMessenger.failedLiquidationPhase3Messages(chainId, countId);
    console.log('Failed liquidation phase 3 message hash: ', messageHash);
    
    return messageHash;
}

export { liquidationCallPhase1, retryLiquidationCallPhase3, getFailedLiquidationPhase3Messages }; 