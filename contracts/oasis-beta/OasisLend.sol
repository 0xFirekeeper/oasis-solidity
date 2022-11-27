// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

//  ==========  EXTERNAL IMPORTS    ==========

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/interfaces/IERC721.sol";
// import "@openzeppelin/contracts/interfaces/IERC20.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";

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
 * @title   OasisLend - The Oasis Lending Contract.
 * @notice  This contract allows holders of various collections to get low-interest loans against their NFTs.
 * @dev     On hold. Should add oracle.
 */

/*is Ownable, Pausable*/ contract OasisLend {
    // /*///////////////////////////////////////////////////////////////
    //                             ERRORS
    // //////////////////////////////////////////////////////////////*/
    // error DoesNotOwnNFT();
    // error InactiveCollection();
    // error InactiveLoan();
    // error ContractBalanceTooLow();
    // error UserBalanceTooLow();
    // error NoCollateral();
    // error TokenNotApproved();
    // error LoanActive();
    // error LoanInactive();
    // /*///////////////////////////////////////////////////////////////
    //                             STATE VARIABLES
    // //////////////////////////////////////////////////////////////*/
    // StateVariables public stateVariables;
    // mapping(address => Collection) public collection;
    // mapping(address => Loan) public loan;
    // /*///////////////////////////////////////////////////////////////
    //                             STRUCTS
    // //////////////////////////////////////////////////////////////*/
    // struct StateVariables {
    //     address evolvedCamels;
    //     uint256 loanDuration;
    //     uint256 borrowFee;
    //     uint256 nonEvolvedRate;
    //     uint256 evolvedRate;
    //     uint256 cavalryRate;
    //     uint256 innerCircleRate;
    //     uint256 evolvedBalance;
    //     uint256 cavalryBalance;
    //     uint256 innerCircleBalance;
    //     uint256 gracePeriod;
    //     uint256 lateFee;
    // }
    // struct Collection {
    //     bool isActive;
    //     uint256 floor;
    // }
    // struct Loan {
    //     bool isActive;
    //     uint256 loanStart;
    //     address collection;
    //     uint256[] tokenIds;
    //     uint256 borrowAmount;
    // }
    // /*///////////////////////////////////////////////////////////////
    //                             USER FUNCTIONS
    // //////////////////////////////////////////////////////////////*/
    // function borrow(address _collection, uint256[] memory _tokenIds) external payable whenNotPaused {
    //     // Check if user has an ongoing loan
    //     if (loan[msg.sender].isActive) revert LoanActive();
    //     // Check if collection is whitelisted
    //     if (!collection[_collection].isActive) revert InactiveCollection();
    //     // Check if amount sent is enough to pay for the fee
    //     if (msg.value < stateVariables.borrowFee) revert UserBalanceTooLow();
    //     // Check if at least 1 token is used as collateral for the loan
    //     uint256 amountOfTokens = _tokenIds.length;
    //     if (amountOfTokens < 1) revert NoCollateral();
    //     // Check if treasury has enough funds to cover the loan and then some
    //     uint256 maxLoanAmount = amountOfTokens * collection[_collection].floor;
    //     if (maxLoanAmount > address(this).balance) revert ContractBalanceTooLow();
    //     // Check if tokens are actually owned by the msg.sender
    //     for (uint256 i = 0; i < amountOfTokens; i++)
    //         if (msg.sender != IERC721(_collection).ownerOf(_tokenIds[i])) revert DoesNotOwnNFT();
    //     // Check if tokens are approved to the contract
    //     for (uint256 i = 0; i < amountOfTokens; i++)
    //         if (IERC721(_collection).getApproved(_tokenIds[i]) == address(this)) revert TokenNotApproved();
    //     // Transfer their tokens from msg.sender to the contract
    //     for (uint256 i = 0; i < amountOfTokens; i++)
    //         IERC721(_collection).transferFrom(msg.sender, address(this), _tokenIds[i]);
    //     // Transfer ETH from the contract to msg.sender
    //     uint256 borrowAmount = getBorrowAmount(msg.sender, _collection, amountOfTokens);
    //     payable(msg.sender).transfer(borrowAmount);
    //     // Update loan mapping
    //     loan[msg.sender] = Loan(true, block.timestamp, _collection, _tokenIds, borrowAmount);
    // }
    // function repay() external payable {
    //     // Check if loan is active
    //     if (!loan[msg.sender].isActive) revert LoanInactive();
    //     // Check if is too late
    //     if (_isTooLate(loan[msg.sender])) {
    //         loan[msg.sender].isActive = false;
    //         revert LoanInactive();
    //     }
    //     // Set owed amount including late fees
    //     uint256 owedAmount = _isLate(loan[msg.sender])
    //         ? loan[msg.sender].borrowAmount + stateVariables.lateFee
    //         : loan[msg.sender].borrowAmount;
    //     // Check if user sent enough to repay
    //     if (owedAmount < msg.value) revert UserBalanceTooLow();
    //     // TODO: Check if contract owns ALL tokens
    //     // Transfer their tokens from contract to msg.sender
    //     // for (uint256 i = 0; i < loan[msg.sender].tokenIds.length; i++)
    //     //     IERC721(loan[msg.sender].collection).transferFrom(address(this), msg.sender, loan[msg.sender].tokenIds[i]);
    //     // Delete loan
    //     delete loan[msg.sender];
    // }
    // function getBorrowAmount(
    //     address _user,
    //     address _collection,
    //     uint256 _tokenAmount
    // ) public view returns (uint256 borrowAmount_) {
    //     uint256 ecOwned = IERC721(stateVariables.evolvedCamels).balanceOf(_user);
    //     uint256 collectionFloor = collection[_collection].floor;
    //     uint256 totalFloorValue = _tokenAmount * collectionFloor;
    //     if (ecOwned >= stateVariables.innerCircleBalance) {
    //         return (totalFloorValue * stateVariables.innerCircleRate) / 100;
    //     } else if (ecOwned >= stateVariables.cavalryBalance) {
    //         return (totalFloorValue * stateVariables.cavalryRate) / 100;
    //     } else if (ecOwned >= stateVariables.evolvedBalance) {
    //         return (totalFloorValue * stateVariables.evolvedRate) / 100;
    //     } else {
    //         return (totalFloorValue * stateVariables.nonEvolvedRate) / 100;
    //     }
    // }
    // /*///////////////////////////////////////////////////////////////
    //                             OWNER FUNCTIONS
    // //////////////////////////////////////////////////////////////*/
    // function pause() public onlyOwner {
    //     _pause();
    // }
    // function unpause() public onlyOwner {
    //     _unpause();
    // }
    // function deposit() external payable onlyOwner {}
    // function setStateVariables(StateVariables memory _stateVariables) external onlyOwner {
    //     stateVariables = _stateVariables;
    // }
    // function addCollection(address _collection, uint256 _floor) external onlyOwner {
    //     collection[_collection].isActive = true;
    //     collection[_collection].floor = _floor;
    // }
    // function removeCollection(address _collection) external onlyOwner {
    //     collection[_collection].isActive = false;
    // }
    // function setCollectionFloor(address _collection, uint256 _floor) external onlyOwner {
    //     collection[_collection].floor = _floor;
    // }
    // /*///////////////////////////////////////////////////////////////
    //                             INTERNAL FUNCTIONS
    // //////////////////////////////////////////////////////////////*/
    // function _isLate(Loan memory _loan) internal view returns (bool isActive_) {
    //     if (
    //         block.timestamp > _loan.loanStart + stateVariables.loanDuration &&
    //         block.timestamp < _loan.loanStart + stateVariables.loanDuration + stateVariables.gracePeriod
    //     ) return true;
    //     return false;
    // }
    // function _isTooLate(Loan memory _loan) internal view returns (bool isActive_) {
    //     if (block.timestamp > _loan.loanStart + stateVariables.loanDuration + stateVariables.gracePeriod) return true;
    //     return false;
    // }
}
