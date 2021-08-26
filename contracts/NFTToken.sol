// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract OnlyNFTToken is ERC721 {
    using Counters for Counters.Counter;

    //created _tokenIds variable for incrementing tokenId
    Counters.Counter private _tokenIds;

    constructor() ERC721("NFTToken", "NFTk") {}

    //strucuture of our NFT Item
    
    struct Item {
        uint256 id; //id of the NFT token
        address creator; //creator of the NFT token
        string uri; //to store metadata
    }
    //      tokenId  NFT Item
    mapping(uint256 => Item) public items; 



    function createItem(string memory uri) public returns(uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        items[newItemId] = Item(newItemId, msg.sender, uri);
        return newItemId;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return items[tokenId].uri;
    }
    
     
}
