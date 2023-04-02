// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title An ERC1155 marketplace 
/// @author Leo Kolade for Team 11 Encode club
/// @notice You can use this contract to Buy and Sell NFTs, this contract requires permission from setApprovalForAll
/// @dev All Basic functions work as they should 
/// @custom:experimental This is an experimental contract.

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

//@dev This is the Marketplace contract
contract Marketplace is ERC1155Holder,Ownable{
    using SafeMath for uint256;

//@param this is the variable that holds the properties of each NFT
    struct Item {
        address nftContract;
        uint256 tokenId;
        uint256 amount;
        string name;
        uint256 price;
        address payable seller;
        bool sold;
    }

    //@notice this maps the Item to the uint256 which serves as each item id
    //@dev this can be used to get the list of items in the marketplace
    mapping(uint256 => Item) public items;
    uint256 public itemCount;

    //@notice this is used to check if contract is active or paused
    //@dev this variable can be called to check if the contract is paused or not
    bool public isPaused;

    //@notice Marketplace Platform fees in boint basis
    //@dev this variable can be called to check if the contract is paused or not
    uint256 public fees;

    //@dev This is a modifier to check if contract is paused it returns a boolean based on _checkPauseStatus
    modifier _isPaused() {
        _checkPauseStatus();
        _;
    }

    //@dev A function to check if contract is paused
    function _checkPauseStatus() internal view virtual{
        require(!isPaused, "Marketplace is paused");
    }
    
    //@dev Event for when Item is added and sold on the contract
    event ItemAdded(uint256 itemId, address nftContract, uint256 tokenId, uint256 amount, string name, uint256 price, address seller);
    event ItemSold(uint256 itemId, address buyer);

    //@notice this contract requires permission to be granted to the contract 
    //@dev function to add NFTs to the marketPlace
    function addItem(address _nftContract, uint256 _tokenId, uint256 _amount, string memory _name, uint256 _price) public _isPaused{
        
        require(_nftContract != address(0), "Invalid  Nft contract address");
        //@notice Check that the item being listed for sale is an ERC1155 token
        //@dev this method is used because  "owner" is a state variable and cannot be called
        require(IERC1155(_nftContract).balanceOf(msg.sender, _tokenId) >= _amount, "Only token owner can list for sale");

        itemCount++;

        //@notice Add a new Item and add it to the items mapping
        items[itemCount] = Item(_nftContract, _tokenId, _amount, _name, _price, payable(msg.sender), false);

        emit ItemAdded(itemCount, _nftContract, _tokenId, _amount, _name, _price, msg.sender);
    }

    /// @param _itemId gets the item Id and _amount gets the amount to be bought from each user
    /// @dev the function buys the listed Items on the marketplace
    function buyItem(uint256 _itemId, uint256 _amount) public payable _isPaused {
        require(items[_itemId].nftContract != address(0), "Item does not exist");
        require(!items[_itemId].sold, "Item already sold");
        require(_amount > 0, "Amount must be greater than zero");

        /// @dev This calculates the platform fees
        uint256 costprice = items[_itemId].price.mul(_amount);
        uint256 feesPercentage = fees.div(100);
        uint256 platformFees = costprice.mul(feesPercentage);
        uint256 totalCost = costprice.add(platformFees);

        require(msg.value >= totalCost, "Insufficient funds");
        require(items[_itemId].amount >= _amount, "Insufficient stock");

        /// @notice Update the stock of the item
        items[_itemId].amount -= _amount;

        /// @dev Mark the item as sold if all items are sold out
        if (items[_itemId].amount == 0) {
            items[_itemId].sold = true;
        }
        
        /// @notice Return any excess payment back to the buyer.
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value.sub(totalCost));
            }
        /// @notice Transfer the NFT to the buyer
        IERC1155(items[_itemId].nftContract).safeTransferFrom(items[_itemId].seller, msg.sender, items[_itemId].tokenId, _amount, "Transfer sent");

        /// @notice Transfer the funds to the seller
        items[_itemId].seller.transfer(costprice);

        /// @dev Tigger an event on completion
        emit ItemSold(_itemId, msg.sender);
        onERC1155Received(address(this), msg.sender, _itemId, _amount, "");
    }


    /// @dev The resumeMarketPlace is used to resume transaction and can only be called by the Owner
    function resumeMarketPlace() public onlyOwner {
        require(isPaused, "Marketplace is not paused");
        isPaused = false; 
    }
    /// @dev The pauseMarketPlace is used to pause transaction and can only be called by the Owner
    function pauseMarketPlace() public onlyOwner {
        require(!isPaused, "Marketplace is already paused");
        isPaused = true; 
    }
    /// @dev The resumeMarketPlace is used to pause transaction and can only be called by the Owner
    function checkPlatformTotalFees() external view returns(uint256){
        return address(this).balance;
    }
    
    /// @dev This withdraws platform fees
    function withdrawPlatformFees(address payable _toAddress, uint256 _amountFees) external onlyOwner{
        require(address(this).balance > 0, "No Revenue to withdraw");
        require(_toAddress != address(0), "Invalid address");
        payable(_toAddress).transfer(_amountFees);
    }

    /// @notice This should only be called in only extreme situations
    /// @dev This withdraws all Revenue held in the contract 
    function emergencyWithdrawAll(address payable _toAddress) external onlyOwner{
        require(address(this).balance != 0, "There is no Revenue");
        require(_toAddress != address(0), "Invalid address");
        withdrawAll(_toAddress);
    }

    /// @dev internal function for withdrawing all Revenue
    function withdrawAll(address payable _toAddress) internal onlyOwner{
        require(address(this).balance > 0, "No Revenue to withdraw");
        require(_toAddress != address(0), "Invalid address");
        uint256 balance = address(this).balance;
        _toAddress.transfer(balance);


        // (bool success, ) = _toAddress.call{value: address(this).balance}("");
        // require(success, "Withdrawal failed");
    }

    /// @notice This sets the fees bps for the marketplace, fees of zero means no fees, Default is also Zero
    /// @dev Function for setting  the fees of the contract 
    function setFees(uint256 _fees) external onlyOwner _isPaused{
        fees = _fees;
    }
}