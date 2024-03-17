PolymerL2CrosschainToken
PolymerL2CrosschainToken is an ERC20 token contract with extended functionality to support cross-chain transfers using the IBC protocol. It inherits from OpenZeppelin's ERC20 contract and a custom UniversalChanIbcApp contract to handle IBC-related logic.

# Cross-Chain Transfer Functions

## crosschainTransfer
```function crosschainTransfer(address destPortAddr, bytes32 channelId, address to, uint256 amount) public```

Initiates a cross-chain transfer of tokens from the caller's account to a specified address on a destination chain. The function checks if the caller has enough balance, encodes the transfer details into a payload, and sends it as an IBC packet through the IBC middleware. The tokens are burned on the source chain to ensure they are not double-spent.

### Workflow:
1. The function checks if the caller has a sufficient balance to cover the transfer amount.
2. The transfer details (sender address, recipient address, and amount) are encoded into a payload.
3. A timeout timestamp is set to ensure the transfer doesn't hang indefinitely.
4. The IBC packet, containing the payload and timeout, is sent to the destination chain's application address via the specified IBC channel.
5. The specified amount of tokens is burned from the sender's account on the source chain.

## crosschainTransferFrom
```function crosschainTransferFrom(address destPortAddr, bytes32 channelId, address from, address to, uint256 amount) public```

Allows a third party to initiate a cross-chain transfer on behalf of the token holder, provided they have been given the necessary allowance. This function is similar to crosschainTransfer but adds an allowance check for the from address.

### Workflow:
1. The function checks if the from address has a sufficient balance and if the caller has been given enough allowance to cover the transfer amount.
2. If the caller is not the token holder, the allowance is decreased by the transfer amount.
3. The transfer details are encoded into a payload, and a timeout timestamp is set.
4. The IBC packet is sent to the destination chain's application address via the specified IBC channel.
5. The specified amount of tokens is burned from the from account on the source chain.

## onRecvUniversalPacket
```function onRecvUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override returns (AckPacket memory ackPacket)```

Handles the receipt of a cross-chain transfer packet on the destination chain. The function decodes the transfer details from the packet, mints the specified amount of tokens to the recipient, and returns an acknowledgment packet.

Workflow
1. The function extracts the transfer details (sender address, recipient address, and amount) from the received IBC packet.
2. The specified amount of tokens is minted to the recipient's account on the destination chain.
3. An acknowledgment packet is created, containing the transfer details, and returned to indicate successful receipt and processing of the transfer.
## onUniversalAcknowledgement
```function onUniversalAcknowledgement(bytes32 channelId, UniversalPacket memory packet, AckPacket calldata ack) external override```

Handles the acknowledgment of a successful cross-chain transfer. This function is called when the destination chain acknowledges the receipt and processing of the transfer packet.

### Workflow: 
1. The function extracts the transfer details from the acknowledgment packet.
2. Since the tokens have already been burned on the source chain and minted on the destination chain, no further action is required in this function. However, this is where you could implement additional logic, such as granting an NFT to the sender as a reward for the cross-chain transfer.

## onTimeoutUniversalPacket
```function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override```

Handles the timeout of a cross-chain transfer packet. If the transfer packet does not get processed within the specified timeout period, this function is called to return the funds to the sender on the source chain.

Workflow
1. The function extracts the transfer details (sender address, recipient address, and amount) from the timed-out packet.
2. The specified amount of tokens is minted back to the sender's account on the source chain, effectively returning the funds that were initially burned for the transfer.

These functions work together to enable secure and efficient cross-chain transfers of tokens using the IBC protocol. The burning and minting of tokens ensure that the total supply remains constant across both chains, preventing double-spending and ensuring the integrity of the transfer process.

# Issued Problems on development

1. When run command `just install` on my forge there are not flag --shallow. The console output:
`
ippolit@MacBook-Pro-ippolit ~/Dapps/ibc-app-solidity-template % just install        
echo "Installing dependencies"
Installing dependencies
npm install

up to date, audited 587 packages in 3s

97 packages are looking for funding
  run `npm fund` for details

2 vulnerabilities (1 low, 1 moderate)

To address all issues, run:
  npm audit fix

Run `npm audit` for details.
forge install --shallow
error: unexpected argument '--shallow' found

  tip: to pass '--shallow' as a value, use '-- --shallow'

Usage: forge install [OPTIONS] [DEPENDENCIES]...
    forge install [OPTIONS] <github username>/<github project>@<tag>...
    forge install [OPTIONS] <alias>=<github username>/<github project>@<tag>...
    forge install [OPTIONS] <https:// git url>...

For more information, try '--help'.
error: Recipe `install` failed on line 5 with exit code 2
`

