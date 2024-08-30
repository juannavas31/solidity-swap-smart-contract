// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {ERC20SwapperV1} from "src/ERC20SwapperV1.sol";

contract TransparentProxyScript is Script {
    function setUp() public {}

    function run() public {
        address proxy = Upgrades.deployTransparentProxy(
            "ERC20SwapperV1.sol",
            "<INITIAL_OWNER_ADDRESS_FOR_PROXY_ADMIN>",
            abi.encodeCall(ERC20SwapperV1.initialize, ())
        );
        console.log("Proxy deployed at: ", proxy);

        vm.broadcast();
    }
}
