// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../contracts/PolymerL2CrosschainToken.sol";
import "@open-ibc/vibc-core-smart-contracts/contracts/libs/Ibc.sol";

contract MockMiddleware {
    event UniversalPacketSent(bytes32 channelId, bytes32 destPortAddr, bytes payload, uint64 timeoutTimestamp);

    function sendUniversalPacket(
        bytes32 channelId,
        bytes32 destPortAddr,
        bytes memory payload,
        uint64 timeoutTimestamp
    ) public {
        emit UniversalPacketSent(channelId, destPortAddr, payload, timeoutTimestamp);
    }
}

contract PolymerL2CrosschainTokenTest is Test {
    PolymerL2CrosschainToken token;
    MockMiddleware mockMiddleware;
    address owner;
    address recipient;

    function setUp() public {
        owner = address(this);
        recipient = address(0x123);
        mockMiddleware = new MockMiddleware();
        token = new PolymerL2CrosschainToken(address(mockMiddleware));
    }

    function testMint() public {
        uint256 amount = 100 * 10 ** token.decimals();
        uint256 initialBalance = token.balanceOf(owner);
        token.mint(amount);
        assertEq(token.balanceOf(owner), initialBalance + amount);
    }

    function testBurn() public {
        uint256 initialBalance = token.balanceOf(owner);
        uint256 burnAmount = 50 * 10 ** token.decimals();
        token.burn(burnAmount);
        assertEq(token.balanceOf(owner), initialBalance - burnAmount);
    }

    function testCrosschainTransfer() public {
        bytes32 channelId = bytes32("testChannel");
        address destPortAddr = address(0x456);
        uint256 amount = 100 * 10 ** token.decimals();

        token.crosschainTransfer(destPortAddr, channelId, recipient, amount);
        
        console.log("Owner balance after crosschainTransfer:", token.balanceOf(owner));
        assertEq(token.balanceOf(owner), 900 * 10 ** token.decimals());

        // Simulate receiving a packet and its acknowledgment
        vm.startPrank(address(mockMiddleware));
    
        // Create a mock packet
        UniversalPacket memory packet = UniversalPacket({
            srcPortAddr: IbcUtils.toBytes32(address(this)),
            mwBitmap: 0,
            destPortAddr: IbcUtils.toBytes32(destPortAddr),
            appData: abi.encode(address(this), recipient, amount)
        });

        // Create a mock acknowledgment
        AckPacket memory ack = AckPacket({
            success: true,
            data: abi.encode(address(this), recipient, amount)
        });

        // Simulate the acknowledgment of the packet
        token.onUniversalAcknowledgement(channelId, packet, ack);

        vm.stopPrank();
    }
}