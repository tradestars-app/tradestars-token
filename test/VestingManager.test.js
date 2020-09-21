const { accounts, contract } = require('@openzeppelin/test-environment')
// const { deployProxy } = require('@openzeppelin/truffle-upgrades');

const {
  BN,
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers')

const { toWei } = require('web3-utils')

const TSToken = contract.fromArtifact('TSToken');
const VestingManager = contract.fromArtifact('VestingManager');

const expect = require('chai')
  .use(require('bn-chai')(BN))
  .expect

describe('VestingManager', function () {
  const [owner, notOwner, party1, party2, party3, party4, party5, party6, party7] = accounts

  let vestingManager;
  let token;

  const vestingTeamTokens = toWei('500000000');
  const vestingPerParty = toWei('100000000'); // 5 parties
  const vestingStart = new Date().getTime();
  const cliffDuration = 0;
  const vestingDuration = 60 * 60 * 24 * 365;

  before(async function() {
    /// Create TS Token
    // token = await deployProxy(TSToken, {
    //   initMethod: 'initialize',
    //   initArgs: [owner]
    // });

    /// Create Vesting Manager
    // vestingManager = await deployProxy(VestingManager, {
    //   initMethod: 'initialize',
    //   initArgs: [owner, token.address]
    // });

    // create the TS token as non-upgradedable
    token = await TSToken.new({ from: owner })
    await token.initialize({ from: owner })

    // create the vestingManager as non-upgradedable
    vestingManager = await VestingManager.new({ from: owner })
    await vestingManager.initialize(token.address, { from: owner })

    /// Lock in tokens in Vesting Manager.
    await token.mint(vestingManager.address, vestingTeamTokens, {
      from: owner
    });
  });

  async function createVesting(vestingBeneficiary, sender) {
    return vestingManager.add(
      vestingPerParty,
      vestingBeneficiary,
      vestingStart,
      cliffDuration,
      vestingDuration,
      true, {
        from: sender,
      }
    );
  }

  describe('Positive Tests', function() {

    it(`should OK createVesting()`, async function() {
      const tx = await createVesting(party1, owner);
      expectEvent(tx, "BeneficiaryAdded");
    });

    it(`should OK lockedInTokens()`, async function() {
      const locked = await vestingManager.lockedInTokens();

      expect(locked).to.be.eq.BN(`${vestingTeamTokens}`);
    });

    it(`Should OK availableTokens()`, async function() {
      const available = await vestingManager.availableTokens();
      expect(available).to.be.eq.BN(
        new BN(vestingTeamTokens).sub(
          new BN(vestingPerParty)
        )
      );
    });

    it(`Should OK getVestingContracts()`, async function() {
      const contracts = await vestingManager.getVestingContracts();
      expect(contracts).to.be.an('array').with.lengthOf(1);
    });

    it(`Should OK vestingContract()`, async function() {
      await vestingManager.vestingContract(party1);
    });

    it(`should OK revoke()`, async function() {
      const tx = await vestingManager.revoke(party1, {
        from: owner
      });
      expectEvent(tx, "BeneficiaryRevoked");

      const available = await vestingManager.availableTokens();
      expect(available).to.be.eq.BN(`${vestingTeamTokens}`);
    });

    it(`Should OK availableTokens()`, async function() {
      const available = await vestingManager.availableTokens();
      expect(available).to.be.eq.BN(`${vestingTeamTokens}`);
    });

    it(`should OK createVesting() :: 5 vestors [p2...p6]`, async function() {
      for (let party of [party2, party3, party4, party5, party6]) {
        await createVesting(party, owner);
      }

      const available = await vestingManager.availableTokens();
      expect(available).to.be.eq.BN('0');
    });

  });

  describe('Negative Tests', function() {

    it(`should FAIL createVesting() :: not owner`, async function() {
      await expectRevert(
        createVesting(party1, notOwner),
        'Ownable: caller is not the owner'
      );
    });

    it(`should FAIL createVesting() :: no tokens left`, async function() {
      await expectRevert(
        createVesting(party7, owner),
        'VestingManager: not enought balance'
      );
    });

    it(`should FAIL createVesting() :: allready vesting`, async function() {
      /// mint some tokens

      await token.mint(vestingManager.address, vestingPerParty, {
        from: owner
      });

      await expectRevert(
        createVesting(party1, owner),
        'VestingManager: beneficiary already added'
      );
    });

  });
});
