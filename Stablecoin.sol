// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./BlacklistableUpgradable.sol";

contract Stablecoin is
    Initializable,            // Used for contract initialization purposes.
    ContextUpgradeable,       // Provides basic functionality from the Context contract.
    ERC20Upgradeable,         // Represents an upgradeable ERC20 token.
    PausableUpgradeable,      // Provides functionality to pause and unpause the contract.
    AccessControlUpgradeable, // Manages access roles for the contract.
    ERC20PermitUpgradeable,   // ERC20 token with a permit function (off-chain approval).
    BlacklistableUpgradable   // Allows certain addresses to be blacklisted.
{
    // Define constants for various roles using the keccak256 hash of the role names.
    bytes32 public constant BLACKLIST_ROLE = keccak256("BLACKLIST_ROLE");
    bytes32 public constant PAUSE_ROLE = keccak256("PAUSE_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with default settings and roles.
     * @param _admin The address to be granted initial roles.
     */
    function initialize(address _admin) public initializer {
        string memory name = "Forte AUD";
        __ERC20_init(name, "AUDF");
        __Pausable_init();
        __AccessControl_init();
        __ERC20Permit_init(name);
        __ERC20Blacklistable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(BLACKLIST_ROLE, _admin);
        _grantRole(PAUSE_ROLE, _admin);
        _grantRole(MINT_ROLE, _admin);
    }

    /**
     * @dev Returns the number of decimals the token uses.
     * @return uint8 Number of decimals.
     */
    function decimals() public view virtual override returns (uint8) {
        return 2;
    }

    /**
     * @dev Hook that is called before any token transfer, ensuring transfers are not paused or between blacklisted addresses.
     * @param from The sender's address.
     * @param to The recipient's address.
     * @param amount Amount of tokens being transferred.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused notBlacklisted(from) notBlacklisted(to) {
        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     * Can only be called by an account with the PAUSE_ROLE.
     */
    function pause() public onlyRole(PAUSE_ROLE) {
        _pause();
    }

    /**
     * @dev Resumes all token transfers.
     * Can only be called by an account with the PAUSE_ROLE.
     */
    function unpause() public onlyRole(PAUSE_ROLE) {
        _unpause();
    }

    /**
     * @dev Blacklists an account, preventing it from participating in token transfers.
     * Can only be called by an account with the BLACKLIST_ROLE.
     * @param _account Address to be blacklisted.
     */
    function blacklist(address _account) public onlyRole(BLACKLIST_ROLE) {
        _blacklist(_account);
    }

    /**
     * @dev Removes an account from the blacklist.
     * Can only be called by an account with the BLACKLIST_ROLE.
     * @param _account Address to be removed from the blacklist.
     */
    function unBlacklist(address _account) public onlyRole(BLACKLIST_ROLE) {
        _unBlacklist(_account);
    }

    /**
     * @dev Mints tokens to the caller's address.
     * Can only be called by an account with the MINT_ROLE.
     * @param _amount Amount of tokens to mint.
     */
    function mint(uint256 _amount) public onlyRole(MINT_ROLE) {
        _mint(_msgSender(), _amount);
    }

    /**
     * @dev Mints tokens to a specified address.
     * Can only be called by an account with the MINT_ROLE.
     * @param _account Address to mint token tos.
     * @param _amount Amount of tokens to mint.
     */
    function mint(address _account, uint256 _amount) public onlyRole(MINT_ROLE) {
        _mint(_account, _amount);
    }

    /**
     * @dev Burns tokens from the caller's address.
     * Can only be called by an account with the MINT_ROLE.
     * @param _amount Amount of tokens to burn.
     */
    function burn(uint256 _amount) public onlyRole(MINT_ROLE) {
        _burn(_msgSender(), _amount);
    }

    /**
     * @dev Burns tokens from a specified address, assuming they have the required allowance.
     * Can only be called by an account with the MINT_ROLE.
     * @param _account Address to burn tokens from.
     * @param _amount Amount of tokens to burn.
     */
    function burn(address _account, uint256 _amount) public onlyRole(MINT_ROLE) {
        _spendAllowance(_account, _msgSender(), _amount);
        _burn(_account, _amount);
    }
}
