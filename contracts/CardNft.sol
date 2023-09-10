// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// Interfaces, Libraries, Contracts
error NFTDepositContract__NotOwner();
error NFTDepositContract__InsufficientBalance();
error NFTDepositContract__TransferFailed();

contract Card is ERC721 {
    string public constant TOKEN_URI =
        "ipfs://QmNaLF1AXgq1zmBAeipoVsRW6bcw4w8aax9tsFJbbgc1Ci";
    uint256 private s_tokenCounter;
    uint256 private s_depositFee;
    uint256 private s_feesGenerated;
    uint256 private s_mintPrice = 10;
    address private immutable i_owner;
    IERC20 private immutable i_usdcToken;
    mapping(address => uint256) public s_AdressToBalance;

    // Events
    event ValueSent(
        uint256 indexed amount,
        address indexed sender,
        address indexed recipient
    );

    event DepositFeeSet(uint256 indexed fee);

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NFTDepositContract__NotOwner();
        _;
    }

    constructor(
        uint256 depositFee,
        address usdcAddress
    ) ERC721("Ethereal Card", "CARD") {
        s_tokenCounter = 0;
        s_depositFee = depositFee;
        i_usdcToken = IERC20(usdcAddress); // 0x07865c6E87B9F70255377e024ace6630C1Eaa37F
        i_owner = msg.sender;
        // add function to update owner
    }

    function claimTo(address _to, uint256 _quantity) public payable {
        require(
            i_usdcToken.transferFrom(msg.sender, address(this), _quantity),
            "USDC transfer failed"
        ); // transfer USDC from user to contract
        _safeMint(_to, s_tokenCounter);
        uint256 fee = _quantity / s_depositFee;
        s_feesGenerated += fee;
        s_AdressToBalance[_to] = _quantity - fee;
        s_tokenCounter = s_tokenCounter + 1;
    }

    function sendTokens(
        uint256 amount,
        address sender,
        address recipient
    ) public onlyOwner {
        // require owner of tokenId === sender
        require(amount > 0, "Send Value Too Low");
        if (s_AdressToBalance[sender] < amount) {
            revert NFTDepositContract__InsufficientBalance();
        }
        s_AdressToBalance[sender] -= amount;
        require(
            i_usdcToken.transfer(recipient, amount),
            "USDC transfer failed"
        );
        emit ValueSent(amount, sender, recipient);

        // (bool success, ) = payable(recipient).call{value: amount}("");
        // if (success) {
        //     emit ValueSent(tokenId, recipient, amount);
        // } else {
        //     revert NFTDepositContract__TransferFailed();
        // }
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
        s_feesGenerated = 0;
        require(
            i_usdcToken.transfer(msg.sender, s_feesGenerated),
            "USDC transfer failed"
        );

        // (bool success, ) = payable(msg.sender).call{value: s_feesGenerated}("");
        // if (!success) {
        //     revert NFTDepositContract__TransferFailed();
        // }
    }

    // function simulateTx() public {
    //     uint256 amountToSend = i_usdcToken.balanceOf(address(this)) / 1000;
    //      for (uint256 i = 0; i < 1000; i++) {
    //         ownerOf(0);
    //         i_usdcToken.transfer(msg.sender, amountToSend);
    //     }
    // }

    function getUSDCBal() public view returns (uint256) {
        return i_usdcToken.balanceOf(address(this));

    }

    function getOwnerTest(uint256 tokenId) public view returns (address) {
        return ownerOf(tokenId);
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    function getAddressBalance(address owner) public view returns (uint256) {
        return s_AdressToBalance[owner];
    }

    function getDepositFee() public view returns (uint256) {
        return s_depositFee;
    }

    function setDepositFee(uint256 depositFee) public onlyOwner {
        s_depositFee = depositFee;
        emit DepositFeeSet(depositFee);
    }

    function getFeesGenerated() public view returns (uint256) {
        return s_feesGenerated;
    }
}
