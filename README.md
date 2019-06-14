# Contracts for TradeStars App.
[![Build Status](https://travis-ci.com/tradestars-app/tradestars-token.svg?branch=master)](https://travis-ci.com/tradestars-app/tradestars-token)

## TradeStars Utility Token

## Dependencies
- [npm](https://www.npmjs.com/): v6.2.0.
- [zos](https://www.npmjs.com/package/zos): v1.0.0

You can check if the dependencies are installed correctly by running the following command:

```
$ npm --version
6.2.0
$ zos --version
1.0.0
```

## Build and Test
After installing the dependencies previously mentioned, clone the project repository and enter the root directory:

```
$ git clone git@github.com:tradestars-app/tradestars-token.git
$ cd tradestars-token
```

Then, install ZeppelinOS and project dependencies:

```
$ npm install --global zos
$ $ npm install`
```

## Local Example

Run a local ganache instance as:

`$ ganache-cli --port 9545 --deterministic -e 100`

Build and deploy contracts

```
npx zos session --network local --from 0x1df62f291b2e969fb0849d99d9ce41e2f137006e --expires 3600
npx zos push --deploy-dependencies
```

Run package unit tests

`$ npm test`
