// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import { ERC1155 } from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import { ERC1155Supply } from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";


contract Collection is ERC1155Supply, Ownable{
    using Counters for Counters.Counter;
    
    /// @dev - Boolean to check if collection has been minted
    bool minted;

     ///@notice - Counters for tokenIDs
    Counters.Counter private tokenID;

    ///@notice - Mapping for tokenURIs
    mapping(uint256 => string) public tokenURIs;

    ///@notice error when uri for non-existent collection is queried
    error NonExistentToken();
    //@notice when array lengths are not equal
    error ArrayLengthsNotEqual();

    
    ///@dev hardcoded marketplace address for easy approval
    address public marketPlace; //update the market address here once the marketplace contract is deployed
    string public collectionInfoHash; //CollectionInfo Hash(cid of collection)
    uint[] public quantities; //the quantities of each token
    string[] public allTokenURIs; //an array of all tokenURIs
    uint256[] public token_ids; //an array of all tokenIDs 

     /*
    constructor is executed when the factory contract calls its own deployERC1155 method
    */
    constructor(
        string memory _collectionInfoHash,  //hash of CollectionInfo, not contractHash
        string[] memory _hashOfNFTItems,  //hash cids of individual nft items in an array
        uint256[] memory _ids,
        uint256[] memory _quantities,
        address owner
    )  ERC1155("") {
        if(_hashOfNFTItems.length != _quantities.length || _hashOfNFTItems.length != _ids.length)
        {
        revert ArrayLengthsNotEqual();
        }

        collectionInfoHash = _collectionInfoHash;
        quantities = _quantities;
        allTokenURIs = _hashOfNFTItems;
        token_ids = _ids;   

        for(uint i = 0; i < _hashOfNFTItems.length; i++) {
            tokenID.increment();
            tokenURIs[tokenID.current()] = _hashOfNFTItems[i];
        }

        transferOwnership(owner);  
    }

    ///@dev Returns the number of child tokens deployed.
    function getTotalChildren() public view returns (uint256) {
        return tokenID.current();
    }

    
    ///@dev necessary override of _beforeTokenTransfer See {ERC1155-_beforeTokenTransfer}.
       function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

     /**
     * @dev Returns the token uri for a token ID
     * @param _id uint256 ID of the token uri
     * @return tokenURIs of token ID
     */
    function uri(uint256 _id) public view override returns (string memory) {
        if (!exists(_id)) revert NonExistentToken();
        return tokenURIs[_id];
    }

     ///@dev mints all the tokens specified for this collection
     function mintAll() external onlyOwner {
        require(!minted);
       _mintBatch(msg.sender, token_ids, quantities, ""); 
       minted = true;
    }

    ///@dev sets approval for the marketplace, pass in approved as true or false depending on if you want to set or revoke approval
    function setApprovalforAll(address _operator, bool _approved) 
    public 
     {
        if(_operator == marketPlace) {
            setApprovalforAll(_operator, _approved);
        }
    }

    //you could also use this to set approval for the marketplace

    //   /**
    //  * Override isApprovedForAll to whitelist marketPlace for all token owners
    //  */
    // function isApprovedForAll(address owner, address operator)
    //     public
    //     view
    //     override
    //     returns (bool)
    // {
    //     if(operator == marketPlace) return true;
    //     return super.isApprovedForAll(owner, operator);
    // }


}