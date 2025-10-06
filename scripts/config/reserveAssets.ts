const ReserveAssets = {
    base_mainnet: {
        USDC: {
            reserveName: 'USDC',
            underlyingAddress: '0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913',
        },
        USDT: {
            reserveName: 'Bridged Tether USD',
            underlyingAddress: '0xfde4C96c8593536E31F229EA8f37b2ADa2699bb2',
        },
        WETH: {
            reserveName: 'Wrapped Ether',
            underlyingAddress: '0x4200000000000000000000000000000000000006',
        },
        cbBTC: {
            reserveName: 'Coinbase Wrapped BTC',
            underlyingAddress: '0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf',
        }
    },
    arbitrum_one_mainnet: {
        USDC: {
            reserveName: 'USD Coin',
            underlyingAddress: '0xaf88d065e77c8cC2239327C5EDb3A432268e5831',
        },
        USDT: {
            reserveName: 'USD₮0',
            underlyingAddress: '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9',
        },
        WETH: {
            reserveName: 'Wrapped Ether',
            underlyingAddress: '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
        },
        WBTC: {
            reserveName: 'Wrapped BTC',
            underlyingAddress: '0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f',
        }
    },
    bsc_mainnet: {
        WBNB: {
            reserveName: 'Wrapped BNB',
            underlyingAddress: '0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c',
        },
        USDT: {
            reserveName: 'Tether USD',
            underlyingAddress: '0x55d398326f99059fF775485246999027B3197955',
        },
        USDC: {
            reserveName: 'USD Coin',
            underlyingAddress: '0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d',
        }
    },
    bsc_testnet: {
        USDC: {
            reserveName: 'USDC',
            underlyingAddress: '0x345dCB7B8F17D342A3639d1D9bD649189f2D0162',
        },
        USDT: {
            reserveName: 'USDT',
            underlyingAddress: '0x780397E17dBF97259F3b697Ca3a394fa483A1419',
        },
    },
};

export { ReserveAssets };