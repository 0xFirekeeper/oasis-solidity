// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @author  . 0xFirekeeper
 * @title   . Oasis Shop
 * @notice  . Shop for the Oasis - users may purchase $OST for $ETH, or active Shop ERC721 NFTs for $OST!
 */

contract OasisShop is Pausable, Ownable {
    using Address for address payable;

    /*///////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct ShopItem {
        bool isActive;
        address itemContract;
        uint64 itemId;
        uint128 itemPrice;
    }

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    address public immutable oasisGraveyard;
    address public immutable treasury;
    address public immutable ost;
    uint256 public weiPricePerOst;
    ShopItem[] private _shopItems;

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event PurchasedOst(address indexed buyer, uint256 indexed quantity);
    event PurchasedItem(address indexed buyer, address indexed itemContract, uint256 indexed itemId);

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _oasisGraveyard,
        address _treasury,
        address _ost,
        uint256 _weiPricePerOst
    ) {
        oasisGraveyard = _oasisGraveyard;
        treasury = _treasury;
        ost = _ost;
        weiPricePerOst = _weiPricePerOst;
    }

    /*///////////////////////////////////////////////////////////////
                               USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function purchaseOst(uint256 _quantity) external payable whenNotPaused {
        // Add decimals to $OST quantity
        uint256 fullOst = _quantity * 1e18;
        // Check Treasury $OST balance
        if (fullOst > IERC20(ost).balanceOf(treasury)) revert("Treasury Balance Too Low");
        // Check User $ETH balance
        if (msg.value < weiPricePerOst * _quantity) revert("User Balance Too Low");
        // Transfer $OST
        if (!IERC20(ost).transferFrom(treasury, msg.sender, fullOst)) revert("OST Transfer Failed");
        // Emit Event
        emit PurchasedOst(msg.sender, _quantity);
    }

    function purchaseShopItem(address _itemContract, uint256 _itemId) external whenNotPaused returns (bool replaced_) {
        // Check if item exists, is active and is owned by treasury
        (bool exists, uint256 index) = _itemExists(_itemContract, _itemId);
        if (!exists) revert("This item does not exist");
        if (!_shopItems[index].isActive) revert("This item is not for sale");
        if (!_itemOwnedByTreasury(_itemContract, _itemId)) revert("This item is not owned by the treasury");
        // Check user OST balance
        uint256 fullOst = _shopItems[index].itemPrice * 1e18;
        if (fullOst > IERC20(ost).balanceOf(msg.sender)) revert("User Balance Too Low");
        // Remove item from storage array
        _shopItems[index] = _shopItems[_shopItems.length - 1];
        _shopItems.pop();
        // Activate a new random item
        bool replaced = _activateRandomItem();
        // Burn OST and transfer item to sender
        if (!IERC20(ost).transferFrom(msg.sender, oasisGraveyard, fullOst)) revert("OST Transfer Failed");
        IERC721(_itemContract).safeTransferFrom(treasury, msg.sender, _itemId);
        // Emit Event
        emit PurchasedItem(msg.sender, _itemContract, _itemId);

        return replaced;
    }

    function getItems() external view returns (ShopItem[] memory shopItems_) {
        return _shopItems;
    }

    /*///////////////////////////////////////////////////////////////
                                OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setOstPrice(uint256 _weiPricePerOst) external onlyOwner {
        weiPricePerOst = _weiPricePerOst;
    }

    function addItems(
        address _itemContract,
        uint64[] memory _itemIds,
        uint128 _itemPrice
    ) external onlyOwner {
        uint256 itemAmount = _itemIds.length;
        if (0 == itemAmount) revert("Must pass at least one item ID");

        bool exists;
        for (uint256 i = 0; i < itemAmount; i++) {
            (exists, ) = _itemExists(_itemContract, _itemIds[i]);
            if (exists) revert("One of the items already exists");
            if (!_itemOwnedByTreasury(_itemContract, _itemIds[i])) revert("One of the items is not owned by treasury");
            if (!_addItem(_itemContract, _itemIds[i], _itemPrice)) revert("Error adding one of the items");
        }
    }

    function removeItems(address _itemContract, uint256[] memory _itemIds) external onlyOwner {
        uint256 itemAmount = _itemIds.length;
        if (0 == itemAmount) revert("Must pass at least one item ID");

        bool exists;
        uint256 index;
        for (uint256 i = 0; i < itemAmount; i++) {
            (exists, index) = _itemExists(_itemContract, _itemIds[i]);
            if (!exists) revert("One of the items does not exist");
            if (!_removeItem(index)) revert("Error removing one of the items");
        }
    }

    function activateRandomItems(uint256 amount) external onlyOwner {
        ShopItem[] storage currentItems = _shopItems;
        uint256 currentItemsLength = currentItems.length;
        if (amount > currentItemsLength) revert("Amount larger than shop item length");

        for (uint256 i = 0; i < currentItemsLength; i++) currentItems[i].isActive = false;

        uint256 randomIndex = _getRandomIndex(currentItemsLength);
        uint256 currentIndex;
        for (uint256 i = 0; i < amount; i++) {
            currentIndex = (randomIndex + i) % currentItemsLength;
            currentItems[currentIndex].isActive = true;
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdraw() external onlyOwner {
        payable(owner()).sendValue(address(this).balance);
    }

    /*///////////////////////////////////////////////////////////////
                                PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _activateRandomItem() private returns (bool activated_) {
        ShopItem[] storage currentItems = _shopItems;
        uint256 currentItemsLength = currentItems.length;
        uint256 randomIndex = _getRandomIndex(currentItemsLength);
        uint256 currentIndex;
        for (uint256 i = 0; i < currentItemsLength; i++) {
            currentIndex = (randomIndex + i) % currentItemsLength;
            if (!currentItems[currentIndex].isActive) {
                currentItems[currentIndex].isActive = true;
                return true;
            }
        }
        return false;
    }

    function _addItem(
        address _itemContract,
        uint64 _itemId,
        uint128 _itemPrice
    ) private returns (bool added_) {
        _shopItems.push(ShopItem(false, _itemContract, _itemId, _itemPrice));
        return true;
    }

    function _removeItem(uint256 index) private returns (bool removed_) {
        _shopItems[index] = _shopItems[_shopItems.length - 1];
        _shopItems.pop();
        return true;
    }

    function _itemExists(address _itemContract, uint256 _itemId) private view returns (bool exists_, uint256 index_) {
        ShopItem[] memory currentItems = _shopItems;
        uint256 currentItemsLength = currentItems.length;
        for (uint256 i = 0; i < currentItemsLength; i++)
            if (_itemId == currentItems[i].itemId && _itemContract == currentItems[i].itemContract) return (true, i);
        return (false, 1337420);
    }

    function _itemOwnedByTreasury(address _itemContract, uint256 _itemId) private view returns (bool treasuryOwned_) {
        if (treasury == IERC721(_itemContract).ownerOf(_itemId)) return true;
        return false;
    }

    function _getRandomIndex(uint256 maxExcluded) private view returns (uint256 randomIndex_) {
        uint256 randomHash = uint256(
            keccak256(abi.encode(block.difficulty, block.timestamp, block.number, msg.sender))
        );
        return randomHash % maxExcluded;
    }
}
