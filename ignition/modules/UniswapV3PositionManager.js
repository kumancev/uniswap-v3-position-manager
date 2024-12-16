const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { ethers } = require("ethers");

module.exports = buildModule("UniswapV3PositionManagerModule", (m) => {
  // deploy Mock ERC20 Tokens
  const mockDAI = m.deploy("MockERC20", [
    "DAI Stablecoin",
    "DAI",
    ethers.utils.parseEther("1000000"),
  ]);

  const mockWETH = m.deploy("MockERC20", [
    "Wrapped Ether",
    "WETH",
    ethers.utils.parseEther("1000000"),
  ]);

  // deploy Mock Uniswap V3 Pool
  const mockPool = m.deploy("MockUniswapV3Pool", [
    mockDAI.address,
    mockWETH.address,
    3000, // fee: 0.3%
  ]);

  // deploy Mock NPM
  const mockPositionManager = m.deploy("MockNonfungiblePositionManager", []);

  // deploy UniswapV3PositionManagerContract
  const uniswapV3PositionManager = m.deploy(
    "UniswapV3PositionManagerContract",
    [mockPositionManager.address]
  );

  return {
    mockDAI,
    mockWETH,
    mockPool,
    mockPositionManager,
    uniswapV3PositionManager,
  };
});
