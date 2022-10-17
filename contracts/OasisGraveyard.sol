// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract OasisGraveyard {
    address public immutable crazyCamels;

    constructor(address _crazyCamels) {
        crazyCamels = _crazyCamels;
    }

    function buriedCamels() public view returns (uint256) {
        return IERC721(crazyCamels).balanceOf(address(this));
    }
}
