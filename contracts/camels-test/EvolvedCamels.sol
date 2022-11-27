// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  ==========  EXTERNAL IMPORTS    ==========

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

//  ==========  INTERNAL IMPORTS    ==========

import "../interfaces/IEvolvedCamels.sol";

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
 * @title   EvolvedCamels - Basic ERC721Enumerable NFT.
 * @notice  Used for testing other Oasis contracts in place of the Evolved Camels contract.
 */

contract EvolvedCamels is ERC721Enumerable, Ownable, IEvolvedCamels {
    using Strings for uint256;
    using Address for address payable;

    /*///////////////////////////////////////////////////////////////
                                STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public maxTotalTokens;
    uint256 public mintCost = 0.000 ether;
    address public treasury;

    string private _currentBaseURI;

    /*///////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() ERC721("Evolved Camels", "EC") {
        maxTotalTokens = 2222;
        treasury = 0xDaaBDaaC8073A7dAbdC96F6909E8476ab4001B34;
    }

    /*///////////////////////////////////////////////////////////////
                                USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function publicSaleMint(uint256 number) public payable {
        require(totalSupply() + number <= maxTotalTokens, "Not enough NFTs left to mint");
        require(msg.value == mintCost * number, "Invalid amount of ETH");

        for (uint256 i = 0; i < number; i++) _safeMint(msg.sender, totalSupply());
    }

    function mint(address to, uint256 quantity) public payable {
        require(totalSupply() + quantity <= maxTotalTokens, "Not enough NFTs left to mint");
        require(msg.value == mintCost * quantity, "Invalid amount of ETH");

        for (uint256 i = 0; i < quantity; i++) _safeMint(to, totalSupply());
    }

    function tokenURI(uint256 tokenId_) public view virtual override returns (string memory) {
        require(_exists(tokenId_), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId_.toString(), ".json")) : "";
    }

    /*///////////////////////////////////////////////////////////////
                                ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function addTokens(uint number) public onlyOwner {
        require(number > 0, "Cannot add 0 tokens!");

        maxTotalTokens += number;
    }

    function changeBaseURI(string memory baseURI) public onlyOwner {
        _currentBaseURI = baseURI;
    }

    function setMintCost(uint256 newCost) public onlyOwner {
        mintCost = newCost;
    }

    function setTreasury(address newTreasury) public onlyOwner {
        treasury = newTreasury;
    }

    function withdraw() public onlyOwner {
        payable(treasury).sendValue(address(this).balance);
    }

    /*///////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _baseURI() internal view virtual override returns (string memory) {
        return _currentBaseURI;
    }
}
