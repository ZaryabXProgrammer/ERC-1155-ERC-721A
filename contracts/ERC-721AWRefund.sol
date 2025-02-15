// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/ERC721A.sol";
import "https://github.com/exo-digital-labs/ERC721R/blob/main/contracts/IERC721R.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Web3Builders is ERC721A, Ownable {
    uint256 public constant mintPrice = 1 ether;
    uint256 public constant maxMintPerUser = 5;
    uint256 public constant maxMintSupply = 100;

    uint256 public constant refundPeriod = 3 minutes;
    uint256 public refundEndTimestamp;

    address public refundAddress;

    mapping(uint256 => uint256) public refundEndTimestamps;

    mapping(uint256 => bool) public hasRefunded;

    constructor(address initialOwner)
        ERC721A("Web3Builders", "WE3")
        Ownable(initialOwner)
    {
        refundAddress = address(this);
        refundEndTimestamp = block.timestamp + refundPeriod;
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmbseRTJWSsLfhsiWwuB2R7EtN93TxfoaMz1S5FXtsFEUB";
    }

    function safeMint(uint256 quantity) public payable {
        require(msg.value >= mintPrice * quantity, "Not Enough Funds");
        require(
            _numberMinted(msg.sender) + quantity <= maxMintPerUser,
            "Mint Limit"
        );
        require(_totalMinted() + quantity <= maxMintSupply, "Sold Out");
        _safeMint(msg.sender, quantity);
        refundEndTimestamp = block.timestamp + refundPeriod;

        for (uint256 i = _currentIndex - quantity; i < _currentIndex; i++) {
            refundEndTimestamps[i] = refundEndTimestamp;
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;

        Address.sendValue(payable(msg.sender), balance);
    }
}
