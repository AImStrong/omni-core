import "@typechain/hardhat";
import "hardhat-contract-sizer";
import "@nomiclabs/hardhat-ethers";
import "@ethersproject/abstract-provider";
import "@ethersproject/abstract-signer";
import "@ethersproject/transactions";
import "@ethersproject/bytes";
import "hardhat-interface-generator";
import { HardhatUserConfig } from "hardhat/config";
import * as dotenv from "dotenv";
dotenv.config();

const PRIVATE_KEY = process.env.PRIVATE_KEY!;

const config: HardhatUserConfig = {
	networks: {
		bsc_testnet: {
			url: "https://bsc-testnet-rpc.publicnode.com",
			chainId: 97,
			gasPrice: 1e10,
			gas: 2e7,
			accounts: [PRIVATE_KEY],
		},
		zeta_testnet: {
			url: "https://zetachain-testnet.public.blastapi.io",
			chainId: 7001,
			gasPrice: 1e8,
			gas: 2e7,
			accounts: [PRIVATE_KEY],
		},
		sepolia: {
			url: "https://eth-sepolia.public.blastapi.io",
			chainId: 11155111,
			gasPrice: 1e10,
			gas: 2e7,
			accounts: [PRIVATE_KEY],
		},
		avalanche_testnet: {
			url: "https://api.avax-test.network/ext/bc/C/rpc",
			chainId: 43113,
			gasPrice: 1e10,
			gas: 2e7,
			accounts: [PRIVATE_KEY],
		},
		avalanche_mainnet: {
			url: "https://api.avax.network/ext/bc/C/rpc",
			chainId: 43114,
			// gasPrice: 1e10,
			gas: 2e7,
			accounts: [PRIVATE_KEY],
		},
		zeta_mainnet: {
			url: "https://zetachain-evm.blockpi.network/v1/rpc/public",
			chainId: 7000,
			// gasPrice: 1e8,
			gas: 5e6,
			accounts: [PRIVATE_KEY],
		},
		base_mainnet: {
			url: "https://base-mainnet.public.blastapi.io",
			chainId: 8453,
			// gasPrice: 1e8,
			gas: 5e6,
			accounts: [PRIVATE_KEY],
		},
		arbitrum_one_mainnet: {
			url: "https://arbitrum-one-rpc.publicnode.com",
			chainId: 42161,
			// gasPrice: 1e8,
			gas: 5e6,
			accounts: [PRIVATE_KEY],
		},
		bsc_mainnet: {
			url: "https://public-bsc.nownodes.io",
			chainId: 56,
			// gasPrice: 1e8,
			gas: 5e6,
			accounts: [PRIVATE_KEY],
		}
	},
	paths: {
		tests: "./test",
		artifacts: "./build/artifacts",
		cache: "./build/cache",
	},
	solidity: {
		compilers: [
			{
				version: "0.6.12",
				settings: {
					viaIR: true,
					optimizer: {
						enabled: true,
						runs: 0,
					},
				},
			},
			{
				version: "0.8.26",
				settings: {
					viaIR: true,
					optimizer: {
						enabled: true,
						runs: 0,
					},
				},
			},
			{
				version: "0.8.20",
				settings: {
					viaIR: true,
					optimizer: {
						enabled: true,
						runs: 0,
					},
				},
			},
			{
				version: "0.8.22",
				settings: {
					viaIR: true,
					optimizer: {
						enabled: true,
						runs: 0,
					},
				},
			},
		],
	},
	contractSizer: {
		alphaSort: true,
		runOnCompile: false,
		disambiguatePaths: false,
	},
};

export default config;