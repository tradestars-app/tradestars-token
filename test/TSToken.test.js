const { TestHelper } = require('@openzeppelin/cli');
const { Contracts, ZWeb3, assertRevert } = require('@openzeppelin/upgrades');

const { toWei, BN } = require('web3-utils');

ZWeb3.initialize(web3.currentProvider);

require('chai').should();

/// check events
function checkEventName(tx, eventName) {
  tx.events[eventName].event.should.be.eq(eventName);
}

const TSToken = Contracts.getFromLocal('TSToken');

contract('VestingManager', ([_, owner, notOwner, party1, depositManager, plasmaAddr, anyone]) => {

    let token;

    before(async function() {
        const project = await TestHelper();

        /// Create TS Token
        token = await project.createProxy(TSToken, {
          initMethod: 'initialize',
          initArgs: [owner]
        });
    });

    describe('Mint/Burn tests', function() {

      it(`should OK mint()`, async function() {
        const amount = toWei('200');

        const tx = await token.methods.mint(party1, amount).send({
          from: owner,
          gas: 6721975,
          gasPrice: 5e9
        });
        checkEventName(tx, "Transfer");
      });

      it(`should FAIL mint() :: not owner`, async function() {
        await assertRevert(
          token.methods.mint(party1, owner).send({
            from: notOwner,
            gas: 6721975,
            gasPrice: 5e9
          })
        );
      });

      it(`should OK tokensBurned() counter`, async function() {
        const amount = toWei('100');
        const tx = await token.methods.burn(amount).send({
          from: party1,
          gas: 6721975,
          gasPrice: 5e9
        });
        checkEventName(tx, "Transfer");

        const ret = await token.methods.tokensBurned().call();
        ret.should.be.eq(String(amount));
      });

    });

    describe('DepositManager tests', function() {

      it(`should OK setDepositManagerAddress()`, async function() {
        const tx = await token.methods.setDepositManagerAddress(depositManager).send({
          from: owner,
          gas: 6721975,
          gasPrice: 5e9
        });

        checkEventName(tx, "DepositManagerChange");
      });

      it(`should FAIL setDepositManagerAddress() :: not owner`, async function() {
        await assertRevert(
          token.methods.setDepositManagerAddress(depositManager).send({
            from: notOwner,
            gas: 6721975,
            gasPrice: 5e9
          })
        );
      });

      it(`should OK increaseAllowanceForDeposit()`, async function() {
        const amount = toWei('100');

        await token.methods.increaseAllowanceForDeposit(
          party1,
          amount,
          plasmaAddr
        ).send({
          from: depositManager,
          gas: 6721975,
          gasPrice: 5e9
        });
      });

      it(`should FAIL increaseAllowanceForDeposit() :: invalid call address`, async function() {
        const amount = toWei('100');

        await assertRevert(
          token.methods.increaseAllowanceForDeposit(
            party1,
            amount,
            plasmaAddr
          ).send({
            from: anyone,
            gas: 6721975,
            gasPrice: 5e9
          })
        );
      });

      it(`should FAIL increaseAllowanceForDeposit() :: current allowance > 0`, async function() {
        const amount = toWei('100');

        await assertRevert(
          token.methods.increaseAllowanceForDeposit(
            party1,
            amount,
            plasmaAddr
          ).send({
            from: depositManager,
            gas: 6721975,
            gasPrice: 5e9
          })
        );
      });

    });

});