// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Consumer.sol";

contract DeployConsumer is Script {
    function run() external {
        vm.startBroadcast();

        // Replace with the actual router address
        address router = 0xf9B8fc078197181C841c296C876945aaa425B278;
        AnimeConsumer consumer = new AnimeConsumer(router);

        console.log("Consumer deployed to:", address(consumer));

        vm.stopBroadcast();
    }
}
