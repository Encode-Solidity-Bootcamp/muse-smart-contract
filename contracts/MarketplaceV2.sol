//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./collection.sol";

contract MarketplaceV2 is Ownable {
    ///@notice Custom error messages for the FillionMarketplace.sol

    ///@notice - raised when an address is not the owner of the ERC1155 collection.
    error ERC1155NotOwner();
    ///@notice - raised when the marketplace does not have appoval for the ERC1155 token.
    error ERC1155ApprovalRequired();
    ///@notice - raised when an address tries to list an ERC1155 token that is already listed in the marketplace.
    error ERC1155AlreadyListed();
    ///@notice - raised when the seller of a listed token doesn't own the token anymore.
    error SellerNotOwner();
    ///@notice - raised when caller is not the owner of the token.
    error NotOwner();
    ///@notice - raised when a listing is not open
    error ListingNotOpen();
    ///@notice - raised when correct price is not sent
    error WrongPrice();

    using EnumerableSet for Enumerable.UintSet;
    using Bytes32ToBytes32Map for Bytes32ToBytes32Map.Map;
    using Counters for Counters.Counter;

    //Collection public nft;

    ///@dev Counter for listings
    Counters.Counter private listingId;
    Counters.Counter private nftId;

    ///@dev - Tracking active listings and offers
    EnumerableSet.UintSet private openListings;

    ///@dev - Tracking a user's nft list
    EnumerableSet.UintSet private userNftList;

    //EnumerableMap.Bytes32ToBytes32Map private nftItemMap;

    ///@dev listing states
    enum State {
        CANCELLED,
        COMPLETED,
        OPEN
    }

    ///@dev different mappings to listing
    mapping(address => EnumerableSet.UintSet) private addrToActiveListings;
    mapping(address => mapping(uint256 => bool)) addrToTokenIdIsListed;
    mapping(uint256 => CollectionListing) private listingIdToListing; //mapping saving listings

    mapping(address => mapping(CollectionListing => bool))
        public isCollectionListed;

    /**
    @notice - Structure for an ERC1155 collection listing
    @param quantity - The quantities of the tokens listed
    @param collectionAddress - The contract address of the collection
    @param price - The price of the token
    @param seller - The address of the seller
    @param status - The status of the listing
    @param id - The ID of the listing
    */
    struct CollectionListing {
        //listing for collection
        uint256 id;
        uint256 price;
        uint256[] quantity;
        address collectionAddress;
        address payable seller;
        State state;
        //NFTItem[] nfts;
        EnumerableMap.Bytes32ToBytes32Map nftItemsMap;
    }

    struct NFTItem {
        uint256 tokenId;
        bool sold;
        address owner;
    }

    function listCollection(
        address _collectionAddress,
        uint256 price,
        uint256 quantity
    ) {
        //require that this function can only be called by collection owner
        EnumerableMap.Bytes32ToBytes32Map memory nftItemMap;

        Collection c = Collection(_collectionAddress);
        (bool success, bytes memory _data) = address(c).call(
            abi.encodeWithSignature("token_ids()")
        );
        require(success, "Call failed");
        uint256[] memory _tokenIds = abi.decode(_data, (uint256[]));

        NftItem[] memory nfts;
        for (uint i = 0; i < _tokenIds.length && _tokenIds.length <= 100; i++) {
            nfts.push(NFTItem(_tokenIds[i], false, msg.sender));
        }

        for (uint i = 0; i < nfts.length; i++) {
            //add unchecked later
            bytes32 bytesKey = bytes32(uint256(i + 1));
            bytes32 bytesValue;

            bytes memory encoded = abi.encode(nfts[i]);
            assembly {
                bytesValue := mload(add(encoded, 32))
            }
            nftItemMap.set(bytesKey, bytesValue);
        }

        listingId.increment();
        CollectionListing memory listing = CollectionListing(
            listingId.current(),
            price,
            quantity,
            _collectionAddress,
            msg.sender,
            State.OPEN,
            nftItemsMap
        );

        isCollectionListed[_collectionAddress][listing.id] = true;
        addrToActiveListings[msg.sender].add(listing.id);
        listingIdToListing[listing.id] = listing;
        openListings.add(listing.id);
        emit CollectionListingCreated(
            _price,
            listingId,
            _collectionAddress,
            msg.sender
        );
        return listing.id;
    }

    function getOwners() {}

    function buyListing(uint256 _listingId, uint256 quantity) external payable {
        Collection memory listing = listingIdToListing[_listingId];
        if (listing.state != State.OPEN) revert ListingNotOpen();

        //require that seller has to be the owner of the collection
        Collection addr = Collection(listing.contractAddress);
        (bool success, bytes memory data) = address(addr).call(
            abi.encodeWithSignature("owner()")
        );
        require(success, "Call failed");
        address addressOwner = abi.decode(data, (address));
        require(listing.seller == addressOwner);

        if (msg.value != listing.price) revert WrongPrice();
    }

    function cancelListing() {}

    function getListingsByUser() {}

    function resellTokens() {}

    /////////////////////INTERNAL FUNCTIONS///////////////////////////////
    ///@notice - Internal function to remove a listing from storage
    /**
     * @dev Remove listing from storage
     * @param listingId - ID of the listing to remove
     */

    ///@notice - Internal function to add a listing to storage

    // /**
    //  * @dev Add listing to storage
    //  * @param listing - Listing to add
    //  */
    // function _addListingStorage(Listing memory listing) internal {
    //     uint id = listing.id;
    //     //uint tokenId = listing.tokenId;
    //     listingIdToListing[id] = listing;
    //     addrToActiveListings[msg.sender].add(id);
    //     //tokenIdToListing[tokenId] = listing;
    //     openListings.add(id);
    // }

    function removeListingStorage() internal {
        addrToActiveListings[msg.sender].remove(listingId);
        openListings.remove(listingId);
    }

    ///@notice - Get all active listings
    function getAllActiveListings() external view returns (Listing[] memory) {
        uint256[] memory allActiveListings = openListings.values();
        uint256 length = allActiveListings.length;
        Listing[] memory allListings = new Listing[](length);

        for (uint i = 0; i < length; ) {
            allListings[i] = listingIdToListing[allActiveListings[i]];
            unchecked {
                ++i;
            }
        }

        return allListings;
    }

    ///@notice - Get owner of contract and make it a payable address
    function getOwner() internal view returns (address payable) {
        address owner = owner();
        return payable(owner);
    }

    function _getOwner() internal view returns (address payable) {
        Collection addr = Collection(_collectionAddress);
        (bool success, bytes memory data) = address(addr).call(
            abi.encodeWithSignature("owner()")
        );
        require(success, "Call failed");
        address result = abi.decode(data, (address));
        return result;
    }

    /////////////////////MODIFIERS///////////////////////////////
    ///@notice - Modifier to check if the caller is the owner of the token.
    modifier onlyCollectionOwner(
        address _collectionAddress,
        uint256 _listingId
    ) {
        Collection addr = Collection(_collectionAddress);
        (bool success, bytes memory data) = address(addr).call(
            abi.encodeWithSignature("owner()")
        );
        require(success, "Call failed");
        address result = abi.decode(data, (address));
        if (result != msg.sender) revert ERC1155NotOwner();
    }

    //only nftItemOwner can call
    modifier onlyNftItemOwner(address _collectionAddress, uint256 _tokenId) {
        if (IERC1155(_nftAddress).balanceOf(msg.sender, _tokenId) == 0)
            revert NotOwner();
        _;
    }

    modifier hasApprovalERC155(address _collectionAddress) {
        if (
            IERC1155(_collectionAddress).isApprovedForAll(
                msg.sender,
                address(this)
            ) == false
        ) revert ERC1155ApprovalRequired();
        _;
    }

    modifier notListed(address _collectionAddress) {
        if (isCollectionListed[_collectionAddress][_ListingId] == true)
            revert ERC1155AlreadyListed();
        _;
    }
}