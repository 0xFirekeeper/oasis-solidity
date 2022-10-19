// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract OasisToken is ERC20, Ownable, ReentrancyGuard {
    /// STATE VARIABLES ///

    uint256 public tokensPerCrazyCamel;
    address public crazyCamels;
    address public oasisGraveyard;

    /// EVENTS ///

    event ClaimedOST(address indexed claimer, uint256 indexed ostAmount, uint256[] ccIds);

    /// CONSTRUCTOR ///

    constructor() ERC20("OasisToken", "OST") {}

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

    function mint(address to, uint256 amount) public onlyOwner nonReentrant {
        _mint(to, amount);
    }

    /// EXTERNAL FUNCTIONS ///

    function claim(uint256[] memory tokenIds) external nonReentrant {
        uint256 burnAmount = tokenIds.length;
        if (burnAmount < 1) revert("Must burn at least 1 token");

        for (uint256 i = 0; i < burnAmount; i++)
            if (IERC721(crazyCamels).getApproved(tokenIds[i]) != address(this)) revert("Must Approve Tokens");

        for (uint256 i = 0; i < burnAmount; i++)
            IERC721(crazyCamels).transferFrom(msg.sender, oasisGraveyard, tokenIds[i]);

        uint256 claimableAmount = burnAmount * tokensPerCrazyCamel;
        _mint(msg.sender, claimableAmount);

        emit ClaimedOST(msg.sender, claimableAmount, tokenIds);
    }
}
