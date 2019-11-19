#!/bin/bash

APP_PATH="../../tradestars-ui/src/artifacts"

# Delete any old artifacts from the app's directory
rm -f $APP_PATH/VestingManager.json $APP_PATH/TokenVesting.json $APP_PATH/TSTokens.json

# Copy the newly compiled artifacts to the app's directory
cp build/contracts/VestingManager.json \
    build/contracts/TokenVesting.json \
    build/contracts/TSToken.json \
    $APP_PATH