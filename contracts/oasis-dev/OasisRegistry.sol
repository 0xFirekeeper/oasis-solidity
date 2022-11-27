// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  ==========  EXTERNAL IMPORTS    ==========

import "@openzeppelin/contracts/access/Ownable.sol";

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
 * @title   OasisRegistry - Updated Registry of the contracts used by the Oasis.
 * @notice  This contract is used to fetch the latest contract addresses for scalability.
 */

contract OasisRegistry is Ownable, IOasisRegistry {
    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error ZeroAddress();

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public immutable evolvedCamels;
    address public immutable crazyCamels;
    address public immutable oasisGraveyard;

    address public oasisTreasury;
    address public oasisStakingToken;
    address public oasisMint;
    address public oasisToken;
    address public oasisShop;
    address public oasisStake;
    address public oasisMarketplace;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event OasisTreasuryUpdated(address indexed oldOasisTreasury, address indexed newOasisTreasury);
    event OasisStakingTokenUpdated(address indexed oldOasisStakingToken, address indexed newOasisStakingToken);
    event OasisTokenUpdated(address indexed oldOasisToken, address indexed newOasisToken);
    event OasisShopUpdated(address indexed oldOasisShop, address indexed newOasisShop);
    event OasisStakeUpdated(address indexed oldOasisStake, address indexed newOasisStake);
    event OasisMarketplaceUpdated(address indexed oldOasisMarketplace, address indexed newOasisMarketplace);

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _evolvedCamels, address _crazyCamels, address _oasisGraveyard) {
        evolvedCamels = _evolvedCamels;
        crazyCamels = _crazyCamels;
        oasisGraveyard = _oasisGraveyard;
    }

    /*///////////////////////////////////////////////////////////////
                                OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setOasisTreasury(address _oasisTreasury) external onlyOwner {
        if (_oasisTreasury == address(0)) revert ZeroAddress();

        emit OasisTreasuryUpdated(oasisTreasury, _oasisTreasury);
        oasisTreasury = _oasisTreasury;
    }

    function setStakingToken(address _oasisStakingToken) external onlyOwner {
        if (_oasisStakingToken == address(0)) revert ZeroAddress();

        emit OasisStakingTokenUpdated(oasisStakingToken, _oasisStakingToken);
        oasisStakingToken = _oasisStakingToken;
    }

    function setOasisToken(address _oasisToken) external onlyOwner {
        if (_oasisToken == address(0)) revert ZeroAddress();

        emit OasisTokenUpdated(oasisToken, _oasisToken);
        oasisToken = _oasisToken;
    }

    function setOasisShop(address _oasisShop) external onlyOwner {
        if (_oasisShop == address(0)) revert ZeroAddress();

        emit OasisShopUpdated(oasisShop, _oasisShop);
        oasisShop = _oasisShop;
    }

    function setOasisStake(address _oasisStake) external onlyOwner {
        if (_oasisStake == address(0)) revert ZeroAddress();

        emit OasisStakeUpdated(oasisStake, _oasisStake);
        oasisStake = _oasisStake;
    }

    function setOasisMarketplace(address _oasisMarketplace) external onlyOwner {
        if (_oasisMarketplace == address(0)) revert ZeroAddress();

        emit OasisMarketplaceUpdated(oasisMarketplace, _oasisMarketplace);
        oasisMarketplace = _oasisMarketplace;
    }
}
