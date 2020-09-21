# Contracts for [TradeStars.app](https://tradestars.app) utility token and vesting management.

[![Build Status](https://travis-ci.com/tradestars-app/tradestars-token.svg?branch=master)](https://travis-ci.com/tradestars-app/tradestars-token)

## Dependencies
- [npm](https://www.npmjs.com/): v6.9.0.

## Build and Test
Clone the project repository and enter the root directory:

```bash
$ git clone git@github.com:tradestars-app/tradestars-token.git
$ cd tradestars-token
```

Install project dependencies:

```bash
$ npm install
```

## Local Test Example

Run a local ganache instance as:

```bash
$ ganache-cli -d
$ npm run test
```

Publish the project to a network.

```bash
npx oz session --network ropsten
npx oz push
```


## Goërly
```
TSX: 0x6d1f63c20e2af745b21425d4cfd88857900a3e74
sTSX: 0xBDc785518880B284FE2147E28Bb3382Bb4042807

VestingManager: 0xC47871D24ed22984fa66cDb1c5936c3e7D458A70
ReserveToken (erc20mock): 0x38aeFC771069596bbf40dE298aCF21388e58eB90


UniswapRouterV2: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
UniswapManager: 0xa4f3d97908CCfb2Bedd700D4606020d2Ca54F9c8
Bridge: 0x2890bA17EfE978480615e330ecB65333b880928e

Cashier: 0x8DC7Cf78b27a328dddbfBD01e860cdfbc46e9182
```
