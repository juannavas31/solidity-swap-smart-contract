// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.20;

import { ERC20SwapperV1 } from "src/ERC20SwapperV1.sol";

contract MockERC20SwapperV1 is ERC20SwapperV1 {
    function swapEtherToToken(address token, uint minAmount) external payable override returns (uint) {
        return 10;
    }
}