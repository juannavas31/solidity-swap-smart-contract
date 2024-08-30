// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "src/ERC20SwapperV1.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "forge-std/Script.sol";

contract DeployUUPSProxy is Script {
    function run() public {

        address _implementation = 0xD0B98e56F19f9b5c2Ef0de72c0bc799a99555261; // swapper contract address at sepolia
        vm.startBroadcast();

        // Encode the initializer function call
        bytes memory data = abi.encodeWithSelector(
            ERC20SwapperV1(_implementation).initialize.selector,
            msg.sender // Initial owner/admin of the contract
        );

        // Deploy the proxy contract with the implementation address and initializer
        ERC1967Proxy proxy = new ERC1967Proxy(_implementation, data);

        vm.stopBroadcast();
        // Log the proxy address
        console.log("UUPS Proxy Address:", address(proxy));
    }
}