// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

///@dev This contract is in charge of managing the state of all artists on the muse platform
contract Artists {
    // ///@notice - Raised when an address is already an artist.
    // error AlreadyAnArtistErr(string message);
    // ///@notice - Raised when a non-artist address tries to call an artist-only function.
    // error OnlyArtistsErr();

    ///@dev Artist ID counter
    uint public artistCount;

    ///@dev mapping to check if an address is an artist
    mapping(address => bool) public isArtist;

    ///@dev mapping of an artist's address to artist struct
    mapping(address => Artist) public addressToArtist;

    struct Artist {
        uint id;
        uint dateJoined;
        address artistAddress;
        string artistDetails;
    }

    ///@dev event for new artist sign up
    event newArtistJoined(uint id, uint dateJoined, address artistAddress, string artistDetails);

    ///@dev Array to store all artists
    Artist[] public artists;

    ///@dev  modifier for only artists
    modifier onlyArtists() {
        require(isArtist[msg.sender] == true, "you are not an artist" );
        _;
    }

    ///@dev modifier for only non artists
    modifier onlyNonArtists() {
        require(isArtist[msg.sender] == false, "you are already an artist");
        _;
    }

    ///@dev function for signing up new artists
    ///@param _artistDetails - cid hash of artist's details
    function newArtistSignup(string memory _artistDetails) external onlyNonArtists {
        require(bytes(_artistDetails).length > 0);
        artistCount++;
    }
    Artist memory newArtist = Artist({
        id: artistCount,
        dateJoined: block.timestamp,
        artistAddress: msg.sender,
        artistDetails: _artistDetails
    });
     isArtist[msg.sender] = true;
     artists.push(newArtist);
     addressToArtist[msg.sender] = newArtist;

     emit newArtistJoined(artistCount, block.timestamp, msg.sender, _artistDetails);

    //TO-DO
    // a function to get a random artist (creator of the day)
    // a function to get a random collection, could be in another file, I just put it here so I won't forget

    ///@dev function to update artist details
    function updateArtistDetails (string memory _newArtistDetails, uint256 _artistId) external onlyArtists {
        require(artists[_artistId].artistAddress == msg.sender);
        artists[_artistId].artistAddress = _newArtistDetails;
    }

    ///@dev function to get all artists
    function getAllArtists() external view returns(Artist[] memory) {
        return artists;
    }

    ///@dev function to check if an address is an artist
    function checkIfArtist() external view returns (bool) {
        return isArtist[msg.sender];
    }


}