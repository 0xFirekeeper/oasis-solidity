// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract OasisShop is Pausable, Ownable {
    /// STATE VARIABLES ///

    address public treasury;
    address public ec;
    address public ost;
    uint256[] public ecTokenIds;
    uint256 public ostPricePerEc;
    address public oasisGraveyard;

    /// EVENTS ///

    event PurchasedEC(address indexed buyer, uint256 indexed ostSpent, uint256 ecId, uint256 ecsLeft);

    /// OWNER FUNCTIONS ///

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setStateVariables(
        address _treasury,
        address _ec,
        address _ost,
        uint256[] memory _ecTokenIds,
        uint256 _ostPricePerEc,
        address _oasisGraveyard
    ) public onlyOwner {
        treasury = _treasury;
        ec = _ec;
        ost = _ost;
        ecTokenIds = _ecTokenIds;
        ostPricePerEc = _ostPricePerEc;
        oasisGraveyard = _oasisGraveyard;
    }

    /// EXTERNAL FUNCTIONS ///

    function purchaseEC() external whenNotPaused {
        if (ecTokenIds.length < 1) revert("No available EC Token Ids");
        if (IERC721(ec).balanceOf(treasury) < 1) revert("Treasury has no ECs");
        if (IERC20(ost).balanceOf(msg.sender) < ostPricePerEc) revert("Not Enough $OST Tokens");

        uint256 lastTokenId = ecTokenIds[ecTokenIds.length - 1];

        if (IERC20(ost).allowance(msg.sender, address(this)) < ostPricePerEc) revert("Not enough OST allowance");
        IERC20(ost).transferFrom(msg.sender, oasisGraveyard, ostPricePerEc);

        IERC721(ec).transferFrom(treasury, msg.sender, lastTokenId);
        ecTokenIds.pop();

        emit PurchasedEC(msg.sender, ostPricePerEc, lastTokenId, ecTokenIds.length);
    }

    function getEcLeft() external view returns (uint256 ecsLeft_) {
        return ecTokenIds.length;
    }

    function getOstPricePerEc() external view returns (uint256 ostPricePerEc_) {
        return ostPricePerEc;
    }
}
