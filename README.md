# Uniswap V3 Position Manager

A smart contract implementation for managing liquidity positions in Uniswap V3 pools. This project demonstrates how to programmatically create and manage Uniswap V3 positions with specified width parameters entirely on-chain.

## Overview

The project implements a position manager contract that allows users to:

- Create new liquidity positions with specified width parameters
- Increase liquidity in existing positions
- Decrease liquidity from positions
- Collect accumulated fees

The width parameter is calculated using the formula:

```
width = (upperPrice - lowerPrice) 10000 / (lowerPrice + upperPrice)
```

## Features

- **Universal Pool Support**: Works with any Uniswap V3 pool regardless of token pairs
- **Fully On-chain**: All calculations and operations are performed entirely on-chain
- **Position Management**: Complete lifecycle management of Uniswap V3 positions
- **Automated Price Range**: Calculates position bounds based on width parameter
- **Fee Collection**: Built-in functionality to collect accumulated fees

## Technical Stack

- Solidity ^0.8.20
- Hardhat
- Uniswap V3 Core & Periphery
- OpenZeppelin Contracts
- Hardhat Ignition (for deployments)

## Contract Architecture

### Main Components

1. **UniswapV3PositionManagerContract**: The main contract that handles position management
2. **Mock Contracts** (for testing):
   - MockERC20: Test ERC20 tokens
   - MockUniswapV3Pool: Simulated Uniswap V3 pool
   - MockNonfungiblePositionManager: Test NFT position manager

### Key Functions

- `createPosition`: Creates new liquidity position with specified width
- `increaseLiquidity`: Adds liquidity to existing position
- `decreaseLiquidity`: Removes liquidity from position
- `collectFees`: Collects accumulated trading fees

# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.js
```
