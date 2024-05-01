// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "../BaseAssignment.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

// Create contract > define Contract Name
interface INFTminter {
    
    // Mint a nft and send to _address.
    function mint(address _address) external payable returns (uint256);

    // Burn a nft.
    function burn(uint256 tokenId) external payable;

    // Flip sale status.
    function pauseSale() external;

    // Flip sale status.
    function activateSale() external;

    // Get sale status.
    function getSaleStatus() external view returns (bool);

    // Withdraw all funds to owner.
    function withdraw(uint256 amount) external;

    // Get current price.
    function getPrice() external view returns (uint256);

    // Get total supply.
    function getTotalSupply() external view returns (uint256);

    // Get IPFS hash.
    function getIPFSHash() external view returns (string memory);
}
//RC721URIStorage

contract NFTMinter is ERC721URIStorage, INFTminter, Ownable, BaseAssignment {
    using Strings for uint256;
    using Strings for address;

    bool public isSaleActive=true;
    uint256 public _currentTokenId = 0;
    uint256 public _totalSupply=0;
    uint256 public currentPrice=0.0001*(10**18);
    uint256 public INITIAL_PRICE = 0.0001*(10**18); 
    uint256 public MAX_PRICE = 0.049*(10**18); 
    uint256 public PRICE_REDUCTION =0.0001*(10**18); 
    uint256 public BURN_FEE =0.0001*(10**18); 
    string public ipfsHash= "QmWBr68qz3oeWBU8hY7rpEoR5f3AWBFJj6NBc71YMimqpw";

    constructor(address _initialOwner)
    BaseAssignment(0x43E66d5710F52A2D0BFADc5752E96f16e62F6a11)
    ERC721("Artwork", "ART")
    Ownable(_initialOwner)
    {}
    
    function mint(address _address) public payable override returns (uint256) {
        require(msg.value >= getPrice(), "Insufficient payment");
        require(getSaleStatus()==true);

        _currentTokenId++;
        _totalSupply++;

        
        string memory tokenURI=getTokenURI(_currentTokenId, _address);

        _mint(_address, _currentTokenId);
        _setTokenURI(_currentTokenId, tokenURI);

        if(_currentTokenId>1){
            uint256 currentSupply = _totalSupply;
            currentPrice = INITIAL_PRICE * (2 ** currentSupply);
        }

        return _currentTokenId;
    }

    function getTokenURI(uint256 tokenId, address newOwner) public view returns(string memory){
        bytes memory dataURI= abi.encodePacked(
            "{",
            '"name": "My beautiful artwork #',
            tokenId.toString(),
            '"',
            '"hash": "',
            ipfsHash,
            '",',
            '"by": "',
            owner(),
            '",',
            "0x_OWNER",
            '",',
            '"new_owner":"',
            newOwner,
            '"',
            "}"
        );

        return 
    
            string.concat(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                
            );
    }

    

    function getTotalSupply() public view override returns(uint256){
        return _totalSupply;
    }

    function getIPFSHash() public view override returns (string memory){
        return ipfsHash;
    }

    function getPrice() public view override returns(uint256){
        return currentPrice;
    }

    function burn(uint256 TokenId) public payable override {
        require(ownerOf(TokenId) == msg.sender, "Only the owner can burn the token");
        require(msg.value >= BURN_FEE, "Insufficient burn fee");

        _burn(TokenId);
        _totalSupply--;

        currentPrice = currentPrice-0.0001 ether > INITIAL_PRICE? currentPrice-0.0001 ether : INITIAL_PRICE ;

    }
    function getSaleStatus() public view override returns (bool){
        return isSaleActive;
    }

    function pauseSale() public override{
        require(isValidator(msg.sender)||msg.sender==owner(), "This address is not the owner or the validator");
        isSaleActive=false;
    }

    function activateSale() public override{
        require(isValidator(msg.sender)||msg.sender==owner(), "This address is not the owner or the validator");
        isSaleActive=true;
    }

    function withdraw(uint256 amount) public override{
        require(isValidator(msg.sender)||msg.sender==owner(), "This address is not the owner or the validator");
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}
