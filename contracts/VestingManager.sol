pragma solidity ^0.5.0;

import "openzeppelin-eth/contracts/drafts/TokenVesting.sol";
import "openzeppelin-eth/contracts/token/ERC20/SafeERC20.sol";

/**
 * @title VestingManager
 * @dev Manager for ERC20 token vesting plan.
 */
contract VestingManager is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event BeneficiaryAdded(address beneficiary, uint256 amount);
    event BeneficiaryRevoked(address beneficiary);

    /// Token registry
    IERC20 _vestingToken;

    /// Array of available vesting contracts
    TokenVesting[] private _vestingContractsArr;

    /// Vesting Map
    mapping (address => TokenVesting) private _vestingContractsMap;

    function initialize(address _sender, IERC20 _token) public initializer {
        Ownable.initialize(_sender);
        _vestingToken = _token;
    }

    /**
     * @dev Add a new beneficiary to the vesting plan.
     * @param amount of tokens to vest
     * @param beneficiary address of the vesting plan
     * @param start in unix timestamp of the vesting plan
     * @param cliffDuration in unix timestamp of the cliff period
     * @param duration in unix timestamp of the vesting period
     * @param revocable true if the vesting is revocable
     */
    function add(
        uint256 amount,
        address beneficiary,
        uint256 start,
        uint256 cliffDuration,
        uint256 duration,
        bool revocable
    )
        external onlyOwner
    {
        require(_vestingToken.balanceOf(address(this)) >= amount, "not enought balance");
        require(_vestingContractsMap[beneficiary] == TokenVesting(0), "beneficiary already added");

        // Create a vesting contract for the beneficiary
        TokenVesting vestingContract = new TokenVesting();

        vestingContract.initialize(
            beneficiary,
            start,
            cliffDuration,
            duration,
            revocable,
            address(this)
        );

        // Transfer Tokens to vesting contract of the beneficiary
        _vestingToken.safeTransfer(address(vestingContract), amount);

        // Add to manager
        _vestingContractsMap[beneficiary] = vestingContract;
        _vestingContractsArr.push(vestingContract);

        emit BeneficiaryAdded(beneficiary, amount);
    }

    /**
     * @param beneficiary to revoke tokens
     */
    function revoke(address beneficiary) external onlyOwner {
        _vestingContractsMap[beneficiary].revoke(_vestingToken);

        emit BeneficiaryRevoked(beneficiary);
    }

    /**
     * @return the total amount of locked in tokens for vesting
     */
    function lockedInTokens() external view returns (uint256) {
        uint256 totalAmount = _vestingToken.balanceOf(address(this));

        for (uint256 x = 0; x < _vestingContractsArr.length; x++) {
            TokenVesting vestingContract = _vestingContractsArr[x];

            /// Get token locked in this contract.
            uint256 balance = _vestingToken.balanceOf(
                address(vestingContract)
            );

            /// add to total counter
            totalAmount = totalAmount.add(balance);
        }

        return totalAmount;
    }

    /**
     * @return the amount of available tokens for vesting plan left.
     */
    function availableTokens() external view returns (uint256) {
        return _vestingToken.balanceOf(address(this));
    }

    /**
     * @param beneficiary to query for
     * @return the vesting contract for the beneficiary of the tokens.
     */
    function vestingContract(address beneficiary) external view returns (TokenVesting) {
        return _vestingContractsMap[beneficiary];
    }

    /**
     * @return the vesting contracts added to the plan
     */
    function getVestingContracts() external view returns (TokenVesting[] memory) {
        return _vestingContractsArr;
    }
}