import { ethers, network } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

async function getUserAssetData(user: string, asset: string, chainId: number) {
    let networkName = network.name;

    // ========= Contracts required ========= 
    const controller = await ethers.getContractAt(`CrossChainLendingController`, process.env[`${networkName.toUpperCase()}_CONTROLLER_PROXY`]!);

    // Get the reserve data to get the current indices
    const reserveData = await controller.getReserveData(chainId, asset);

    console.log(reserveData);

    // Get user account data to extract information about their position
    const [
        totalCollateralUSD, 
        totalDebtUSD, 
        availableBorrowsUSD, 
        currentLiquidationThreshold, 
        ltv, 
        healthFactor,
        isBeingLiquidated
    ] = await controller.getUserAccountData(user);
    
    // Get the user asset specific data
    const [
        income, 
        debt, 
        userConfig, 
        isBorrowing, 
        isUsingAsCollateral, 
        scaledIncome, 
        scaledDebt, 
        currentLiquidityIndex, 
        currentVariableBorrowIndex
    ] = await controller.getUserAssetDataInDetail(user, asset, chainId);

    const apr = await controller.getUserApr(user);

    return {
        user,
        asset,
        chainId,
        // User specific data for the asset
        income: income.toString(),
        debt: debt.toString(),
        // User account general data
        totalCollateralUSD: totalCollateralUSD.toString(),
        totalDebtUSD: totalDebtUSD.toString(),
        availableBorrowsUSD: availableBorrowsUSD.toString(),
        currentLiquidationThreshold: currentLiquidationThreshold.toString(),
        ltv: ltv.toString(),
        healthFactor: healthFactor.toString(),
        // Reserve specific data
        liquidityIndex: reserveData.liquidityIndex.toString(),
        variableBorrowIndex: reserveData.variableBorrowIndex.toString(),
        currentLiquidityRate: reserveData.currentLiquidityRate.toString(),
        currentVariableBorrowRate: reserveData.currentVariableBorrowRate.toString(),
        balanceOfUnderlyingAsset: reserveData.balanceOfUnderlyingAsset.toString(),
        userConfig: userConfig.toString(),
        isBeingLiquidated: isBeingLiquidated.toString(),
        // Additional user asset data
        isBorrowing: isBorrowing.toString(),
        isUsingAsCollateral: isUsingAsCollateral.toString(),
        scaledIncome: scaledIncome.toString(),
        scaledDebt: scaledDebt.toString(),
        currentLiquidityIndex: currentLiquidityIndex.toString(),
        currentVariableBorrowIndex: currentVariableBorrowIndex.toString(),
        apr : apr.toString()
    };
}

export {
    getUserAssetData
}