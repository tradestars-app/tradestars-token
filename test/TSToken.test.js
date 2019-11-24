const { TestHelper } = require('@openzeppelin/cli');
const { Contracts, ZWeb3, assertRevert } = require('@openzeppelin/upgrades');

const { toWei } = require('web3-utils');
const abi = require('ethereumjs-abi');

ZWeb3.initialize(web3.currentProvider);

require('chai').should();

/// check events
function checkEventName(tx, eventName) {
  tx.events[eventName].event.should.be.eq(eventName);
}

const TSToken = Contracts.getFromLocal('TSToken');
const MockPlasma = Contracts.getFromLocal('MockContract');

contract('TSToken', ([_, owner, notOwner, referralManager, someone, anotherOne]) => {

  let token;
  let plasmaRoot;

  before(async function() {
      const project = await TestHelper();

      /// Create TS Token
      token = await project.createProxy(TSToken, {
        initMethod: 'initialize',
        initArgs: [owner]
      });

      // create a mock
      plasmaRoot = await MockPlasma.new({ gas: 4000000 });
  });

  describe('Mint/Burn tests', function() {

    it(`should OK mint()`, async function() {
      const amount = toWei('200');

      const tx = await token.methods.mint(anotherOne, amount).send({
        from: owner,
        gas: 6721975,
        gasPrice: 5e9
      });

      checkEventName(tx, "Transfer");
    });

    it(`should FAIL mint() :: not owner`, async function() {
      const amount = toWei('200');

      await assertRevert(
        token.methods.mint(anotherOne, amount).send({
          from: notOwner,
          gas: 6721975,
          gasPrice: 5e9
        })
      );
    });

    it(`should OK tokensBurned() counter`, async function() {
      const amount = toWei('100');

      const tx = await token.methods.burn(amount).send({
        from: anotherOne,
        gas: 6721975,
        gasPrice: 5e9
      });

      checkEventName(tx, "Transfer");

      const ret = await token.methods.tokensBurned().call();
      ret.should.be.eq(String(amount));
    });

  });

  describe('DepositManager tests', function() {

    it(`should OK setReferralManager()`, async function() {
      await token.methods.setReferralManager(referralManager).send({
        from: owner,
        gas: 6721975,
        gasPrice: 5e9
      });
    });

    it(`should FAIL setReferralManager() :: not owner`, async function() {
      await assertRevert(
        token.methods.setReferralManager(referralManager).send({
          from: notOwner,
          gas: 6721975,
          gasPrice: 5e9
        })
      );
    });
  });

  describe('Redeem tokens test', function() {

    before(async function() {
      /// mint tokens for referralManager
      await token.methods.mint(referralManager, toWei('1000000')).send({
        from: owner,
        gas: 6721975,
        gasPrice: 5e9
      });
    });

    /// Before each call to redem, set allowance to 0, because theres no
    /// call from the plasmaRoot contract. (calls transferFrom on each deposit)
    beforeEach(async function () {
      await token.methods.approve(plasmaRoot.address, 0).send({
        from: referralManager,
        gas: 5000000
      });
    });

    it(`Should OK redeemTokens()`, async function() {
      const qualifiedNonce = 1;
      const tokensPerCredit = toWei('250');

      const tx = await token.methods.redeemTokens(
        someone,
        qualifiedNonce,
        tokensPerCredit,
        plasmaRoot.address
      ).send({
        from: referralManager,
        gas: 6721975,
        gasPrice: 5e9
      });

      checkEventName(tx, 'Redeemed');

      const { nonce, amount } = await token.methods.getReferralInfo(someone).call();

      nonce.should.be.eq(String(qualifiedNonce));
      amount.should.be.eq(tokensPerCredit);
    });

    it(`Should OK redeem to non-consecutive nonce`, async function() {
      const qualifiedNonce = 4;
      const tokensPerCredit = toWei('300');

      const totalTokensRedeemed = toWei(String( ((4 - 1) * 300) + 250 ));

      const tx = await token.methods.redeemTokens(
        someone,
        qualifiedNonce,
        tokensPerCredit,
        plasmaRoot.address
      ).send({
        from: referralManager,
        gas: 6721975,
        gasPrice: 5e9
      });

      checkEventName(tx, 'Redeemed');

      const { nonce, amount } = await token.methods.getReferralInfo(someone).call();

      nonce.should.be.eq(String(qualifiedNonce));
      amount.should.be.eq(totalTokensRedeemed);
    });

    it(`FAIL redeemTokens() :: nonce invalid (< last nonce)`, async function() {
      const qualifiedNonce = 0;
      const tokensPerCredit = toWei('250');

      await assertRevert(
        token.methods.redeemTokens(
          someone,
          qualifiedNonce,
          tokensPerCredit,
          plasmaRoot.address
        ).send({
          from: referralManager,
          gas: 6721975,
          gasPrice: 5e9
        })
      );
    });

    it(`FAIL redeemTokens() :: nonce invalid (= last nonce)`, async function() {
      const qualifiedNonce = 4;
      const tokensPerCredit = toWei('250');

      await assertRevert(
        token.methods.redeemTokens(
          someone,
          qualifiedNonce,
          tokensPerCredit,
          plasmaRoot.address
        ).send({
          from: referralManager,
          gas: 6721975,
          gasPrice: 5e9
        })
      );
    });

    it(`FAIL redeemTokens() :: non referralManager call`, async function() {
      const qualifiedNonce = 5;
      const tokensPerCredit = toWei('250');

      await assertRevert(
        token.methods.redeemTokens(
          someone,
          qualifiedNonce,
          tokensPerCredit,
          plasmaRoot.address
        ).send({
          from: someone,
          gas: 6721975,
          gasPrice: 5e9
        })
      );
    });

  });

});