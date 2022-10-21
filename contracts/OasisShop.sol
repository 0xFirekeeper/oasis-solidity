// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @author  . 0xFirekeeper
 * @title   . Oasis Shop
 * @notice  . Scalable Shop for the Oasis. You can add any ERC-20 or ERC-721 Enumerable to it. Users can purchase with $ETH or $OST.
 */

contract OasisShop is Pausable, Ownable, ReentrancyGuard {
    /// STATE VARIABLES ///

    address public oasisGraveyard;
    address public treasury;
    address public ost;

    mapping(address => ShopItem) public shopItems;

    uint256 private nonce = 0;

    /// STRUCTS ///

    struct ShopItem {
        bool isActive;
        bool is721;
        bool is20;
        bool withWei;
        bool withOst;
        uint256 weiPrice;
        uint256 ostPrice;
    }

    /// EVENTS ///

    event PurchasedShopItems(address indexed buyer, address indexed itemAddress, ShopItem item, uint256 quantity);

    /// OWNER FUNCTIONS ///

    function pause() public onlyOwner nonReentrant {
        _pause();
    }

    function unpause() public onlyOwner nonReentrant {
        _unpause();
    }

    function setStateVariables(
        address _oasisGraveyard,
        address _treasury,
        address _ost
    ) external onlyOwner nonReentrant {
        oasisGraveyard = _oasisGraveyard;
        treasury = _treasury;
        ost = _ost;
    }

    function addShopItem(
        address _contract,
        bool _isActive,
        bool _is721,
        bool _is20,
        bool _withWei,
        bool _withOst,
        uint256 _weiPrice,
        uint256 _ostPrice
    ) external onlyOwner nonReentrant {
        require(
            _contract != address(0) &&
                _isActive &&
                (_is20 != _is721) &&
                ((_withWei && _weiPrice > 0) || (_withOst && _ostPrice > 0))
        );

        shopItems[_contract] = ShopItem(_isActive, _is721, _is20, _withWei, _withOst, _weiPrice, _ostPrice);
    }

    function removeShopIem(address _contract) external onlyOwner nonReentrant {
        delete shopItems[_contract];
    }

    /// USER FUNCTIONS ///

    function purchaseWithOst(address _contract, uint256 _quantity) external whenNotPaused nonReentrant {
        require(shopItems[_contract].isActive, "This item is not active.");
        require(shopItems[_contract].withOst, "This item cannot be purchased with $OST.");
        require(_quantity > 0, "You must at least purchase one item.");

        ShopItem memory item = shopItems[_contract];

        if (item.is20) {
            uint256 treasuryBalance20 = IERC20(_contract).balanceOf(treasury);
            uint256 userBalanceOst = IERC20(ost).balanceOf(msg.sender);
            uint256 totalOstPrice = item.ostPrice * _quantity;

            if (treasuryBalance20 < _quantity) revert("Treasury does not have enough tokens.");
            if (userBalanceOst < totalOstPrice) revert("Not enough $OST tokens.");

            IERC20(_contract).transferFrom(treasury, msg.sender, _quantity);
            IERC20(ost).transferFrom(msg.sender, oasisGraveyard, totalOstPrice);
        } else if (item.is721) {
            uint256 treasuryBalance721 = IERC721(_contract).balanceOf(treasury);
            uint256 userBalanceOst = IERC20(ost).balanceOf(msg.sender);
            uint256 totalOstPrice = item.ostPrice * _quantity;

            if (treasuryBalance721 < _quantity) revert("Treasury does not have enough NFTs.");
            if (userBalanceOst < totalOstPrice) revert("Not enough $OST tokens.");

            for (uint256 i = 0; i < _quantity; i++) {
                uint256 randomTokenIndex = generateRandomNumber(0, treasuryBalance721 - i);
                uint256 randomTokenId = IERC721Enumerable(_contract).tokenOfOwnerByIndex(treasury, randomTokenIndex);

                IERC721(_contract).transferFrom(treasury, msg.sender, randomTokenId);
            }
            IERC20(ost).transferFrom(msg.sender, oasisGraveyard, totalOstPrice);
        } else {
            revert("This type of token is not supported.");
        }

        emit PurchasedShopItems(msg.sender, _contract, item, _quantity);
    }

    function purchaseWithEth(address _contract, uint256 _quantity) external payable whenNotPaused nonReentrant {
        require(shopItems[_contract].isActive, "This item is not active.");
        require(shopItems[_contract].withWei, "This item cannot be purchased with $ETH.");
        require(_quantity > 0, "You must at least purchase one item.");

        ShopItem memory item = shopItems[_contract];

        if (item.is20) {
            uint256 treasuryBalance20 = IERC20(_contract).balanceOf(treasury);
            uint256 userBalanceWei = msg.value;
            uint256 totalWeiPrice = item.weiPrice * _quantity;

            if (treasuryBalance20 < _quantity) revert("Treasury does not have enough tokens.");
            if (userBalanceWei < totalWeiPrice) revert("Not enough $ETH tokens.");

            IERC20(_contract).transferFrom(treasury, msg.sender, _quantity);
        } else if (item.is721) {
            uint256 treasuryBalance721 = IERC721(_contract).balanceOf(treasury);
            uint256 userBalanceWei = msg.value;
            uint256 totalWeiPrice = item.weiPrice * _quantity;

            if (treasuryBalance721 < _quantity) revert("Treasury does not have enough NFTs.");
            if (userBalanceWei < totalWeiPrice) revert("Not enough $ETH tokens.");

            for (uint256 i = 0; i < _quantity; i++) {
                uint256 randomTokenIndex = generateRandomNumber(0, treasuryBalance721 - i);
                uint256 randomTokenId = IERC721Enumerable(_contract).tokenOfOwnerByIndex(treasury, randomTokenIndex);

                IERC721(_contract).transferFrom(treasury, msg.sender, randomTokenId);
            }
        } else {
            revert("This type of token is not supported.");
        }

        emit PurchasedShopItems(msg.sender, _contract, item, _quantity);
    }

    /// INTERNAL FUNCTIONS ///

    function generateRandomNumber(uint256 _minIncluded, uint256 _maxExcluded) internal returns (uint256 randomNumber_) {
        uint256 randomnumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % _maxExcluded;
        randomnumber = randomnumber + _minIncluded;
        nonce = nonce + 1;
        return randomnumber;
    }
}