We fixed that by adjusting in Justfile install instruction. Removed the --shallow flag.
`
# Install dependencies
install:
    echo "Installing dependencies"
    npm install
    forge install
`


ippolit@MacBook-Pro-ippolit ~/Dapps/ibc-app-solidity-template % just deploy optimism base
echo "Deploying contracts with Hardhat..."
Deploying contracts with Hardhat...
node scripts/private/_deploy-config.js optimism base
Contract PolymerL2CrosschainToken deployed to 0x2ECcd0f66154F581367a99d8dE432Cec821562c9 on network base


          ✅   Deployment Successful   ✅
          -------------------------------
          📄 Contract Type: PolymerL2CrosschainToken
          📍 Address: 0x2ECcd0f66154F581367a99d8dE432Cec821562c9
          🌍 Network: base
          -------------------------------

      
🆗 Updated config/polymer-l2-crosschain-token-config.json with address 0x2ECcd0f66154F581367a99d8dE432Cec821562c9 on network base
Contract PolymerL2CrosschainToken deployed to 0xCEcCB760C8eA1Eb710924F68C873445A3d26eF00 on network optimism


          ✅   Deployment Successful   ✅
          -------------------------------
          📄 Contract Type: PolymerL2CrosschainToken
          📍 Address: 0xCEcCB760C8eA1Eb710924F68C873445A3d26eF00
          🌍 Network: optimism
          -------------------------------

      
🆗 Updated config/polymer-l2-crosschain-token-config.json with address 0xCEcCB760C8eA1Eb710924F68C873445A3d26eF00 on network optimism

ippolit@MacBook-Pro-ippolit ~/Dapps/ibc-app-solidity-template % yarn hardhat verify 0xCEcCB760C8eA1Eb710924F68C873445A3d26eF00 0x34a0e37cCCEdaC70EC1807e5a1f6A4a91D4AE0Ce --network optimism
yarn run v1.22.17
$ /Users/ippolit/Dapps/ibc-app-solidity-template/node_modules/.bin/hardhat verify 0xCEcCB760C8eA1Eb710924F68C873445A3d26eF00 0x34a0e37cCCEdaC70EC1807e5a1f6A4a91D4AE0Ce --network optimism
[INFO] Sourcify Verification Skipped: Sourcify verification is currently disabled. To enable it, add the following entry to your Hardhat configuration:

sourcify: {
  enabled: true
}

Or set 'enabled' to false to hide this message.

For more information, visit https://hardhat.org/hardhat-runner/plugins/nomicfoundation-hardhat-verify#verifying-on-sourcify
Successfully submitted source code for contract
contracts/PolymerL2CrosschainToken.sol:PolymerL2CrosschainToken at 0xCEcCB760C8eA1Eb710924F68C873445A3d26eF00
for verification on the block explorer. Waiting for verification result...

Successfully verified contract PolymerL2CrosschainToken on the block explorer.
https://optimism-sepolia.blockscout.com/address/0xCEcCB760C8eA1Eb710924F68C873445A3d26eF00#code

✨  Done in 10.84s.


ippolit@MacBook-Pro-ippolit ~/Dapps/ibc-app-solidity-template % yarn hardhat verify 0x2ECcd0f66154F581367a99d8dE432Cec821562c9 0x50E32e236bfE4d514f786C9bC80061637dd5AF98 --network base              
yarn run v1.22.17
$ /Users/ippolit/Dapps/ibc-app-solidity-template/node_modules/.bin/hardhat verify 0x2ECcd0f66154F581367a99d8dE432Cec821562c9 --network base
[INFO] Sourcify Verification Skipped: Sourcify verification is currently disabled. To enable it, add the following entry to your Hardhat configuration:

sourcify: {
  enabled: true
}

Or set 'enabled' to false to hide this message.

For more information, visit https://hardhat.org/hardhat-runner/plugins/nomicfoundation-hardhat-verify#verifying-on-sourcify
The contract 0x2ECcd0f66154F581367a99d8dE432Cec821562c9 has already been verified on Etherscan.
https://base-sepolia.blockscout.com/address/0x2ECcd0f66154F581367a99d8dE432Cec821562c9#code
✨  Done in 1.50s.


2. Try to make crosschainTransfer on optimism

https://optimism-sepolia.blockscout.com/tx/0x8b2e14c5db7adee9728cbd1b0d0fa388f80cf7b298bddbe455a7e8996e2e2948
https://optimism-sepolia.blockscout.com/tx/0xc569a2b0049c1f583c0217dbbf293e865343cba32f025c9a0bf58b83e740e4ff

And on base

https://base-sepolia.blockscout.com/tx/0x3668e49960515b2007587c84712b8b1c4499a46acea8181459f981147a236221

We saw this transactions on https://sepolia.polymer.zone/packets but there are all relaying.