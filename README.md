# Contracts for TradeStars App.
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
$ zos create TSToken --init initialize --args $OWNER
Creating TSToken proxy and calling initialize with:
 - _sender (address): $OWNER
TSToken proxy: 0x568877b70b562af298a8436b28733ed6be6aad46
```
```bash
$ zos create VestingManager --init initialize --args $OWNER,$TSTOKEN
Creating VestingManager proxy and calling initialize with:
 - _sender (address): $OWNER
 - _token (address): $TSTOKEN
VestingManager proxy: 0x568877b70b562af298a8436b28733ed6be6aad46
```
