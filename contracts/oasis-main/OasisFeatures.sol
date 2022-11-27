// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  ==========  EXTERNAL IMPORTS    ==========

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

//  ==========  INTERNAL IMPORTS    ==========

import "../interfaces/IEvolvedCamels.sol";
import "../interfaces/IOasisRegistry.sol";
import "../interfaces/IOasisToken.sol";

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
 * @title   OasisFeatures - Bonus features for the Oasis.
 * @notice  Simple and fun Oasis features that do not require their own contract!
 */

contract OasisFeatures is Ownable, Pausable, ReentrancyGuard, IERC721Receiver {
    using Address for address payable;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Error for if arguments are invalid.
    error InvalidArguments();
    /// @notice Error for if msg.value is invalid.
    error InvalidETHAmount();
    /// @notice Error for if contract balance too low.
    error ContractBalanceTooLow();
    /// @notice Error for if user balance too low.
    error UserBalanceTooLow();
    /// @notice Error for if ERC721 received from invalid sender.
    error InvalidERC721Sender();

    /*///////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  NFT data related to NFTs in this contract that are for sale.
     * @param   nftContract  The NFT contract address.
     * @param   nftTokenId  The NFT token ID.
     * @param   nftPrice  The NFT price in OST.
     */
    struct NFT {
        address nftContract;
        uint64 nftTokenId;
        uint128 nftPrice;
    }

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice OasisRegistry contract address.
    IOasisRegistry public oasisRegistry;
    /// @notice Amount of OST to be rewarded per burnt Crazy Camels.
    uint256 public ostRewardPerCCBurned = 50000 * 1e18;
    /// @notice Amount of OST to be rewarded per Evolved Camels minted.
    uint256 public ostRewardPerMint = 50000 * 1e18;
    /// @notice Price in wei for 1 * 1e18 OST.
    uint256 public weiPricePerOst = 500000000000;
    /// @notice Array of designated NFTs for sale within this contract.
    NFT[] public nftsForSale;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  OasisFeatures constructor.
     * @param   _oasisRegistry  Address of the OasisRegistry contract.
     */
    constructor(IOasisRegistry _oasisRegistry) {
        oasisRegistry = _oasisRegistry;
    }

    /*///////////////////////////////////////////////////////////////
                                USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Burn Crazy Camels to earn Oasis Tokens.
     * @param   _tokenIds  Crazy Camels token IDs to be burned.
     */
    function oasisBurn(uint256[] calldata _tokenIds) external nonReentrant whenNotPaused {
        if (0 == _tokenIds.length) revert InvalidArguments();

        address crazyCamels = oasisRegistry.crazyCamels();
        address oasisGraveyard = oasisRegistry.oasisGraveyard();

        for (uint256 i = 0; i < _tokenIds.length; i++)
            IERC721(crazyCamels).transferFrom(msg.sender, oasisGraveyard, _tokenIds[i]);

        IOasisToken(oasisRegistry.oasisToken()).mint(msg.sender, _tokenIds.length * ostRewardPerCCBurned);
    }

    /**
     * @notice  Mints '_amount' of Evolved Camels and transfers them to caller along with bonus OST Rewards.
     * @param   _amount  Amount of Evolved Camels to mint.
     */
    function oasisMint(uint256 _amount) external payable nonReentrant whenNotPaused {
        address ec = oasisRegistry.evolvedCamels();
        address ost = oasisRegistry.oasisToken();
        uint256 ostReward = ostRewardPerMint * _amount;

        if (msg.value != IEvolvedCamels(ec).mintCost() * _amount) revert InvalidETHAmount();
        if (IERC20(ost).balanceOf(address(this)) < ostReward) revert ContractBalanceTooLow();

        IEvolvedCamels(ec).publicSaleMint{value: msg.value}(_amount);

        uint256 startingTokenId = IERC721Enumerable(ec).totalSupply() - 1;
        for (uint256 i = 0; i < _amount; i++)
            IERC721(ec).safeTransferFrom(address(this), msg.sender, startingTokenId + i);

        IOasisToken(ost).mint(msg.sender, ostReward);
    }

    /**
     * @notice  Purchase OST for ETH.
     * @param   _quantity  Amount of OST (without decimals) to be purchased.
     */
    function buyOST(uint256 _quantity) external payable nonReentrant whenNotPaused {
        if (_quantity < 1e18) revert InvalidArguments();
        if (msg.value != weiPricePerOst * _quantity) revert InvalidETHAmount();

        IOasisToken(oasisRegistry.oasisToken()).mint(msg.sender, _quantity * 1e18);
    }

    /**
     * @notice  Purchase a deposited NFT for OST.
     * @param   _index  Index of the NFT in nftsForSale array.
     */
    function buyNFT(uint256 _index) external nonReentrant whenNotPaused {
        address ost = oasisRegistry.oasisToken();
        NFT[] memory nfts = nftsForSale;

        if (_index >= nfts.length) revert InvalidArguments();
        if (IERC20(ost).balanceOf(msg.sender) < nfts[_index].nftPrice) revert UserBalanceTooLow();

        _removeNFT(_index);

        IOasisToken(ost).burn(msg.sender, nfts[_index].nftPrice);
        IERC721(nfts[_index].nftContract).safeTransferFrom(address(this), msg.sender, nfts[_index].nftTokenId);
    }

    /**
     * @notice  Returns the NFT struct corresponding to '_index'.
     * @param   _index  Index of the NFT in nftsForSale array.
     * @return  nftForSale_  NFT item at '_index'.
     */
    function viewNft(uint256 _index) external view returns (NFT memory nftForSale_) {
        return nftsForSale[_index];
    }

    /**
     * @notice  Returns the length of 'nftsForSale'.
     * @return  nftsForSaleAmount_  Length of 'nftsForSale'.
     */
    function totalNfts() external view returns (uint256 nftsForSaleAmount_) {
        return nftsForSale.length;
    }

    /*///////////////////////////////////////////////////////////////
                                IERC721RECEIVER
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Required for ERC721 safe transfers.
     * @return  bytes4  The onERC721Received selector.
     */
    function onERC721Received(address, address, uint256, bytes calldata) public pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /*///////////////////////////////////////////////////////////////
                                OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Pauses the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice  Sets the OasisRegistry contract address.
     * @param   _oasisRegistry  OasisRegistry contract address.
     */
    function setOasisRegistry(IOasisRegistry _oasisRegistry) external onlyOwner {
        oasisRegistry = _oasisRegistry;
    }

    /**
     * @notice  Sets OST rewards per CC Burned.
     * @param   _ostRewardPerCCBurned  OST rewards per CC burned.
     */
    function setOSTRewardPerCCBurned(uint256 _ostRewardPerCCBurned) external onlyOwner {
        ostRewardPerCCBurned = _ostRewardPerCCBurned;
    }

    /**
     * @notice  Sets OST rewards per EC Mint.
     * @param   _ostRewardPerMint  OST rewards per EC Mint.
     */
    function setOSTRewardPerMint(uint256 _ostRewardPerMint) external onlyOwner {
        ostRewardPerMint = _ostRewardPerMint;
    }

    /// @notice Transfers contract ETH balance to owner.
    function withdrawETH() external onlyOwner {
        payable(msg.sender).sendValue(address(this).balance);
    }

    /// @notice Transfers contract OST balance to owner.
    function withdrawOST() external onlyOwner {
        address ost = oasisRegistry.oasisToken();
        IERC20(ost).transfer(msg.sender, IERC20(ost).balanceOf(address(this)));
    }

    /**
     * @notice  Adds an NFT to nftsForSale and transfers it to the contract.
     * @param   _nftContract  NFT contract address.
     * @param   _nftTokenId  NFT token ID.
     * @param   _nftPrice  NFT price in OST.
     */
    function depositNFT(address _nftContract, uint256 _nftTokenId, uint256 _nftPrice) external onlyOwner {
        _addNFT(_nftContract, _nftTokenId, _nftPrice);

        IERC721(_nftContract).transferFrom(msg.sender, address(this), _nftTokenId);
    }

    /**
     * @notice  Removes an NFT from nftsForSale (if it exists) and transfers it to the msg.sender.
     * @param   _nftContract  NFT contract address.
     * @param   _nftTokenId  NFT price in OST.
     */
    function withdrawNFT(address _nftContract, uint256 _nftTokenId) external onlyOwner {
        bool found;
        uint256 index;
        NFT[] memory nfts = nftsForSale;

        for (uint256 i = 0; i < nfts.length; i++) {
            if (_nftContract == nfts[i].nftContract && _nftTokenId == nfts[i].nftTokenId) {
                found = true;
                index = i;
                break;
            }
        }

        if (found) _removeNFT(index);

        IERC721(_nftContract).transferFrom(address(this), msg.sender, _nftTokenId);
    }

    /*///////////////////////////////////////////////////////////////
                                PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice  Adds an NFT to nftsForSale.
     * @param   _nftContract  NFT contract address.
     * @param   _nftTokenId  NFT token ID.
     * @param   _nftPrice  NFT price in OST.
     */
    function _addNFT(address _nftContract, uint256 _nftTokenId, uint256 _nftPrice) private {
        nftsForSale.push(NFT(_nftContract, uint64(_nftTokenId), uint128(_nftPrice)));
    }

    /**
     * @notice  Removes an NFT from nftsForSale.
     * @param   _index  Index of the NFT in nftsForSale to remove.
     */
    function _removeNFT(uint256 _index) private {
        nftsForSale[_index] = nftsForSale[nftsForSale.length - 1];
        nftsForSale.pop();
    }
}
