// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Marketplace is ERC1155Holder,Ownable{
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


    bool public paused;

    modifier checkPauseMarketPlace() {
        _checkPauseMarketPlace();
        _;
    }

    function _checkPauseMarketPlace() internal view virtual{
        require(!paused, "Marketplace is paused");
    }
    

    event ItemAdded(uint256 itemId, address nftContract, uint256 tokenId, uint256 amount, string name, uint256 price, address seller);
    event ItemSold(uint256 itemId, address buyer);

    function addItem(address _nftContract, uint256 _tokenId, uint256 _amount, string memory _name, uint256 _price) public {
        require(!paused, "Marketplace is paused");
        itemCount++;

        // Check that the item being listed for sale is an ERC1155 token
        require(IERC1155(_nftContract).balanceOf(msg.sender, _tokenId) >= _amount, "Only token owner can list for sale");

        

        // Create a new Item and add it to the items mapping
        items[itemCount] = Item(_nftContract, _tokenId, _amount, _name, _price, payable(msg.sender), false);

        emit ItemAdded(itemCount, _nftContract, _tokenId, _amount, _name, _price, msg.sender);
    }

    function buyItem(uint256 _itemId, uint256 _amount) public payable {
        require(!paused, "Marketplace is paused");
        require(items[_itemId].nftContract != address(0), "Item does not exist");
        require(!items[_itemId].sold, "Item already sold");
        require(msg.value >= items[_itemId].price * _amount, "Insufficient funds");
        require(items[_itemId].amount >= _amount, "Insufficient stock");
       
        // Transfer the NFT to the buyer
        IERC1155(items[_itemId].nftContract).safeTransferFrom(items[_itemId].seller, msg.sender, items[_itemId].tokenId, _amount, "Transfer sent");

        // Transfer the funds to the seller
        items[_itemId].seller.transfer(msg.value);

        // Update the stock of the item
        items[_itemId].amount -= _amount;

        // Mark the item as sold if all items are sold out
        if (items[_itemId].amount == 0) {
            items[_itemId].sold = true;
        }

        emit ItemSold(_itemId, msg.sender);
        onERC1155Received(address(this), msg.sender, _itemId, _amount, "");
    }


    // @dev the functions pauseMarketPlace and resumeMarketPlace is used to pause transaction and can only be called by the owner contract 
    function pauseMarketPlace() public onlyOwner {
        require(!paused, "Marketplace is already paused");
        paused = true; 
    }

    function resumeMarketPlace() public onlyOwner {
        require(paused, "Marketplace is not paused");
        paused = false; 
    }

    
}