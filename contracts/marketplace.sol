// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Marketplace is ERC1155Holder,Ownable{
    using SafeMath for uint256;

    struct Item {
        address nftContract;
        uint256 tokenId;
        uint256 amount;
        string name;
        uint256 price;
        address payable seller;
        bool sold;
    }

    mapping(uint256 => Item) public items;
    uint256 public itemCount;

    //@notice this is used to check if contract is active or paused
    bool public isPaused;
    //@notice Marketplace Platform fees
    uint256 public fees;

    modifier _isPaused() {
        _checkPauseStatus();
        _;
    }

    function _checkPauseStatus() internal view virtual{
        require(!isPaused, "Marketplace is paused");
    }
    

    event ItemAdded(uint256 itemId, address nftContract, uint256 tokenId, uint256 amount, string name, uint256 price, address seller);
    event ItemSold(uint256 itemId, address buyer);

    function addItem(address _nftContract, uint256 _tokenId, uint256 _amount, string memory _name, uint256 _price) public _isPaused{
        
        require(_nftContract != address(0), "Invalid  Nft contract address");
        // Check that the item being listed for sale is an ERC1155 token
        //@dev this method is used because  "owner" is a state variable and cannot be called
        require(IERC1155(_nftContract).balanceOf(msg.sender, _tokenId) >= _amount, "Only token owner can list for sale");

        itemCount++;

        // Create a new Item and add it to the items mapping
        items[itemCount] = Item(_nftContract, _tokenId, _amount, _name, _price, payable(msg.sender), false);

        emit ItemAdded(itemCount, _nftContract, _tokenId, _amount, _name, _price, msg.sender);
    }

    function buyItem(uint256 _itemId, uint256 _amount) public payable _isPaused {
        // require(!isPaused, "Marketplace is paused");
        require(items[_itemId].nftContract != address(0), "Item does not exist");
        require(!items[_itemId].sold, "Item already sold");
        require(_amount > 0, "Amount must be greater than zero");
        uint256 costprice = items[_itemId].price.mul(_amount);
        uint256 feesPercentage = fees.div(100);
        uint256 platformFees = costprice.mul(feesPercentage);
        uint256 totalCost = costprice.add(platformFees);

        require(msg.value >= totalCost, "Insufficient funds");
        require(items[_itemId].amount >= _amount, "Insufficient stock");

        // Update the stock of the item
        items[_itemId].amount -= _amount;

        // Mark the item as sold if all items are sold out
        if (items[_itemId].amount == 0) {
            items[_itemId].sold = true;
        }
        
        // Return any excess payment back to the buyer.
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value.sub(totalCost));
            }
        // Transfer the NFT to the buyer
        IERC1155(items[_itemId].nftContract).safeTransferFrom(items[_itemId].seller, msg.sender, items[_itemId].tokenId, _amount, "Transfer sent");

        // Transfer the funds to the seller
        items[_itemId].seller.transfer(costprice);


        emit ItemSold(_itemId, msg.sender);
        onERC1155Received(address(this), msg.sender, _itemId, _amount, "");
    }


    // @dev the functions pauseMarketPlace and resumeMarketPlace is used to pause transaction and can only be called by the owner contract 
    function resumeMarketPlace() public onlyOwner {
        require(isPaused, "Marketplace is not paused");
        isPaused = false; 
    }
    function pauseMarketPlace() public onlyOwner {
        require(!isPaused, "Marketplace is already paused");
        isPaused = true; 
    }
    function checkPlatformTotalFees() external view returns(uint256){
        return address(this).balance;
    }
    
    function withdrawPlatformFees(address payable _toAddress, uint256 _amountFees) external onlyOwner{
        require(address(this).balance > 0, "No Revenue to withdraw");
        require(_toAddress != address(0), "Invalid address");
        payable(_toAddress).transfer(_amountFees);
    }
    function emergencyWithdrawAll(address payable _toAddress) external onlyOwner{
        require(address(this).balance != 0, "There is no Revenue");
        require(_toAddress != address(0), "Invalid address");
        withdrawAll(_toAddress);
    }

    function withdrawAll(address payable _toAddress) internal onlyOwner{
        require(address(this).balance > 0, "No Revenue to withdraw");
        require(_toAddress != address(0), "Invalid address");
        uint256 balance = address(this).balance;
        _toAddress.transfer(balance);


        // (bool success, ) = _toAddress.call{value: address(this).balance}("");
        // require(success, "Withdrawal failed");
    }

    function setFees(uint256 _fees) external onlyOwner _isPaused{
        fees = _fees;
    }
}