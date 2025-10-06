import fs from "fs";
import { toChecksumAddress } from 'ethereumjs-util';
import { EthAddress, uint256 } from "./type";
import { BigNumber } from "ethers";
import { network } from "hardhat";
import * as hre from "hardhat";
import { getMainOwner } from "../sdk/rdOwner";

export async function getGasPrice(exGasPrice: BigNumber) {
    let defaultGasPrice = BigNumber.from("0");
    let newGasPrice = defaultGasPrice;

    if (exGasPrice.gt('0')) {
        defaultGasPrice = BigNumber.from(network.config.gasPrice);
        newGasPrice = defaultGasPrice.gt('0') ? defaultGasPrice : await hre.ethers.providers.getDefaultProvider().getGasPrice();
    } else if (network.name === 'ethMainnet') {
        defaultGasPrice = BigNumber.from(network.config.gasPrice);
        newGasPrice = defaultGasPrice.gt('0') ? defaultGasPrice : await hre.ethers.providers.getDefaultProvider().getGasPrice();
    } else if (network.name === 'bscTestnet') {
        defaultGasPrice = BigNumber.from(network.config.gasPrice);
        newGasPrice = defaultGasPrice.gt('0') ? defaultGasPrice : await hre.ethers.providers.getDefaultProvider().getGasPrice();
    }

    // if (exGasPrice.gte(newGasPrice)) {
    //     newGasPrice = exGasPrice.add(3e9);
    // }
    return newGasPrice;
};

export function getTimestampFromUTXTime(utxTime: string) {
    var desiredDate = new Date(utxTime);
    console.log(desiredDate)
    return Math.floor(desiredDate.getTime() / 1000).toString();
}


export async function getOption() {
    const gasPrice = await getGasPrice(BigNumber.from("0"));
    const nonce = await getMainOwner().getTransactionCount();
    const options = { gasPrice: gasPrice, nonce: nonce };

    return options

}
export function writeToEnvFile(key: String, value: String) {
    const envFilePath = '.env';
    const envString = `${key}=${value}`;

    try {
        if (fs.existsSync(envFilePath)) {
            let data = fs.readFileSync(envFilePath, 'utf8');
            const lines = data.trim().split('\n');
            let keyExists = false;
            const updatedLines = lines.map(line => {
                const [existingKey] = line.split('=');
                if (existingKey === key) {
                    keyExists = true;
                    return envString;
                }
                return line;
            });
            if (!keyExists) {
                updatedLines.push(envString);
            }
            const updatedData = updatedLines.join('\n');
            fs.writeFileSync(envFilePath, updatedData + '\n');
        } else {
            fs.writeFileSync(envFilePath, envString + '\n');
        }
        console.log('Successfully wrote to .env file.');
    } catch (err) {
        console.error('Error writing to .env file:', err);
    }
}

export const convertHexStringToAddress = (hexString: EthAddress): EthAddress => {
    String(hexString).toLowerCase();
    const strippedHex = hexString.replace(/^0x/, '');

    return toChecksumAddress(`0x${strippedHex}`);
}

