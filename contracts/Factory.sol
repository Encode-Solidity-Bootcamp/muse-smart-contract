// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import {Collection} from "./Collection.sol";
import {Artists} from "./Artists.sol";

contract Factory {
    ///@dev artists to an array of collection contracts mapping
    mapping(address => address[]) public artistToCollectionContracts;

    ///@dev variable for the artists contract address
    Artists artistContractAddress;

    constructor(address _artistContractAddress) {
        artistContractAddress = Artists(_artistContractAddress);
    }

    ///@dev an array of all collection contracts
    address[] public allCollections;

    ///@dev an event that is emitted when ERC1155 token is deployed
    event ERC1155Created(address indexed owner, address indexed tokenContract);

    ///@notice Function to deploy ERC1155 contracts (collection contracts)
    function deployERC1155(
        string memory _collectionInfoHash,
        string[] memory _nftItemsHash,
        uint256[] memory _ids,
        uint256[] memory _quantities
    ) public returns (address) {
        Collection addr = new Collection(_collectionInfoHash, _nftItemsHash, _ids, _quantities, tx.origin); //test this to be sure that the address that deployed is the actual owner, if it isn't use tx.origin
        artistToCollectionContracts[msg.sender].push(address(addr));//test this line as well
        allCollections.push(address(addr));
        emit ERC1155Created(msg.sender, address(addr));

        return address(addr);
    }

    ///@dev function to mint all items on the collection contract
    function mintCollection(address _addr) external {
        Collection addr = Collection(_addr);
        (bool success, ) = address(addr).call(abi.encodeWithSignature("mintAll()"));
        require(success);
    }

    ///@dev function to get all the collections created by this artist
    function getAllArtistCollections(address _artist) external view returns (address[] memory) {
        return artistToCollectionContracts[_artist];
    }

      ///@dev function to get all the collections created on the muse platform
    function getAllCollections() external view returns (address[] memory) {
        return allCollections;
    }
}


