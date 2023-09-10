// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Interfaces, Libraries, Contracts
error NFTDepositContract__NotOwner();
error NFTDepositContract__InsufficientBalance();
error NFTDepositContract__TransferFailed();

contract NFTDepositContract is ERC721 {
    string public constant TOKEN_URI =
        "ipfs://QmNaLF1AXgq1zmBAeipoVsRW6bcw4w8aax9tsFJbbgc1Ci";
    uint256 private s_tokenCounter;
    uint256 private s_depositFee;
    uint256 private s_feesGenerated;
    address private immutable i_owner;
    mapping(uint256 => uint256) public s_tokenIdToBalance;

    // Events
    event ValueSent(
        uint256 indexed fromTokenId,
        address recipient,
        uint256 amount
    );
    event DepositFeeSet(uint256 indexed fee);

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert NFTDepositContract__NotOwner();
        _;
    }

    constructor(uint256 depositFee) ERC721("Ethereal Card", "CARD") {
        s_tokenCounter = 0;
        s_depositFee = depositFee;
        i_owner = msg.sender;
    }

    function mint(address _to) public payable {
        require(msg.value > 0, "Deposit Value Too Low");
        _safeMint(_to, s_tokenCounter);
        uint256 fee = msg.value / s_depositFee;
        s_feesGenerated += fee;
        s_tokenIdToBalance[s_tokenCounter] = msg.value - fee;
        s_tokenCounter = s_tokenCounter + 1;
    }

    function sendValue(
        uint256 amount,
        address recipient,
        uint256 tokenId
    ) public onlyOwner {
        require(amount > 0, "Send Value Too Low");
        if (s_tokenIdToBalance[tokenId] < amount) {
            revert NFTDepositContract__InsufficientBalance();
        }
        s_tokenIdToBalance[tokenId] -= amount;
        (bool success, ) = payable(recipient).call{value: amount}("");
        if (success) {
            emit ValueSent(tokenId, recipient, amount);
        } else {
            revert NFTDepositContract__TransferFailed();
        }
    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return TOKEN_URI;
    }

    function withdrawFees() public onlyOwner {
        require(s_feesGenerated > 0, "No Fees Generated");
        (bool success, ) = payable(msg.sender).call{value: s_feesGenerated}("");
        if (!success) {
            revert NFTDepositContract__TransferFailed();
        }
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getTokenBalance(uint256 tokenId) public view returns (uint256) {
        return s_tokenIdToBalance[tokenId];
    }

    function getDepositFee() public view returns (uint256) {
        return s_depositFee;
    }

    function setDepositFee(uint256 depositFee) public onlyOwner {
        s_depositFee = depositFee;
        emit DepositFeeSet(depositFee);
    }

    function getFeesGenerates() public view returns (uint256) {
        return s_feesGenerated;
    }
}
