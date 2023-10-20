// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract BlacklistableUpgradable is Initializable {
    mapping(address => bool) internal blacklistedAddresses;

    function __ERC20Blacklistable_init() internal onlyInitializing {}

    function __ERC20Blacklistable_init_unchained() internal onlyInitializing {}

    /**
     * @dev Emitted when an `account` is blacklisted.
     */
    event Blacklisted(address account);

    /**
     * @dev Emitted when an `account` is removed from the blacklist.
     */
    event UnBlacklisted(address account);

    /**
     * @dev Throws if argument account is blacklisted
     * @param account The address to check
     */
    modifier notBlacklisted(address account) {
        require(!blacklistedAddresses[account], "Blacklistable: account is blacklisted");
        _;
    }

    /**
     * @dev Checks if account is blacklisted
     * @param account The address to check
     */
    function isBlacklisted(address account) public view returns (bool) {
        return blacklistedAddresses[account];
    }

    /**
     * @dev Adds account to blacklist
     * @param account The address to blacklist
     */
    function _blacklist(address account) internal virtual {
        blacklistedAddresses[account] = true;
        emit Blacklisted(account);
    }

    /**
     * @dev Removes account from blacklist
     * @param account The address to remove from the blacklist
     */
    function _unBlacklist(address account) internal virtual {
        blacklistedAddresses[account] = false;
        emit UnBlacklisted(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}