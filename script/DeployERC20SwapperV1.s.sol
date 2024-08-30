// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/ERC20SwapperV1.sol";
import "forge-std/Script.sol";

contract DeployTokenImplementation is Script {
    function run() public {
        // Use address provided in config to broadcast transactions
        vm.startBroadcast();
        // Deploy the ERC-20 token
        ERC20SwapperV1 implementation = new ERC20SwapperV1();
        // Stop broadcasting calls from our address
        vm.stopBroadcast();
        // Log the token address
        console.log("Token Implementation Address:", address(implementation));
    }
}