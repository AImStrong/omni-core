import { ethers } from 'hardhat';
import * as dotenv from 'dotenv';
dotenv.config();

function encode(funcSig: string, params: any[]) {

    let funcName = '';

    for (let i = 0; funcSig[i] != '('; i++) {
        funcName += funcSig[i];
    }

    const contractInterface = new ethers.utils.Interface([
        `function ${funcSig}`
    ]);

    const data = contractInterface.encodeFunctionData(funcName, params);

    return data;
}

export {
    encode
}