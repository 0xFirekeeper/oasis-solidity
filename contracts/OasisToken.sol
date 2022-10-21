// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

/**
 * @author  . 0xFirekeeper
 * @title   . Oasis Token
 * @notice  . Standard ERC-20 for the Oasis. Mintable by assigned Minters or by burning a Crazy Camels NFT.
 */

contract OasisToken is ERC20, Ownable, ReentrancyGuard {
    /// STATE VARIABLES ///

    address public crazyCamels;
    address public oasisGraveyard;
    uint256 public tokensPerCrazyCamel;
    mapping(address => bool) public minter;

    /// EVENTS ///

    event ClaimedOST(address indexed claimer, uint256 ostAmount, uint256[] ccIds);

    /// CONSTRUCTOR ///

    constructor() ERC20("Oasis Token", "OST") {}

    /// OWNER FUNCTIONS ///

    function setStateVariables(
        address _crazyCamels,
        address _oasisGraveyard,
        uint256 _tokensPerCrazyCamel
    ) external onlyOwner nonReentrant {
        crazyCamels = _crazyCamels;
        oasisGraveyard = _oasisGraveyard;
        tokensPerCrazyCamel = _tokensPerCrazyCamel;
    }

    function addMinter(address _minter) external onlyOwner nonReentrant {
        minter[_minter] = true;
    }

    function removeMinter(address _minter) external onlyOwner nonReentrant {
        minter[_minter] = false;
    }

    /// MINTER FUNCTIONS ///

    function mint(address _to, uint256 _amount) external nonReentrant {
        require(minter[msg.sender], "Must be an assigned Minter");

        _mint(_to, _amount);
    }

    /// USER FUNCTIONS ///

    function claim(uint256[] memory _tokenIds) external nonReentrant {
        require(_tokenIds.length > 0, "Must burn at least one Crazy Camel");

        for (uint256 i = 0; i < _tokenIds.length; i++)
            IERC721(crazyCamels).transferFrom(msg.sender, oasisGraveyard, _tokenIds[i]);

        _mint(msg.sender, _tokenIds.length * tokensPerCrazyCamel);

        emit ClaimedOST(msg.sender, _tokenIds.length * tokensPerCrazyCamel, _tokenIds);
    }
}
