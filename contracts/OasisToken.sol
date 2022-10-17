// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract OasisToken is ERC20, Ownable {
    /// ERRORS///

    error NotEnoughTokens();
    error MustApproveTokens();

    /// STATE VARIABLES ///

    uint256 public tokensPerCrazyCamel;
    address public crazyCamels;
    address public oasisGraveyard;

    /// EVENTS ///

    event Claimed(address indexed claimer, uint256 amount);

    /// CONSTRUCTOR ///

    constructor() ERC20("OasisToken", "OST") {}

    /// OWNER FUNCTIONS ///

    function setStateVariables(
        address _crazyCamels,
        address _oasisGraveyard,
        uint256 _tokensPerCrazyCamel
    ) external onlyOwner {
        crazyCamels = _crazyCamels;
        oasisGraveyard = _oasisGraveyard;
        tokensPerCrazyCamel = _tokensPerCrazyCamel;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /// USER FUNCTIONS ///

    function claim(uint256[] memory tokenIds) external {
        uint256 burnAmount = tokenIds.length;
        if (burnAmount < 1) revert NotEnoughTokens();

        for (uint256 i = 0; i < burnAmount; i++)
            if (IERC721(crazyCamels).getApproved(tokenIds[i]) != address(this)) revert MustApproveTokens();

        for (uint256 i = 0; i < burnAmount; i++)
            IERC721(crazyCamels).transferFrom(msg.sender, oasisGraveyard, tokenIds[i]);

        uint256 claimableAmount = burnAmount * tokensPerCrazyCamel;
        _mint(msg.sender, claimableAmount);

        emit Claimed(msg.sender, claimableAmount);
    }
}
