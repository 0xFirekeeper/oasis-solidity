// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  ==========  EXTERNAL IMPORTS    ==========

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

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
 * @title   OasisStaking - Stake Evolved Camels for Oasis Tokens.
 * @notice  Stake your Evolved Camels, get a holder ERC20 token (Oasis Staking Token) to preserve Discord roles, earn $OST!
 */

contract OasisStake is ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Staker {
        uint256 amountStaked;
        uint256 timeOfLastUpdate;
        uint256 unclaimedRewards;
    }

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice OasisToken contract address.
    address public immutable oasisToken;
    /// @notice EvolvedCamels contract address.
    address public immutable evolvedCamels;
    /// @notice Rewards per hour per token deposited in wei.
    uint256 public rewardsPerHour = 10 * 1e18;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _evolvedCamels, address _oasisToken) {
        evolvedCamels = _evolvedCamels;
        oasisToken = _oasisToken;
    }

    /*///////////////////////////////////////////////////////////////
                                USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice User Address to Staker info.
    mapping(address => Staker) public stakers;

    function stake(uint256[] calldata _tokenIds) external nonReentrant {
        Staker storage currentStaker = stakers[msg.sender];
        uint256 tokenAmount = _tokenIds.length;

        if (0 == tokenAmount) revert("Must stake at least one token");

        if (currentStaker.amountStaked > 0) currentStaker.unclaimedRewards += calculateRewards(msg.sender);
        currentStaker.timeOfLastUpdate = block.timestamp;

        currentStaker.amountStaked += tokenAmount;

        for (uint256 i = 0; i < tokenAmount; i++)
            IERC721Enumerable(evolvedCamels).transferFrom(msg.sender, address(this), _tokenIds[i]);
    }

    function unstake(uint256[] calldata _tokenIds) external nonReentrant {
        Staker storage currentStaker = stakers[msg.sender];
        uint256 tokenAmount = _tokenIds.length;

        if (currentStaker.amountStaked == 0) revert("You have no tokens staked");

        currentStaker.unclaimedRewards += calculateRewards(msg.sender);
        currentStaker.timeOfLastUpdate = block.timestamp;

        for (uint256 i = 0; i < tokenAmount; i++) {
            if (msg.sender == IERC721Enumerable(evolvedCamels).ownerOf(_tokenIds[i]))
                IERC721Enumerable(evolvedCamels).transferFrom(address(this), msg.sender, _tokenIds[i]);
            else revert("You do not own all of these tokens");
        }

        currentStaker.amountStaked -= tokenAmount;
    }

    function claimRewards() external {
        uint256 rewards = availableRewards(msg.sender);

        if (rewards == 0) revert("You have no rewards to claim");

        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        stakers[msg.sender].unclaimedRewards = 0;

        IERC20(oasisToken).transfer(msg.sender, rewards);
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function availableRewards(address _staker) public view returns (uint256 availableRewards_) {
        return calculateRewards(_staker) + stakers[_staker].unclaimedRewards;
    }

    function getStakedTokens(address _user) public view returns (uint256[] memory stakedTokens_) {
        uint256 contractStaked = IERC721Enumerable(evolvedCamels).balanceOf(address(this));
        uint256 userStaked = stakers[_user].amountStaked;
        uint256[] memory userTokenIds = new uint256[](userStaked);

        uint256 currentTokenId;
        uint256 currentIndex;
        for (uint256 i = 0; i < contractStaked; i++) {
            currentTokenId = IERC721Enumerable(evolvedCamels).tokenOfOwnerByIndex(address(this), i);
            if (_user == IERC721Enumerable(evolvedCamels).ownerOf(currentTokenId)) {
                userTokenIds[currentIndex] = currentTokenId;
                currentIndex = currentIndex + 1;
                if (currentIndex == userStaked) break;
            }
        }

        return userTokenIds;
    }

    /*///////////////////////////////////////////////////////////////
                                PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function calculateRewards(address _staker) private view returns (uint256 _rewards) {
        return (((((block.timestamp - stakers[_staker].timeOfLastUpdate) * stakers[_staker].amountStaked)) *
            rewardsPerHour) / 3600);
    }
}
