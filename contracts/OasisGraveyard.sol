// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract OasisGraveyard {
    address public immutable crazyCamels;
    address public immutable ost;

    constructor(address _crazyCamels, address _ost) {
        crazyCamels = _crazyCamels;
        ost = _ost;
    }

    function buriedCamels() public view returns (uint256 crazyCamels_) {
        return IERC721(crazyCamels).balanceOf(address(this));
    }

    function buriedOasisTokens() public view returns (uint256 ost_) {
        return IERC20(ost).balanceOf(address(this));
    }
}
