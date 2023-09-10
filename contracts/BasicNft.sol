// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error BasicNft__NeedMoreETHSent();
error BasicNft__RoyaltyPaymentFailed();

contract BasicNft is ERC721 {
    string public constant TOKEN_URI =
        "ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json";
    uint256 private s_tokenCounter;
    uint256 private immutable i_mintFee;

    // token 1 is diamond = 10% royalty
    // tokens 2, 3, 4 are gold = 5% royalty each (20% total)

    constructor(uint256 mintFee) ERC721("doggie", "DOG") {
        i_mintFee = mintFee;
        s_tokenCounter = 0;
    }

    // function mintNft(address _to, uint256 _quantity) public returns (uint256) {
    //     _safeMint(msg.sender, s_tokenCounter);
    //     s_tokenCounter = s_tokenCounter + 1;
    //     return s_tokenCounter;
    // }

    function claimTo(address _to, uint256 _quantity)
        public
        payable
        returns (uint256)
    {
        if (msg.value < (i_mintFee * _quantity)) {
            revert BasicNft__NeedMoreETHSent();
        }
        for (uint256 i = 0; i < _quantity; i++) {
            _safeMint(_to, s_tokenCounter);
            s_tokenCounter = s_tokenCounter + 1;
        }
        if (s_tokenCounter > 1) {
            // 9999.045216231176
            address diamondHolder = ownerOf(0);
            uint256 diamondAmount = i_mintFee / 10;
            (bool success, ) = payable(diamondHolder).call{
                value: diamondAmount
            }("");
            if (!success) {
                revert BasicNft__RoyaltyPaymentFailed();
            }
            if (s_tokenCounter > 4) {
                address[] memory goldHolders = new address[](3);
                goldHolders[0] = ownerOf(1);
                goldHolders[1] = ownerOf(2);
                goldHolders[2] = ownerOf(3);

                uint256 goldAmount = i_mintFee / 20;
                for (uint256 i = 0; i < goldHolders.length; i++) {
                    (bool success, ) = payable(goldHolders[i]).call{
                        value: goldAmount
                    }("");
                    if (!success) {
                        revert BasicNft__RoyaltyPaymentFailed();
                    }
                }
            }
        }
    }

    /*     function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert RandomIpfsNft__TransferFailed();
        }
    }*/

    function tokenURI(
        uint256 /*tokenId*/
    ) public view override returns (string memory) {
        return TOKEN_URI;
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    // Enumerable mapping from token ids to their owners
    // EnumerableMap.UintToAddressMap private _tokenOwners;
    function getTokenOwners() public view returns (address[] memory) {
        address[] memory owners = new address[](s_tokenCounter);
        for (uint256 i = 0; i < s_tokenCounter; i++) {
            owners[i] = (ownerOf(i));
        }
        return owners;
    }

    function getMintFee() public view returns (uint256) {
        return i_mintFee;
    }

    // ipfs://bafybeig37ioir76s7mg5oobetncojcm3c3hxasyd4rvid4jqhy4gkaheg4/?filename=0-PUG.json
    // https://res.cloudinary.com/alchemyapi/image/upload/thumbnailv2/matic-mainnet/012ef94f85be07ecc5c6855cef41be9d
}
