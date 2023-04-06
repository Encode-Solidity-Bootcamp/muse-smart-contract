//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./Collection.sol";

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

    using EnumerableSet for EnumerableSet.UintSet;
    //using Bytes32ToBytes32Map for Bytes32ToBytes32Map.Map;
    using Counters for Counters.Counter;

    //Collection public nft;

    ///@dev Counter for listings
    Counters.Counter private listingId;
    Counters.Counter private nftId;

    //Counters.Counter private listedCount;

    //Counters.Counter private soldCount;

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
    mapping(uint256 => CollectionListing) private listingIdToCollectionListing; //mapping saving listings

    mapping(address => mapping(uint256 => bool)) public isCollectionListed;

    //COllectionListing sets
    EnumerableSet.UintSet listedNFTItemsId; //listed nft ids
    mapping(uint256 => EnumerableSet.UintSet)
        private listingIdTolistedNFTItemsIds;

    EnumerableSet.UintSet soldNFTItemsId; //sold nft ids
    mapping(uint256 => EnumerableSet.UintSet)
        private listingIdToSoldNFTItemsIds;

    //mapping(uint256 => Counters.Counter[]) private listingIdToListedNftCount;
    //mapping(uint256 => Counters.Counter[]) private listingIdToSoldNftCount;

    mapping(uint256 => uint256[]) private listingIdTosoldTokenIds;

    //mapping(uint256 => Listing) private tokenIdToListing;
    //mapping(address => mapping(uint256 => bool)) isTokenListed;

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
        uint256 quantity;
        address collectionAddress;
        address payable seller;
        State state;
        //NFTItems[] nfts;
        //EnumerableMap.Bytes32ToBytes32Map nftItemsMap;
        uint256[] allTokenIds;
        Counters.Counter listedCount;
        Counters.Counter soldNftCount;
    }

    struct NFTItems {
        uint256 tokenId;
        bool sold;
        address seller;
        //bool listed;
    }

    NFTItems[] public _nfts;

    // struct NFTItemsListing {
    //     uint256 tokenId;
    //     bool sold;
    // }

    event CollectionListingCreated(
        uint256 _price,
        uint256 indexed _listingId,
        address indexed _collectionAddress,
        address indexed _seller
    );

    function listCollection(
        address _collectionAddress,
        uint256 _price,
        uint256 _quantity
    )
        public
        onlyCollectionOwner(_collectionAddress)
        hasApprovalERC155(_collectionAddress)
        returns (uint256)
    {
        //require that this function can only be called by collection owner
        //EnumerableMap.Bytes32ToBytes32Map memory nftItemMap;

        Collection c = Collection(_collectionAddress);
        (bool success, bytes memory _data) = address(c).call(
            abi.encodeWithSignature("token_ids()")
        );
        require(success, "Call failed");
        uint256[] memory _tokenIds = abi.decode(_data, (uint256[]));

        // NFTItems[] memory nfts = new NFTItems[](_tokenIds.length);
        // for (uint i = 0; i < _tokenIds.length && i <= 100; i++) {
        //     NFTItems memory nft = NFTItems(_tokenIds[i], false, msg.sender);
        //     _nfts.push(nft);
        // }

        // for (uint i = 0; i < nfts.length; i++) {
        //     //add unchecked later
        //     bytes32 bytesKey = bytes32(uint256(i + 1));
        //     bytes32 bytesValue;

        //     bytes memory encoded = abi.encode(nfts[i]);
        //     assembly {
        //         bytesValue := mload(add(encoded, 32))
        //     }
        //     nftItemMap.set(bytesKey, bytesValue);
        // }

        //EnumerableSet.UintSet storage _listedTokenIds;

        listingId.increment();

        CollectionListing memory listing = CollectionListing({
            id: listingId.current(),
            price: _price,
            quantity: _quantity,
            collectionAddress: _collectionAddress,
            seller: payable(msg.sender),
            state: State.OPEN,
            //nftItemsMap,
            allTokenIds: _tokenIds,
            listedCount: Counters.Counter(0),
            soldNftCount: Counters.Counter(0)
            //_listedTokenIds
        });

        listingIdToCollectionListing[listing.id] = listing;
        CollectionListing storage storedListing = listingIdToCollectionListing[
            listing.id
        ];

        uint256 currentCount = storedListing.listedCount.current();

        uint256[] memory _allTokenIds = listing.allTokenIds;

        for (
            uint i = (currentCount + 1);
            i <= _quantity && i <= _allTokenIds.length;
            i++
        ) {
            EnumerableSet.UintSet
                storage listedNftIdsSet = listingIdTolistedNFTItemsIds[
                    listingId.current()
                ];
            listedNftIdsSet.add(_allTokenIds[currentCount]);
            //listing.listedNFTItemsId.add(listing._tokenIds[listing.listedCount.current()];

            storedListing.listedCount.increment();
        }

        isCollectionListed[_collectionAddress][listing.id] = true;
        addrToActiveListings[msg.sender].add(listing.id);
        listingIdToCollectionListing[listing.id] = listing;
        openListings.add(listing.id);
        emit CollectionListingCreated(
            _price,
            listingId.current(),
            _collectionAddress,
            msg.sender
        );
        return storedListing.id;
    }

    //function getOwners() {}

    ///@dev function to buy items from a particular collection
    function buyListing(uint256 _listingId, uint256 quantity) external payable {
        uint256 listedNftItemsLength = listingIdTolistedNFTItemsIds[_listingId]
            .length();

        require(
            (quantity <= listedNftItemsLength),
            "can't purchase higher than the quantity listed"
        );
        CollectionListing memory listing = listingIdToCollectionListing[
            _listingId
        ];
        if (listing.state != State.OPEN) revert ListingNotOpen();

        //require that seller has to be the owner of the collection
        Collection addr = Collection(listing.collectionAddress);
        (bool success, bytes memory data) = address(addr).call(
            abi.encodeWithSignature("owner()")
        );
        require(success, "Call failed");
        address addressOwner = abi.decode(data, (address));
        require(listing.seller == addressOwner);

        if (msg.value != listing.price) revert WrongPrice();

        // Counters.Counter memory _soldCount;
        // _soldCount = listing.soldNftCount;

        //uint256[] storage _soldTokenIds =  listingIdTosoldTokenIds[_listingId];
        uint256[] memory _soldTokenIds = new uint256[](quantity);

        uint256[] memory amounts = new uint256[](quantity);

        //= new uint256[](quantity);

        listingIdToCollectionListing[_listingId] = listing;
        CollectionListing storage storedListing = listingIdToCollectionListing[
            listing.id
        ];

        EnumerableSet.UintSet
            storage listedNftIdsSet = listingIdTolistedNFTItemsIds[_listingId];
        EnumerableSet.UintSet
            storage soldNftIdsSet = listingIdToSoldNFTItemsIds[_listingId];

        uint256[] memory _allTokenIds = listing.allTokenIds;
        for (uint i = 0; i <= quantity; i++) {
            uint256 _soldTokenId = listedNftIdsSet.at(_allTokenIds[i + 1]);
            //_soldTokenIds.push(_soldTokenId);
            _soldTokenIds[i] = _soldTokenId;
            listedNftIdsSet.remove(_soldTokenId);
            storedListing.listedCount.decrement();
            soldNftIdsSet.add(_soldTokenId);
            storedListing.soldNftCount.increment();
            amounts[i] = 1;

            // unchecked {
            //     ++i;
            // }
        }

        //listingIdToCollectionListing[listingId] = listing;

        uint royalty = (msg.value * 1) / 100;
        uint sellerFunds = (msg.value * 99) / 100;

        (bool success2, ) = address(this).call{value: royalty}(""); //implement receive later so that this contract can receive funds
        (bool sellerSuccess, ) = listing.seller.call{value: sellerFunds}("");

        // uint256[] memory amounts = new uint256[](quantity.length);
        // for(uint i = 0; i < quantity.length; i++) {
        //     amounts.push(1);
        // }
        if (success2 && sellerSuccess) {
            IERC1155(listing.collectionAddress).safeBatchTransferFrom(
                listing.seller,
                msg.sender,
                _soldTokenIds,
                amounts,
                bytes("")
            );
        } else {
            revert();
        }
    }

    function cancelListing(
        uint256 _listingId
    )
        external
        onlyCollectionOwner(
            listingIdToCollectionListing[_listingId].collectionAddress
            //listingIdToCollectionListing[_listingId].id
        )
    {
        CollectionListing memory listing = listingIdToCollectionListing[
            _listingId
        ];
        if (listing.state != State.OPEN) revert ListingNotOpen();
        listing.state = State.CANCELLED;
        isCollectionListed[listing.collectionAddress][listing.id] = false;

        listingIdToCollectionListing[_listingId] = listing;
    }

    function getListingsByUser(
        address _userAddress
    ) external view returns (CollectionListing[] memory) {
        uint256[] memory userActiveListings = addrToActiveListings[_userAddress]
            .values();
        uint256 length = userActiveListings.length;
        CollectionListing[] memory userListings = new CollectionListing[](
            length
        );

        for (uint i = 0; i < length; ) {
            userListings[i] = listingIdToCollectionListing[
                userActiveListings[i]
            ];
            unchecked {
                ++i;
            }
        }

        return userListings;
    }

    // function resellTokens() {}

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

    function removeListingStorage(uint256 _listingId) internal {
        addrToActiveListings[msg.sender].remove(_listingId);
        openListings.remove(_listingId);
    }

    ///@notice - Get all active listings
    function getAllActiveListings()
        external
        view
        returns (CollectionListing[] memory)
    {
        uint256[] memory allActiveListings = openListings.values();
        uint256 length = allActiveListings.length;
        CollectionListing[] memory allListings = new CollectionListing[](
            length
        );

        for (uint i = 0; i < length; ) {
            allListings[i] = listingIdToCollectionListing[allActiveListings[i]];
            unchecked {
                ++i;
            }
        }

        return allListings;
    }

    // ///@notice - Get owner of contract and make it a payable address
    // function getOwner() internal view returns (address payable) {
    //     address owner = owner();
    //     return payable(owner);
    // }

    function _getOwner(
        address _collectionAddress
    ) internal returns (address payable) {
        Collection addr = Collection(_collectionAddress);
        (bool success, bytes memory data) = address(addr).call(
            abi.encodeWithSignature("owner()")
        );
        require(success, "Call failed");
        address result = abi.decode(data, (address));
        return payable(result);
    }

    /////////////////////MODIFIERS///////////////////////////////
    ///@notice - Modifier to check if the caller is the owner of the token.
    modifier onlyCollectionOwner(
        address _collectionAddress //uint256 _listingId
    ) {
        Collection addr = Collection(_collectionAddress);
        (bool success, bytes memory data) = address(addr).call(
            abi.encodeWithSignature("owner()")
        );
        require(success, "Call failed");
        address result = abi.decode(data, (address));
        if (result != msg.sender) revert ERC1155NotOwner();
        _;
    }

    //only nftItemOwner can call
    modifier onlyNftItemOwner(address _collectionAddress, uint256 _tokenId) {
        if (IERC1155(_collectionAddress).balanceOf(msg.sender, _tokenId) == 0)
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

    modifier notListed(address _collectionAddress, uint256 _ListingId) {
        if (isCollectionListed[_collectionAddress][_ListingId] == true)
            revert ERC1155AlreadyListed();
        _;
    }
}
