// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Pausable} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract Web3Builders is ERC1155, Ownable, ERC1155Pausable, ERC1155Supply, PaymentSplitter {
  
    uint256 public publicPrice = 0.02 ether;
    uint256 public allowListPrice = 0.01 ether;

    uint256 public maxSupply = 20;
    uint256 public maxPerWallet = 3;

    bool public publicMintOpen = true;
    bool public allowListMintOpen = true;

    mapping(address => bool) public allowList;
    mapping(address => uint256) public purchasesPerWallet;
  
    constructor(
        address initialOwner, 
        address[] memory _payees,
        uint256[] memory _shares
        )
        ERC1155("ipfs://bafybeid5vcxajzjhca53mf5kf534uirfqapccojexiopndsyos4rl3vzuu/")
        Ownable(initialOwner)
        PaymentSplitter(_payees, _shares)
    {}

    //Create an edit function that will edit the mint windows:

    function editMintWindows(bool _publicMintOpen, bool _allowListMintOpen ) external onlyOwner {
        publicMintOpen = _publicMintOpen;
        allowListMintOpen = _allowListMintOpen;
    }

    //Funtion to set the allowList

    function setAllowList(address[] calldata addresses) external onlyOwner {
        
        for (uint256 i; i < addresses.length; i++) 
        {
            allowList[addresses[i]] = true;
        }
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function allowListMint(uint256 id,uint256 amount) public payable  {
        
        require(allowListMintOpen, "Allow List mint is closed");
        require(allowList[msg.sender], "Sorry! You are not in allowList"); 
        require(msg.value == allowListPrice * amount, "Wrong! Not Enough funds");
        mint(id, amount);
       
    }


    //add supply tracking
    function publicMint(uint256 id, uint256 amount)
        public 
        payable
         
    {
        require(publicMintOpen, "Public Mint Closed");
        require(msg.value == publicPrice * amount, "Wrong! Not Enough Money Sent");
         mint(id, amount);
    }

    function mint(uint256 id, uint256 amount) internal  {
        require(purchasesPerWallet[msg.sender] + amount <= maxPerWallet , "Wallet Limit Reached");
        require(id < 2, "Sorry, you are minting the wrong NFT");
        require(totalSupply() + amount <= maxSupply, "Sorry, We are minted out!");
        _mint(msg.sender, id, amount, "");
         purchasesPerWallet[msg.sender] += amount;
    }

    function withdraw(address _addr) external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_addr).transfer(balance);
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
    require(exists(_id), "URI not existent token");
    return string(abi.encodePacked(super.uri(_id), Strings.toString(_id), ".json"));
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Pausable, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}
