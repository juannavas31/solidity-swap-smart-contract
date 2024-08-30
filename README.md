# ERC-20 swapping contract

This is a Solidity contract for exchanging Ether to an arbitrary ERC-20.

## Specification description

1. It implement the following interface as a Solidity Contract

   ```solidity
   interface ERC20Swapper {
       /// @dev swaps the `msg.value` Ether to at least `minAmount` of tokens in `address`, or reverts
       /// @param token The address of ERC-20 token to swap
       /// @param minAmount The minimum amount of tokens transferred to msg.sender
       /// @return The actual amount of transferred tokens
       function swapEtherToToken(address token, uint minAmount) public payable returns (uint);
   }
   ```

2. The contract is deployed to a public Ethereum testnet (e.g. Sepolia)
3. See the address in the log files

### Additional details

The smart contract makes use of Uniswap v3 pools to get the exchange rate of ETH / ERC-20 token based on the token address.

## Non Functional requirements taken into account

- **Safety and trust minimization**. Are user's assets kept safe during the exchange transaction? Is the exchange rate fair and correct? Does the contract have an owner?
- **Performance**. How much gas will the `swapEtherToToken` execution and the deployment take?
- **Upgradeability**. How can the contract be updated if e.g. the DEX it uses has a critical vulnerability and/or the liquidity gets drained?
- **Usability and interoperability**. Is the contract usable for EOAs? Are other contracts able to interoperate with it?
- **Readability and code quality**. Are the code and design understandable and error-tolerant? Is the contract easily testable?

# Solution

## Upgradeability

Using OpenZeppelin upgrades, Transparent proxy solution implemented with [Foundry plug-in](https://docs.openzeppelin.com/upgrades-plugins/1.x/foundry-upgrades)

The swapper contract is deployed at sepolia address 0xD0B98e56F19f9b5c2Ef0de72c0bc799a99555261

The transparent proxy contract is deployed at sepolia address 0xdaE97900D4B184c5D2012dcdB658c008966466DD

For future upgrades, the swapper contract needs to follow the guide by Openzeppelin about upgradeability, basically to keep the state backwards compatible.

## Safety 

I have presumed that the swapper contract owns tokens at the ERC20 contracts and when it receives ETHER, it transfers its own tokens to the sender. In this case, the transaction is safe, as in case the swapper contract doesn't have enough tokens, it would be reverted and sender would not lose his ether. 
A more complex approach would be to consider that the tokens belong to someone else. Then contract would need to facilitate the transaction between two parties, using the approve() and transferFrom() functions from ERC20 (similar to how Uniswap works). 

_Is the exchange rate fair?_ 

The exchange rate is provided by Uniswap v3 pools. Each pair token/weth may have up to three pools with different fees (they call them tiers). The swapper contract makes use of Uniswapv3 Factory contract to search for a token/weth pool in any of the tiers. From that pool, the exchange rate is obtained. This is not the most reliable way to get the exchange rate, although it is reasonably good. The price in principle is fair, if the token/weth pool has enough liquidity. Otherwise it might be subject to sudden variations. 

The best way would be to use a decentralized oracle (for instance, chainlink). This solution provides a more reliable price, not subject to sudden and intentionally provoked fluctuations. The downside is that it does not offers the functionality of just using a pair of contract addresses to search for a price feed (price feeds addresses for each supported pair of tokens are published on the web, that is, off-chain). Besides, using chainlink price feeds costs extra fees.

## Performance

The swapper contract has taken: 

Total Paid: 0.002522603083589364 ETH (783382 gas * avg 3.220144302 gwei)


## Usuability and Interoperativity

Externally Owned Accounts can interact/transact with the swapper contract, sending ether and receiving tokens. 

Also, other contracts can interact in the same way. 

## Readability and code quality

Comments have been added to help understanding the logic behind it. 

Most potential errored situations have been taken into accout (address not being zero, only-owner transactions, etc.). 
Test cases are available for the self contained logic. However, the functions that rely on calls to external contracts (either Uniswap v3 or the ERC20 token) need a more complex setup. A possible solution (just a hint implemented) is to use mocks based on virtual functions for the external contracts. This is not an easy/straightforward solution, it can get messy if the number of contracts/functions to mock is reasonably large. 

## Installation instructions

Install the needed node libraries (OpenZeppeling, Uniswap, etc) using node package manager, npm: 

```shell
$ npm install
```

You need foundry installed on your system. If it is not installed, you can follow [this guide](https://ethereum-blockchain-developer.com/2022-06-nft-truffle-hardhat-foundry/14-foundry-setup/) 


Proceed to the follwing steps: 

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

## Deploy

We are using foundry scripts to deploy the smart contracts to sepolia testnet. You can checke out the [guide](https://book.getfoundry.sh/tutorials/solidity-scripting#deploying-our-contract) for details. 

First, you need to update the configuration files with your own data, like private key and infura key (or other rpc gateway you want to use). 

Edit the .env file and update the variables 

```shell
SEPOLIA_RPC_URL="https://sepolia.infura.io/v3/<your infura key>"
PRIVATE_KEY="<your private key>"
ETHERSCAN_API_KEY="<optional>"
```

Edit the foundry.toml file and update the variable sepolia=...

We start by deploying the swapper contract, enter the command: 

```shell
$ source .env

$ forge script script/DeployERC20SwapperV1.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast 
```

It will output the contract address, keep it for later use. 

As the swapper contract is upgradable, we can choose using the transparent proxy or the newer UUPS proxy. 

For the UUPS proxy, updateh the script/DeployUUPSProxy.s.sol with the swapper contract address. 
For the Transparent proxy, update the scrpt/DeployTransparentProxy.s.sol with the owner's address for the proxy admin (i.e. your wallet public address). 

Then you can run the foundry command to deploy the proxies: 

```shell
$ forge script script/DeployTransparentProxy.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast
```

or 

```shell
$ forge script script/DeployUUPSProxy.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast 
```

And that's all. 






