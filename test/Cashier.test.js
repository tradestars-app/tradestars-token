const { accounts, contract } = require('@openzeppelin/test-environment')

const {
  BN, // big number
  time, // time helpers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers')

const { balanceSnap, etherSnap } = require('./helpers/balanceSnap')
const { toWei, toHex } = require('web3-utils')

const Cashier = contract.fromArtifact('Cashier')
const SafeDelegate = contract.fromArtifact('SafeDelegate')

const ERC20Mock = contract.fromArtifact('ERC20Mock')
const ERC20MockBurnable = contract.fromArtifact('ERC20MockBurnable')

/// Matic pos
const Bridge = contract.fromArtifact('BridgeMock')

/// UniswapConvert implementation
const UniswapManager = contract.fromArtifact('UniswapManager')
const UniswapRouterMock = contract.fromArtifact('UniswapRouterMock')

// gnosis mock
const MockContract = contract.fromArtifact('MockContract')

const expect = require('chai')
  .use(require('bn-chai')(BN))
  .expect


describe('Cashier', function () {
  const [owner, someone, anotherOne ] = accounts

  before(async function () {
    /// create a mock tokens
    this.currencyToken = await ERC20Mock.new({ from: owner })
    this.reserveToken = await ERC20Mock.new({ from: owner })
    this.bridgedToken = await ERC20MockBurnable.new({ from: owner })

    /// Mock L2 Bridge
    this.bridge = await Bridge.new({ from: owner })

    /// Create a Uniswap Converter with mock router
    this.uniswapRouterMock = await UniswapRouterMock.new({ from: owner })

    this.swapManager = await UniswapManager.new(
      this.uniswapRouterMock.address, { from: owner }
    )

    // link safedelegate lib
    const safeDelegate = await SafeDelegate.new({ from: owner })
    await Cashier.detectNetwork()
    await Cashier.link('SafeDelegate', safeDelegate.address)

    /// Cashier
    this.cashier = await Cashier.new(
      this.bridge.address,
      this.reserveToken.address,
      this.bridgedToken.address,
      this.swapManager.address, {
        from: owner
      }
    )

    // save blocktime
    this.blockTime = await time.latest();
  })

  /// admin base uri
  describe('deposit tests', function () {

    before(async function() {
      // send eth and tokens to the uniswap mock
      await this.uniswapRouterMock.send(toWei('10'))
      await this.reserveToken.mint(this.uniswapRouterMock.address, toWei('1000'))
    })

    it('Deposit w/Ether', async function () {
      const amount = new BN( toWei('1') )
      const exchangedtoStableAmount = await this.uniswapRouterMock
        .calcTokensPerEther(amount)

      // balance trackers.

      const userTracker = await etherSnap(someone, 'user')
      const swapPoolTracker = await etherSnap(this.uniswapRouterMock.address, 'swapPool')

      const bTokensTracker = await balanceSnap(
        this.bridgedToken,
        this.bridge.address,
        'bTokens in bridge'
      )

      const rTokensTracker = await balanceSnap(
        this.reserveToken,
        this.cashier.address,
        'rTokens in cashier'
      )

      ////

      const tx = await this.cashier.methods['deposit()']({
        value: amount,
        from: someone,
        gasPrice: 0 // note
      });

      // console.log('[GAS] ::', tx.receipt.gasUsed)

      expect(tx.receipt.gasUsed).to.be.lt.BN(160000)
      expectEvent(tx, 'BridgeDeposit')

      /// check balances
      await userTracker.requireDecrease(amount)
      await swapPoolTracker.requireIncrease(amount)

      // check bTokens tokens in the L2 bridge
      await bTokensTracker.requireIncrease(exchangedtoStableAmount)

      // check rTokens tokens in the lending pool
      await rTokensTracker.requireIncrease(exchangedtoStableAmount)
    })

    it('Deposits w/ERC20', async function () {
      const amount = new BN( toWei('1') )

      const rTokensTracker = await balanceSnap(
        this.reserveToken,
        this.cashier.address,
        'rTokens in cashier'
      )

      const bTokensTracker = await balanceSnap(
        this.bridgedToken,
        this.bridge.address,
        'bTokens in bridge'
      )

      // Mint currencyToken to buyer
      await this.currencyToken.mint(someone, amount);

      // Allow
      await this.currencyToken.approve(
        this.cashier.address,
        amount, {
          from: someone
        }
      )

      const tx = await this.cashier.deposit(
        this.currencyToken.address,
        amount, {
          from: someone
        }
      )

      // console.log('[GAS] ::', tx.receipt.gasUsed)

      expect(tx.receipt.gasUsed).to.be.lt.BN(140000)
      expectEvent(tx, 'BridgeDeposit')

      /// check balances mapped and bridged
      await rTokensTracker.requireIncrease(amount)
      await bTokensTracker.requireIncrease(amount)
    })

    it('Deposits w/ReserveToken', async function () {
      const amount = new BN( toWei('1') )

      // Mint reserveToken to buyer
      await this.reserveToken.mint(someone, amount);

      // Allow
      await this.reserveToken.approve(
        this.cashier.address,
        amount, {
          from: someone
        }
      )

      const tx = await this.cashier.deposit(
        this.reserveToken.address,
        amount, {
          from: someone
        }
      )

      // console.log('[GAS] ::', tx.receipt.gasUsed)

      expect(tx.receipt.gasUsed).to.be.lt.BN(70000)
      expectEvent(tx, 'BridgeDeposit')
    })
  })

  describe('Withdraw tests', function () {

    it('Changed withdraw OK', async function () {

      // trick the mock bridge use this param
      const burnProof = this.bridgedToken.address

      const cashierBalance = await balanceSnap(
        this.reserveToken,
        this.cashier.address,
        'reserveTokens in cashier'
      )
      const userBalance = await balanceSnap(
        this.reserveToken,
        someone,
        'reserveTokens in someone'
      )

      // check amount available to redeem
      const amount = await this.reserveToken.balanceOf(
        this.cashier.address
      );

      const tx = await this.cashier.withdraw(
        this.reserveToken.address,
        burnProof, { ///
          from: someone
        }
      )

      expectEvent(tx, 'BridgeExit')

      await userBalance.requireIncrease(amount)
      await cashierBalance.requireDecrease(amount)
    })
  })
})
