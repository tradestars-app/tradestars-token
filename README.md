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
