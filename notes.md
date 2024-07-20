- Signature
  `_levelUpNftSignature: bytes32 dataHash = keccak256(
    abi.encodePacked(LEVELUP_ACTION, _tokenId, _creator);
)`
  `_createNftSignature: bytes32 dataHash = keccak256(
      abi.encodePacked(MINT_ACTION, _tokenURI, _creator)
  );`

- NFT Character: (called by owner of NFT contract not owner tokenId)

  - Create NFT: will create the nft character and the ERC6551 account storing the NFT items
  - Level up Character: level up the nft character if possible

- NFT Item & NFT Treasure: ERC-1155

- Centralization: Use the centralized database to store the private key of Game Wallet to represent user signing the transaction.
