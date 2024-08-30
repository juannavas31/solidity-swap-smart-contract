// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20SwapperV1} from "./interfaces/IERC20SwapperV1.sol";
import "../node_modules/@openzeppelin/contracts/interfaces/IERC20.sol";
import "../node_modules/@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Context} from "./utils/Context.sol";

contract ERC20SwapperV1 is IERC20SwapperV1, Context, Initializable {

    // Uniswap V3 factory address, for ex. 0x1F98431c8aD98523631AE4a59f267346ea31F984 for Mainnet
    address private factory;
    // WETH address, for ex. 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 for Mainnet (Wrapper Ether contract)
    address private weth;
    address private owner;

    // Constructor-like function for upgradeable contracts
    function initialize() public initializer {
        factory = 0x0227628f3F023bb0B980b67D528571c95c6DaC1c;   // Sepolia V3 Factory
        weth =  0x4200000000000000000000000000000000000006;     // Wrapped Ether contract at Sepolia
        owner = _msgSender();
    }

    // Modifier to check if the caller is the owner
    modifier onlyOwner() {
        require(_msgSender() == owner, "ERC20SwapperV1: caller is not the owner");
        _;
    }

    // event for transfer token to caller
    event TransferToken(address indexed token, address indexed caller, uint amount);

    function swapEtherToToken(address token, uint minAmount) external payable virtual returns (uint) {
        require(token != address(0), "ERC20SwapperV1: token is the zero address");
        require(minAmount > 0, "ERC20SwapperV1: minAmount must be greater than 0");
        require(msg.value > 0, "ERC20SwapperV1: insufficient amount");

        uint tokenPrice = getTokenPrice(token);

        // Adjust tokenPrice according to decimals (18 decimals for Ether and presume 10 decimals for token)
        // Alternatively, we can fetch the decimals from the token contract IERC20(token).decimals()
        // Also, msg.value is in Wei, so we need to convert it to Ether
        // See https://blog.uniswap.org/uniswap-v3-math-primer for price precision
        // uint amount = (msg.value / 1e18) / (tokenPrice / (10 ** 8));

        uint amount = (msg.value / tokenPrice) / (10 ** 10);
        require(amount >= minAmount, "ERC20SwapperV1: insufficient amount");

        // Transfer the token to the caller
        IERC20(token).transfer(_msgSender(), amount);
        emit TransferToken(token, _msgSender(), amount);

        return amount;
    }

    function setFactory(address _factory) public onlyOwner {
        factory = _factory;
    }

    function getFactory() public view returns (address) {
        return factory;
    }

    function setWeth(address _weth) public onlyOwner {
        weth = _weth;
    }

    function getWeth() public view returns (address) {
        return weth;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getTokenPrice(address tokenAddress) public view returns (uint256 tokenPrice) {
        address poolAddress = getPool(tokenAddress, weth);
        require(poolAddress != address(0), "ERC20SwapperV1: pool not found");
            
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddress);

        // Get the square root price
        (uint160 sqrtPriceX96,,,,,,) = pool.slot0();

        // Convert the sqrt price to integer price
        tokenPrice = convertSqrtPriceToPrice(sqrtPriceX96);
    }

    // Get the pool address for the given tokens and fee
    // Ex. mainnet WETH / USDC pool 0.05% where fee has values for tiers (1% == 10000, 0.3% == 3000, 0.05% == 500, 0.01 == 100)
    // ("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48", 500)
    function getPool(address token0, address token1) public view returns (address poolAddress) {
        poolAddress = IUniswapV3Factory(factory).getPool(token0, token1, 100);
        if (poolAddress == address(0)) {
            poolAddress = IUniswapV3Factory(factory).getPool(token0, token1, 500);
        }
        if (poolAddress == address(0)) {
            poolAddress = IUniswapV3Factory(factory).getPool(token0, token1, 3000);
        }
    }

    // Uniswap square root priceX96 uses 96 decimals
    // See docs.uniswap.org/sdk/guides/fetching-prices for details
    function convertSqrtPriceToPrice(uint160 sqrtPriceX96) private pure returns (uint256) {
        uint256 price = (sqrtPriceX96 ** 2) / (2 ** 192);
        return price;
    }
}