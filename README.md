# Contracts for [TradeStars.app](https://tradestars.app) utility token.

[![Build Status](https://travis-ci.com/tradestars-app/tradestars-token.svg?branch=master)](https://travis-ci.com/tradestars-app/tradestars-token)

## TradeStars Utility Token

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
$ ganache-cli --port 9545 --deterministic
$ npm test
```

Publish the project to a network.

```bash
npx zos session --network ropsten
npx zos push
```

Create the proxy instances:

```bash
$ zos create TSToken --init --args $OWNER --no-interactive
Deploying new ProxyAdmin...
Deployed ProxyAdmin at 0xb4fFe5983B0B748124577Af4d16953bd096b6897
Creating proxy to logic contract 0x9e90054F4B6730cffAf1E6f6ea10e1bF9dD26dbb and initializing by calling initialize with:
 - _sender (address): "0x2828c3048D07208AF0aC2C089AafdBe63Ec941A2"
Instance created at 0xFF5181e2210AB92a5c9db93729Bc47332555B9E9
```
```bash
$ zos create VestingManager --init --args $OWNER,$TSTOKEN --no-interactive
Creating proxy to logic contract 0xfE82e8f24A51E670133f4268cDfc164c49FC3b37 and initializing by calling initialize with:
 - _sender (address): "0x2828c3048D07208AF0aC2C089AafdBe63Ec941A2"
 - _token (address): "0xFF5181e2210AB92a5c9db93729Bc47332555B9E9"
Instance created at 0x6f84742680311CEF5ba42bc10A71a4708b4561d1
```
