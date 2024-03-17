//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.23;

import "./base/UniversalChanIbcApp.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PolymerL2CrosschainToken is ERC20, UniversalChanIbcApp {

    constructor (address _middleware) ERC20("Polymer L2 Crosschain Token", "PCT") UniversalChanIbcApp(_middleware) {
        uint256 initialMintAmount = 1000 * 10 ** decimals();
        _mint(owner(), initialMintAmount);
    }

    /**
     * @dev mints the token to the owner of token
     * @param amount the token amount to mint to owner
     */
    function mint(uint256 amount) public {
        require(msg.sender == owner(), "PolymerL2CrosschainToken: msg.sender is not owner");
        _mint(msg.sender, amount);
    }

    /**
     * @dev burns the token from msg.sender
     * @param amount the token amount to burn from `msg.sender`
     */
    function burn(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "PolymerL2CrosschainToken: not enougth tokens to burn");
        _burn(msg.sender, amount);
    }

    // IBC 

    /**
     * @dev make the crosschain transfer
     * @param destPortAddr The address of the destination application.
     * @param channelId The ID of the channel to send the packet to.
     */
    function crosschainTransfer(address destPortAddr, bytes32 channelId, address to, uint256 amount) public {
        address from = msg.sender;
        crosschainTransferFrom(destPortAddr, channelId, from, to, amount);
    }

    /// @dev 
    function crosschainTransferFrom(address destPortAddr, bytes32 channelId, address from, address to, uint256 amount) public {
        require(balanceOf(from) >= amount, "PolymerL2CrosschainToken: amount exceeded balance");
        
        if (from != msg.sender) {
            require(allowance(from, msg.sender) >= amount, "PolymerL2CrosschainToken: crosschain transfer amount exceeds allowance");
            decreaseAllowance(from, amount);
        }
        bytes memory payload = abi.encode(from, to, amount);
        uint64 timeoutTimestamp = uint64(block.timestamp) + 2 hours;
        IbcUniversalPacketSender(mw).sendUniversalPacket(
            channelId, IbcUtils.toBytes32(destPortAddr), payload, timeoutTimestamp
        );
        // funds sent. burn on source chain
        _burn(from, amount);
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
     *      Also mint the amount to `to`
     * @param channelId the ID of the channel (locally) the packet was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     */
    function onRecvUniversalPacket(bytes32 channelId, UniversalPacket calldata packet)
        external
        override
        onlyIbcMw
        returns (AckPacket memory ackPacket)
    {
        recvedPackets.push(UcPacketWithChannel(channelId, packet));

        (address from, address to, uint256 amount) = abi.decode(packet.appData, (address, address, uint256));
        // funds received. mint it on destination chain       
        _mint(to, amount);

        return AckPacket(true, abi.encode(from, to, amount));
    }

    /**
     * @dev Packet lifecycle callback that implements packet acknowledgment logic.
     *      If crosschain transfer is successful, than this function is called.
     * @param channelId the ID of the channel (locally) the ack was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
     */
    function onUniversalAcknowledgement(bytes32 channelId, UniversalPacket memory packet, AckPacket calldata ack)
        external
        override
        onlyIbcMw
    {
        ackPackets.push(UcAckWithChannel(channelId, packet, ack));

        // decode the crosschainTrasfer data from the ack packet
        (address from, address to, uint256 amount) = abi.decode(ack.data, (address, address, uint256));

        // the funds is received on destination chain, so there are no need to do something. May be grant NFT
    }

    /**
     * @dev if crosschainTransfer packet is timed out, than we return funds back to sender
     * @param channelId the ID of the channel (locally) the timeout was submitted on.
     * @param packet the Universal packet encoded by the counterparty and relayed by the relayer
     */
    function onTimeoutUniversalPacket(bytes32 channelId, UniversalPacket calldata packet) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
        (address from, address to, uint256 amount) = abi.decode(packet.appData, (address, address, uint256));

        // funds not tranfered to receiver on destination chain. So we return back the funds to the sender
        _mint(from, amount);
    }

}
