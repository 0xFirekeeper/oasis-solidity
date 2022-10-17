// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@thirdweb-dev/contracts/extension/ContractMetadata.sol";

/// @title User Database and Creation for The-Oasis
/// @author 0xFirekeeper
/// @notice The-Oasis is my Unity-based project using Web3
/// @dev Just testing thirdweb
contract OasisUser is Ownable, ContractMetadata {
    address public deployer;

    constructor() {
        deployer = _msgSender();
    }

    /// @dev This function returns who is authorized to set the metadata for the contract
    function _canSetContractURI()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return _msgSender() == deployer;
    }

    mapping(address => User) allUsers;

    event UserCreated(address indexed account, string name);
    event UserDeleted(address indexed account);

    struct User {
        bool registered;
        string name;
    }

    /// @dev Create new user and store in mapping
    function createUser(string memory _name) external {
        address account = _msgSender();

        require(
            !allUsers[account].registered,
            "You have already created an account!"
        );

        allUsers[account] = User(true, _name);

        emit UserCreated(account, _name);
    }

    /// @dev Delete registered user by resetting mapping values
    function deleteUser() external {
        address account = _msgSender();

        require(allUsers[account].registered, "You are not registered!");

        allUsers[account].registered = false;
        allUsers[account].name = "";

        emit UserDeleted(account);
    }

    /// @dev Returns registered user information from stored mapping/struct for specified account
    function getUser(address _account)
        external
        view
        returns (bool _registered, string memory _name)
    {
        address account = _account;

        require(allUsers[account].registered, "You are not registered!");

        return (allUsers[account].registered, allUsers[account].name);
    }

    /// @dev Create new user and store in mapping for specified account
    function _createUser(address _account, string memory _name)
        external
        onlyOwner
    {
        address account = _account;

        require(
            !allUsers[account].registered,
            "You have already created an account!"
        );

        allUsers[account] = User(true, _name);

        emit UserCreated(account, _name);
    }

    /// @dev Delete registered user by resetting mapping values for specified account
    function _deleteUser(address _account) external onlyOwner {
        address account = _account;

        require(allUsers[account].registered, "You are not registered!");

        allUsers[account].registered = false;
        allUsers[account].name = "";

        emit UserDeleted(account);
    }
}
