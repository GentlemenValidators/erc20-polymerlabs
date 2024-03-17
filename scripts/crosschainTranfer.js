// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require('hardhat');
const { ethers } = require('hardhat')
const { getConfigPath } = require('./private/_helpers');

async function main() {
    const [ sender ] = await hre.ethers.getSigners();
    const config = require(getConfigPath());
    const crosschainTransferConfig = config.crosschainTransfer;

    const networkName = hre.network.name;
    // Get the contract type from the config and get the contract
   
    // Do logic to prepare the crosschainTransfer
    // If the network we are sending from is optimism, we need to use the base port address and vice versa
    const srcPortAddr = networkName === "optimism" ?
        crosschainTransferConfig["optimism"]["portAddr"]:
        crosschainTransferConfig["base"]["portAddr"];
    // If the network we are sending on is optimism, we need to use the base port address and vice versa
    const destPortAddr = networkName === "optimism" ?
      crosschainTransferConfig["base"]["portAddr"] :
      crosschainTransferConfig["optimism"]["portAddr"];
    
    const srcChannelId = networkName == "optimism" ?
        crosschainTransferConfig["optimism"]["channelId"]:
        crosschainTransferConfig["base"]["channelId"]
    const srcChannelIdBytes = hre.ethers.encodeBytes32String(srcChannelId);
   
    const to = sender.address
    const amount = 12_000_000

    // instantiate contract instance
    const token = await ethers.getContractAt("PolymerL2CrosschainToken", srcPortAddr)
    // make crosschain transfer
    const tx = await token.crosschainTransfer(destPortAddr, srcChannelIdBytes, to, amount)
    console.log("crosschainTransfer TX hash: ", tx.hash)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});