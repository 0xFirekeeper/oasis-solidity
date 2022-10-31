// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./OasisStaking.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract OasisHelper {
    OasisStaking public immutable oasisStaking;
    IERC721Enumerable public immutable evolvedCamels;

    constructor(OasisStaking _oasisStaking, IERC721Enumerable _evolvedCamels) {
        oasisStaking = _oasisStaking;
        evolvedCamels = _evolvedCamels;
    }

    function GetStakedTokenIds(address _address) external view returns (uint256[] memory stakedTokenIds_) {
        uint256 contractStaked = evolvedCamels.balanceOf(address(oasisStaking));
        (uint256 userStaked, ) = oasisStaking.userStakeInfo(_address);

        uint256[] memory stakedTokenIds = new uint256[](userStaked);
        uint256 currentTokenId;
        address currentTokenIdStaker;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < contractStaked; i++) {
            currentTokenId = evolvedCamels.tokenOfOwnerByIndex(address(oasisStaking), i);
            currentTokenIdStaker = oasisStaking.stakerAddress(currentTokenId);
            if (currentTokenIdStaker == _address) {
                stakedTokenIds[currentIndex] = currentTokenId;
                currentIndex = currentIndex + 1;
                if (currentIndex == userStaked) break;
            }
        }

        return stakedTokenIds;
    }
}
