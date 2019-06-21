import { TestHelper } from 'zos';
import { assertRevert, Contracts, ZWeb3 } from 'zos-lib';
import { toWei, BN } from 'web3-utils';

ZWeb3.initialize(web3.currentProvider);

require('chai').should();

/// Test for events.

function checkBeneficiaryAdded(log) {
  log.event.should.be.eq('BeneficiaryAdded');
}

function checkBeneficiaryRevoked(log) {
  log.event.should.be.eq('BeneficiaryRevoked');
}

const TSToken = Contracts.getFromLocal('TSToken');
const VestingManager = Contracts.getFromLocal('VestingManager');

contract('VestingManager', ([_, owner, notOwner, party1, party2, party3, party4, party5, party6, party7]) => {

  let vestingManager;
  let token;

  const vestingTeamTokens = 500000000;
  const vestingPerParty = 100000000; // 5 parties
  const vestingStart = new Date().getTime();
  const cliffDuration = 0;
  const vestingDuration = 60 * 60 * 24 * 365;

  before(async function() {
    const project = await TestHelper();

    /// Create TS Token
    token = await project.createProxy(TSToken, {
      initMethod: 'initialize',
      initArgs: [owner]
    });

    /// Create Vesting Manager
    vestingManager = await project.createProxy(VestingManager, {
      initMethod: 'initialize',
      initArgs: [owner, token.address]
    });

    /// Lock in tokens in Vesting Manager.
    await token.methods.mint(vestingManager.address, vestingTeamTokens).send({
      from: owner,
      gas: 6721975
    });
  });

  async function createVesting(vestingBeneficiary, sender) {
    return vestingManager.methods.add(
      vestingPerParty,
      vestingBeneficiary,
      vestingStart,
      cliffDuration,
      vestingDuration,
      true
    )
    .send({
      from: sender,
      gas: 6721975
    });
  }

  describe('Positive Tests', function() {

    it(`should OK createVesting()`, async function() {
      const tx = await createVesting(party1, owner);
      checkBeneficiaryAdded(tx.events.BeneficiaryAdded);
    });

    it(`should FAIL createVesting() :: not owner`, async function() {
      await assertRevert(
        createVesting(party1, notOwner)
      );
    });

    it(`should FAIL createVesting() :: allreary vesting`, async function() {
      await assertRevert(
        createVesting(party1, owner)
      );
    });

    it(`should OK lockedInTokens()`, async function() {
      const locked = await vestingManager.methods.lockedInTokens().call();
      locked.should.be.eq(`${vestingTeamTokens}`);
    });

    it(`Should OK availableTokens()`, async function() {
      const available = await vestingManager.methods.availableTokens().call();
      available.should.be.eq(`${vestingTeamTokens - vestingPerParty}`);
    });

    it(`Should OK getVestingContracts()`, async function() {
      const contracts = await vestingManager.methods.getVestingContracts().call();
      contracts.should.be.an('array').with.lengthOf(1);
    });

    it(`Should OK vestingContract()`, async function() {
      await vestingManager.methods.vestingContract(party1).call();
    });

    it(`should OK revoke()`, async function() {
      const tx = await vestingManager.methods.revoke(party1).send({
        from: owner,
        gas: 6721975
      });
      checkBeneficiaryRevoked(tx.events.BeneficiaryRevoked);
    });

    it(`Should OK availableTokens()`, async function() {
      const available = await vestingManager.methods.availableTokens().call();
      available.should.be.eq(`${vestingTeamTokens}`);
    });

    it(`should OK createVesting() :: 5 vestors [p2...p6]`, async function() {
      for (let party of [party2, party3, party4, party5, party6]) {
        await createVesting(party, owner);
      }

      const available = await vestingManager.methods.availableTokens().call();
      available.should.be.eq('0');
    });

    it(`should FAIL createVesting() :: no tokens left`, async function() {
      await assertRevert(
        createVesting(party7, owner)
      );
    });

    it(`should OK revoke() :: 5 vestors [p2...p6]`, async function() {
      for (let party of [party2, party3, party4, party5, party6]) {
        await vestingManager.methods.revoke(party).send({
          from: owner,
          gas: 6721975
        });
      }
      const available = await vestingManager.methods.availableTokens().call();
      available.should.be.eq(`${vestingTeamTokens}`);
    });

  });

});