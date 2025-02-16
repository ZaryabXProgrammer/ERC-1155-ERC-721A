// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

// Import required contracts
import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/ERC721A.sol";
import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/IERC721R.sol";
import  "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol"; // Added for Address.sendValue

// Main NFT contract that inherits from ERC721A (for gas efficient minting) and Ownable
contract Web3Builders is ERC721A, Ownable, ReentrancyGuard  {
    // Using Address library for safe ETH transfers
    using Address for address payable;

    // Constant values that cannot be changed after deployment
    uint256 public constant mintPrice = 1 ether;      // Price per NFT (1 ETH)
    uint256 public constant maxMintPerUser = 5;       // Maximum NFTs one address can mint
    uint256 public constant maxMintSupply = 100;      // Total supply of NFTs
    uint256 public constant refundPeriod = 3 minutes; // Time window for refunds

    // State variables
    uint256 public refundEndTimestamp;               // Global timestamp for refund deadline
    address public refundAddress;                    // Address where refunded NFTs go

    // Mappings to track refund-related data
    mapping(uint256 => uint256) public refundEndTimestamps; // Tracks refund deadline for each token
    mapping(uint256 => bool) public hasRefunded;            // Tracks if a token has been refunded

    // Constructor runs once when the contract is deployed
    constructor(address initialOwner)
        ERC721A("Web3Builders", "WE3")  // Set NFT collection name and symbol
        Ownable(initialOwner)           // Set contract owner
    {
        refundAddress = address(this);  // Set refund address to contract address
        refundEndTimestamp = block.timestamp + refundPeriod;  // Set initial refund deadline
    }

    // Function to set the base URI for token metadata
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmbseRTJWSsLfhsiWwuB2R7EtN93TxfoaMz1S5FXtsFEUB";
    }

    // Main minting function - allows users to mint NFTs
    function safeMint(uint256 quantity) public payable {
        // Check if enough ETH was sent
        require(msg.value >= mintPrice * quantity, "Not Enough Funds");
        
        // Check if user's mint limit would be exceeded
        require(
            _numberMinted(msg.sender) + quantity <= maxMintPerUser,
            "Mint Limit"
        );
        
        // Check if total supply limit would be exceeded
        require(_totalMinted() + quantity <= maxMintSupply, "Sold Out");

        // Mint the NFTs to the user
        _safeMint(msg.sender, quantity);
        
        // Update refund deadline
        refundEndTimestamp = block.timestamp + refundPeriod;

        // Set refund deadlines for each minted token
        for (uint256 i = _currentIndex - quantity; i < _currentIndex; i++) {
            refundEndTimestamps[i] = refundEndTimestamp;
        }
    }

    // Allows users to refund their NFT for the mint price
    function refund(uint256 tokenId) external nonReentrant  {
        // Check if refund period is still active
        require(block.timestamp < getRefundDeadline(tokenId), "Refund Period Expired");
        
        // Check if sender owns the NFT
        require(msg.sender == ownerOf(tokenId), "Not Your NFT");
        
        // Get refund amount
        uint256 refundAmount = getRefundAmount(tokenId);

        // Transfer NFT to refund address
        _transfer(msg.sender, refundAddress, tokenId);
        
        // Mark token as refunded
        hasRefunded[tokenId] = true;

        // Send refund amount to user using Address.sendValue
        payable(msg.sender).sendValue(refundAmount);
    }

    // Returns the refund deadline for a specific token
    function getRefundDeadline(uint256 tokenId) public view returns(uint256) {
        // If token has been refunded, return 0
        if(hasRefunded[tokenId]){
            return 0;
        }
        // Otherwise return the stored deadline
        return refundEndTimestamps[tokenId];
    }

    // Returns the refund amount for a specific token
    function getRefundAmount(uint256 tokenId) public view returns(uint256){
        // If token has been refunded, return 0
        if(hasRefunded[tokenId]){
            return 0;
        }
        // Otherwise return the mint price
        return mintPrice;
    }

    // Allows owner to withdraw ETH from contract
    function withdraw() external onlyOwner {
        // Check if global refund period has ended
        require(block.timestamp > refundEndTimestamp, "Refund period not over");
        
        // Get contract balance
        uint256 balance = address(this).balance;
        
        // Send balance to owner using Address.sendValue
        payable(msg.sender).sendValue(balance);
    }
}