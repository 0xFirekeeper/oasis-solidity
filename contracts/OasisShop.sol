// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @author  . 0xFirekeeper
 * @title   . Oasis Shop
 * @notice  . Scalable Shop for the Oasis. Supports any 18 decimal ERC-20 or ERC-721 Enumerable. Users can purchase with $ETH or $OST.
 */

contract OasisShop is Pausable, Ownable {
    /// ERRORS ///

    error InvalidArguments();
    error UserBalanceTooLow();
    error TreasuryBalanceTooLow();
    error TransferFailed();

    /// STATE VARIABLES ///

    address public immutable oasisGraveyard;
    address public immutable treasury;
    address public immutable ost;

    mapping(address => ShopItem) public shopItems;

    /// STRUCTS ///

    struct ShopItem {
        bool isActive;
        bool is721;
        bool is20;
        bool withOst;
        uint128 price;
    }

    /// EVENTS ///

    event PurchasedItems(address indexed buyer, address indexed itemContract, uint256 indexed quantity);

    /// CONSTRUCTOR ///

    constructor(
        address _oasisGraveyard,
        address _treasury,
        address _ost
    ) {
        oasisGraveyard = _oasisGraveyard;
        treasury = _treasury;
        ost = _ost;
    }

    /// OWNER FUNCTIONS ///

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function addItem(
        address _contract,
        bool _isActive,
        bool _is721,
        bool _is20,
        bool _withOst,
        uint128 _price
    ) external onlyOwner {
        require(_contract != address(0) && _price > 0 && _isActive && (_is20 != _is721));

        shopItems[_contract] = ShopItem(_isActive, _is721, _is20, _withOst, _price);
    }

    function removeItem(address _contract) external onlyOwner {
        delete shopItems[_contract];
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /// USER FUNCTIONS ///

    function purchase(address _contract, uint256 _quantity) external payable whenNotPaused {
        // Save gas
        ShopItem memory item = shopItems[_contract];
        // Input checks
        if (1 > _quantity || !item.isActive) revert InvalidArguments();
        // Check balance vs total cost
        uint256 totalCost = item.price * _quantity;
        uint256 userBalance = item.withOst ? IERC20(ost).balanceOf(msg.sender) : msg.value;
        if (userBalance < totalCost) revert UserBalanceTooLow();
        // If with OST, burn OST
        if (item.withOst)
            if (!IERC20(ost).transferFrom(msg.sender, oasisGraveyard, totalCost)) revert TransferFailed();
        // Process transfers
        if (item.is20) {
            // Add decimals
            uint256 erc20quantity = _quantity * 10**18;
            // Check treasury20 balance
            if (erc20quantity > IERC20(_contract).balanceOf(treasury)) revert TreasuryBalanceTooLow();
            // Transfer20 from treasury (add decimals)
            if (!IERC20(_contract).transferFrom(treasury, msg.sender, erc20quantity)) revert TransferFailed();
        } else if (item.is721) {
            // Check treasury721 balance and fetch random 721 token ids
            uint256[] memory randomTokenIds = getRandomTokenIds(_contract, _quantity);
            for (uint256 i = 0; i < _quantity; i++)
                IERC721(_contract).transferFrom(treasury, msg.sender, randomTokenIds[i]);
        } else {
            revert InvalidArguments();
        }

        emit PurchasedItems(msg.sender, _contract, _quantity);
    }

    /// PRIVATE FUNCTIONS ///

    function getRandomTokenIds(address _contract, uint256 _quantity) private view returns (uint256[] memory) {
        uint256 treasuryBalance721 = IERC721(_contract).balanceOf(treasury);
        if (_quantity > treasuryBalance721) revert TreasuryBalanceTooLow();

        uint256 randomIndex = uint256(blockhash(block.number - 1)) % (treasuryBalance721 - _quantity + 1);

        uint256[] memory randomTokenIds = new uint256[](_quantity);

        for (uint256 i = 0; i < _quantity; i++)
            randomTokenIds[i] = IERC721Enumerable(_contract).tokenOfOwnerByIndex(treasury, randomIndex + i);

        return randomTokenIds;
    }
}
