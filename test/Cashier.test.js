const { accounts, contract } = require('@openzeppelin/test-environment')

const {
  BN, // big number
  time, // time helpers
  expectEvent, // Assertions for emitted events
  expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers')

const { toWei } = require('web3-utils')

const Cashier = contract.fromArtifact('Cashier')

const Reserve = contract.fromArtifact('MockContract');
const Bridge = contract.fromArtifact('MockContract');
const BridgedToken = contract.fromArtifact('MockContract');

/// CompoundMock implementation
const ReserveManager = contract.fromArtifact('MockContract');

/// UniswapConvert implementation
const UniswapConverter = contract.fromArtifact('UniswapConverter');
const UniswapRouterMock = contract.fromArtifact('UniswapRouterMock');

require('chai').should()

describe('Cashier', function () {
  const [owner, someone, anotherOne ] = accounts

  before(async function () {
    /// create a mocks as currency
    this.reserve = await Reserve.new({ from: owner })
    this.bridge = await Bridge.new({ from: owner })
    this.bridgedToken = await BridgedToken.new({ from: owner })

    /// Create a Uniswap Converter with mock router
    const uniswapRouterMock = await UniswapRouterMock.new({ from: owner })

    this.tokenConverter = await UniswapConverter.new(
      uniswapRouterMock.address, { from: owner }
    )

    /// Create a Compound Reserve Manager
    this.reserveManager = await ReserveManager.new({ from: owner })

    /// Cashier
    this.cashier = await Cashier.new(
      this.bridge.address,
      this.reserve.address,
      this.bridgedToken.address,
      this.tokenConverter.address,
      this.reserveManager.address, {
        from: owner
      }
    )
    this.blockTime = await time.latest();
  })

  /// admin base uri
  describe('deposit tests', function () {

    it('Deposit Ether tests', async function () {
      const amount = toWei('1')

      const receipt = await this.cashier.methods['deposit()']({
        value: amount,
        from: someone
      });

      expectEvent(receipt, 'BridgeDeposit')
    })
  })
})
