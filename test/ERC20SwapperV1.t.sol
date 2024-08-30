// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/ERC20SwapperV1.sol";
import "./Mocks/MockERC20SwapperV1.sol";
import {Test, console} from "forge-std/Test.sol";

contract MyERC20SwapperV1Test is Test {
    ERC20SwapperV1 internal swapper;
    MockERC20SwapperV1 internal mockSwapper;
    address internal weth;
    address internal token;
    event TransferToken(address indexed token, address indexed caller, uint amount);

    function setUp() public virtual {
        mockSwapper = new MockERC20SwapperV1();
        mockSwapper.initialize();
        swapper = new ERC20SwapperV1();
        swapper.initialize();
        weth = 0x4200000000000000000000000000000000000006;
        token = 0x0227628f3F023bb0B980b67D528571c95c6DaC1c;
    }

    function test_swap_token_reverts_with_address_zero() public {
        // arrange
        address zero = address(0);

        // act & assert
        vm.expectRevert();
        swapper.swapEtherToToken(zero, 10);
    }

    function test_swap_token_reverts_with_zero_min_amount() public {
        // arrange
        uint minAmount = 0;

        // act & assert
        vm.expectRevert();
        swapper.swapEtherToToken(token, minAmount);
    }

    function test_setFactory_ok() public {
        // arrange
        address newFactory = 0x0227628f3F023bb0B980b67D528571c95c6DaC1c;
        vm.prank(swapper.getOwner());

        // act
        swapper.setFactory(newFactory);

        // assert
        assertEq(swapper.getFactory(), newFactory, "Incorrect factory address");
    }

    function test_transferOwnership_reverts_if_not_owner() public {
        // arrange
        address newOwner = makeAddr("newOwner");
        address notOwner = makeAddr("notOwner");
        vm.prank(notOwner);

        // act & assert
        vm.expectRevert();
        swapper.transferOwnership(newOwner);
    }
    
    function test_swap_ether_to_token_ok() public {
        // arrange
        uint256 minAmount = 10;
        uint256 expectedAmount = 10;

        // act
        uint amount = mockSwapper.swapEtherToToken{value: 100000 ether}(token, minAmount);

        // assert
        assertEq(amount, expectedAmount, "Incorrect amount");
    }
}
