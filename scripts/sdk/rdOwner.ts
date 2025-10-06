"use strict";
const { ethers } = require("hardhat");
const hre = require('hardhat');

require("dotenv").config();

const adminKey = {
    publicKey: process.env.PUBLIC_KEY,
    privateKey: process.env.PRIVATE_KEY,
};

const getMainOwner = () => {
    return new ethers.Wallet(adminKey.privateKey, ethers.provider);
}

const getSigner = () => {
    const signer = hre.ethers.provider.getSigner(adminKey.publicKey);
    return signer
}

export { getMainOwner, getSigner }

