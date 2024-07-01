// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title WildCoinERC20 Token Contract
/// @notice ERC20 token with a transfer fee, minting cap, and owner control
/// @dev Extends the OpenZeppelin ERC20, ERC20Burnable and Ownable contracts
contract WildCoin is ERC20, ERC20Burnable, Ownable {
    uint256 public constant MAX_FEE = 50; // Maximum fee is 0.5%
    uint256 public constant MAX_SUPPLY = 100_000_000_000 * 10 ** 18; // Maximum supply is 100 billion tokens
    uint256 public constant INITIAL_MINTABLE_SUPPLY = 50_000_000_000 * 10 ** 18; // Initially mintable supply is 50 billion tokens
    uint256 public BASIS_POINT_DIVISOR = 10000; // Basis point divisor
    uint256 public feePercentage = 30; // Default fee is 0.3%
    bool public canMintMore; // Initially, only 50 billion can be minted

    // Errors
    error ExceedsMintingAllowance(
        uint256 mintedSupply,
        uint256 attemptedMint,
        uint256 maxMintable
    );
    error TransferAmountExceedsAllowance(
        uint256 allowance,
        uint256 attemptedTransfer
    );

    // Events
    event FeePercentageChanged(uint256 indexed newFeePercentage);
    event FullMintingEnabled();

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) Ownable(msg.sender) {}

    /// @notice Mints new tokens, respecting the initial and total supply limits
    /// @param _recipient The recipient of tokens
    /// @param _amount The amount of tokens to mint
    function mint(address _recipient, uint256 _amount) external onlyOwner {
        // Capped to INITIAL_MINTABLE_SUPPLY = 50bn
        if (!canMintMore && totalSupply() + _amount > INITIAL_MINTABLE_SUPPLY) {
            revert ExceedsMintingAllowance(
                totalSupply(),
                _amount,
                INITIAL_MINTABLE_SUPPLY
            );
        }

        // Capped to MAX_SUPPLY = 100bn
        if (canMintMore && totalSupply() + _amount > MAX_SUPPLY) {
            revert ExceedsMintingAllowance(totalSupply(), _amount, MAX_SUPPLY);
        }

        _mint(_recipient, _amount);
    }

    /// @notice Transfers tokens with a fee mechanism
    /// @dev Internal function to handle token transfer with fee deduction
    /// @param _from The address sending the tokens
    /// @param _to The address receiving the tokens
    /// @param _value The amount of tokens being transferred
    function _update(
        address _from,
        address _to,
        uint256 _value
    ) internal virtual override {
        // take fee
        uint256 fee = (_value * feePercentage) / BASIS_POINT_DIVISOR;
        uint256 sendAmount = _value - fee;

        super._update(_from, _to, sendAmount);

        if (fee > 0) {
            super._update(_from, owner(), fee);
        }
    }

    /// @notice Sets the fee percentage for transfers
    /// @param _newFee The new fee percentage in basis points (1/100 of a percent)
    function setFeePercentage(uint256 _newFee) external onlyOwner {
        feePercentage = _newFee > MAX_FEE ? MAX_FEE : _newFee;
        emit FeePercentageChanged(feePercentage);
    }

    /// @notice Enables the minting of the remaining supply beyond the initial mintable supply
    function enableFullMinting() external onlyOwner {
        canMintMore = true;
        emit FullMintingEnabled();
    }
}
