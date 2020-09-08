const { accounts, contract } = require('@openzeppelin/test-environment')
// const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const {
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers')

const { toWei } = require('web3-utils')

const TSToken = contract.fromArtifact('TSToken')
const BridgeMock = contract.fromArtifact('BridgeMock')

require('chai').should();

describe('TSToken', function() {
  const [owner, notOwner, referralManager, someone, anotherOne] = accounts;

  let token;
  let plasmaBridge;

  before(async function() {
      /// Create TS Token
      // token = await deployProxy(TSToken, {
      //   initMethod: 'initialize',
      //   initArgs: [owner]
      // });

      // create the token as non-upgradedable
      token = await TSToken.new({ from: owner })
              await token.initialize({ from: owner })

      // create a mock
      plasmaBridge = await BridgeMock.new();
  });

  describe('Mint/Burn tests', function() {

    it(`should OK mint()`, async function() {
      const amount = toWei('200');

      const tx = await token.mint(anotherOne, amount, {
        from: owner
      });

      expectEvent(tx, "Transfer");
    });

    it(`should FAIL mint() :: not owner`, async function() {
      const amount = toWei('200');

      await expectRevert(
        token.mint(anotherOne, amount, {
          from: notOwner
        }),
        'Ownable: caller is not the owner'
      );
    });

    it(`should OK tokensBurned() counter`, async function() {
      const amount = toWei('100');

      const tx = await token.burn(amount, {
        from: anotherOne
      });

      expectEvent(tx, "Transfer");

      const ret = await token.tokensBurned()
      ret.should.be.bignumber.eq(amount);
    });

  });

  describe('DepositManager tests', function() {

    it(`should OK setReferralManager()`, async function() {
      await token.setReferralManager(referralManager, {
        from: owner
      });
    });

    it(`should FAIL setReferralManager() :: not owner`, async function() {
      await expectRevert(
        token.setReferralManager(referralManager, {
          from: notOwner
        }),
        'Ownable: caller is not the owner'
      );
    });
  });

  describe('Redeem tokens test', function() {

    before(async function() {
      /// mint tokens for referralManager
      await token.mint(referralManager, toWei('1000000'), {
        from: owner
      });
    });

    it(`Should OK redeemTokens()`, async function() {
      const qualifiedNonce = 1;
      const tokensPerCredit = toWei('250');

      const tx = await token.redeemTokens(
        someone,
        qualifiedNonce,
        tokensPerCredit,
        plasmaBridge.address, {
          from: referralManager
        }
      );

      expectEvent(tx, 'Redeemed');

      const { nonce, amount } = await token.getReferralInfo(someone)

      nonce.should.be.bignumber.eq(`${qualifiedNonce}`);
      amount.should.be.bignumber.eq(tokensPerCredit);
    });

    it(`Should OK redeem to non-consecutive nonce`, async function() {
      const qualifiedNonce = 4;
      const tokensPerCredit = toWei('300');

      const totalTokensRedeemed = toWei(String( ((4 - 1) * 300) + 250 ));
      const tx = await token.redeemTokens(
        someone,
        qualifiedNonce,
        tokensPerCredit,
        plasmaBridge.address, {
          from: referralManager
        }
      );

      expectEvent(tx, 'Redeemed');

      const { nonce, amount } = await token.getReferralInfo(someone)

      nonce.should.be.bignumber.eq(`${qualifiedNonce}`);
      amount.should.be.bignumber.eq(totalTokensRedeemed);
    });

    it(`FAIL redeemTokens() :: nonce invalid (< last nonce)`, async function() {
      const qualifiedNonce = 0;
      const tokensPerCredit = toWei('250');

      await expectRevert(
        token.redeemTokens(
          someone,
          qualifiedNonce,
          tokensPerCredit,
          plasmaBridge.address, {
            from: referralManager
          }
        ),
        'qualifiedNonce is invalid'
      );
    });

    it(`FAIL redeemTokens() :: nonce invalid (= last nonce)`, async function() {
      const qualifiedNonce = 4;
      const tokensPerCredit = toWei('250');

      await expectRevert(
        token.redeemTokens(
          someone,
          qualifiedNonce,
          tokensPerCredit,
          plasmaBridge.address, {
            from: referralManager
          }
        ),
        'qualifiedNonce is invalid'
      );
    });

    it(`FAIL redeemTokens() :: non referralManager call`, async function() {
      const qualifiedNonce = 5;
      const tokensPerCredit = toWei('250');

      await expectRevert(
        token.redeemTokens(
          someone,
          qualifiedNonce,
          tokensPerCredit,
          plasmaBridge.address, {
            from: someone
          }
        ),
        'msg.sender is not referralManager'
      );
    });

  });

});
