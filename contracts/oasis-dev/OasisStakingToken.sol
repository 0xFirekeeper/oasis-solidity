// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  ==========  EXTERNAL IMPORTS    ==========

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

//  ==========  INTERNAL IMPORTS    ==========

import "../interfaces/IOasisRegistry.sol";

/*///////////////////////////////////////
/////////╭━━━━┳╮╱╱╱╱╱╭━━━╮///////////////
/////////┃╭╮╭╮┃┃╱╱╱╱╱┃╭━╮┃///////////////
/////////╰╯┃┃╰┫╰━┳━━╮┃┃╱┃┣━━┳━━┳┳━━╮/////
/////////╱╱┃┃╱┃╭╮┃┃━┫┃┃╱┃┃╭╮┃━━╋┫━━┫/////
/////////╱╱┃┃╱┃┃┃┃┃━┫┃╰━╯┃╭╮┣━━┃┣━━┃/////
/////////╱╱╰╯╱╰╯╰┻━━╯╰━━━┻╯╰┻━━┻┻━━╯/////
///////////////////////////////////////*/

/**
 * @author  0xFirekeeper
 * @title   OasisOwnerToken - Placeholder token used by OasisStake.
 * @notice  Conditionally transferrable ERC-20 awarded 1:1 for each Evolved Camels staked in the Oasis.
 */

contract OasisStakingToken is ERC20, Ownable {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Error for if transfer conditions are unmet.
    error Soulbound();

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice OasisRegistry contract address.
    IOasisRegistry public oasisRegistry;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  ERC20 Constructor for OasisStakingToken (OSST).
     * @param   _oasisRegistry  Address of the OasisRegistry contract.
     */
    constructor(IOasisRegistry _oasisRegistry) ERC20("OasisStakingToken", "OSST") {
        oasisRegistry = _oasisRegistry;
    }

    /*///////////////////////////////////////////////////////////////
                                TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Only allow transfers if Zero Address or OasisStake contract.
     * @param   _from  Address to transfer '_amount' from.
     * @param   _to  Address to transfer '_amount' to.
     * @param   _amount  Amount of tokens to transfer.
     */
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        address oasisStake = oasisRegistry.oasisStake();
        if (_from == address(0) || _from == oasisStake || _to == oasisStake)
            super._beforeTokenTransfer(_from, _to, _amount);
        else revert Soulbound();
    }

    /*///////////////////////////////////////////////////////////////
                                OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Mint any amount to any address.
     * @dev     Owner only.
     * @param   _to  Address to mint '_amount' to.
     * @param   _amount  Amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    /**
     * @notice  Sets the OasisRegistry contract address.
     * @dev     Owner only.
     * @param   _oasisRegistry  Address of the OasisRegistry.
     */
    function setOasisRegistry(IOasisRegistry _oasisRegistry) public onlyOwner {
        oasisRegistry = _oasisRegistry;
    }
}
