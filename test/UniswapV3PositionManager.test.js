const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UniswapV3PositionManagerContract", function () {
  let MockERC20, dai, weth;
  let MockUniswapV3Pool, pool;
  let MockNonfungiblePositionManager, positionManagerMock;
  let UniswapV3PositionManagerContract, contract;
  let owner, user, otherUser;

  beforeEach(async function () {
    [owner, user, otherUser] = await ethers.getSigners();

    // deploy mock ERC20 tokens
    MockERC20 = await ethers.getContractFactory("MockERC20");
    dai = await MockERC20.deploy(
      "DAI Stablecoin",
      "DAI",
      ethers.utils.parseEther("1000000")
    );
    await dai.deployed();

    weth = await MockERC20.deploy(
      "Wrapped Ether",
      "WETH",
      ethers.utils.parseEther("1000000")
    );
    await weth.deployed();

    // deploy mock Uniswap V3 Pool
    MockUniswapV3Pool = await ethers.getContractFactory("MockUniswapV3Pool");
    pool = await MockUniswapV3Pool.deploy(dai.address, weth.address, 3000);
    await pool.deployed();

    // deploy mock NPM
    MockNonfungiblePositionManager = await ethers.getContractFactory(
      "MockNonfungiblePositionManager"
    );
    positionManagerMock = await MockNonfungiblePositionManager.deploy();
    await positionManagerMock.deployed();

    // deploy the UniswapV3PositionManagerContract
    UniswapV3PositionManagerContract = await ethers.getContractFactory(
      "UniswapV3PositionManagerContract"
    );
    contract = await UniswapV3PositionManagerContract.deploy(
      positionManagerMock.address
    );
    await contract.deployed();

    // approve tokens for user
    await dai
      .connect(owner)
      .mint(user.address, ethers.utils.parseEther("1000"));
    await weth
      .connect(owner)
      .mint(user.address, ethers.utils.parseEther("1000"));

    await dai
      .connect(user)
      .approve(contract.address, ethers.constants.MaxUint256);
    await weth
      .connect(user)
      .approve(contract.address, ethers.constants.MaxUint256);
  });

  describe("createPosition", function () {
    it("Should create a new liquidity position", async function () {
      const amount0Desired = ethers.utils.parseEther("100");
      const amount1Desired = ethers.utils.parseEther("200");
      const width = 100; // exmpl width

      await dai.connect(user).mint(user.address, amount0Desired);
      await weth.connect(user).mint(user.address, amount1Desired);

      await dai.connect(user).approve(contract.address, amount0Desired);
      await weth.connect(user).approve(contract.address, amount1Desired);

      await expect(
        contract
          .connect(user)
          .createPosition(pool.address, amount0Desired, amount1Desired, width)
      )
        .to.emit(contract, "PositionMinted")
        .withArgs(0, 0, amount0Desired, amount1Desired); // tokenId starts at 0 in mock

      // check that position exists
      expect(await positionManagerMock.positions(0)).to.equal(user.address);

      // check token balances
      expect(await dai.balanceOf(user.address)).to.be.equal(
        ethers.utils.parseEther("900")
      ); // 1000 - 100
      expect(await weth.balanceOf(user.address)).to.be.equal(
        ethers.utils.parseEther("800")
      ); // 1000 - 200
    });

    it("Should revert if width is zero", async function () {
      const amount0Desired = ethers.utils.parseEther("100");
      const amount1Desired = ethers.utils.parseEther("200");
      const width = 0;

      await expect(
        contract
          .connect(user)
          .createPosition(pool.address, amount0Desired, amount1Desired, width)
      ).to.be.revertedWith("Width must be greater than zero");
    });
  });

  describe("increaseLiquidity", function () {
    it("Should increase liquidity for an existing position", async function () {
      // 1-st, create a position
      const amount0Desired = ethers.utils.parseEther("100");
      const amount1Desired = ethers.utils.parseEther("200");
      const width = 100;

      await contract
        .connect(user)
        .createPosition(pool.address, amount0Desired, amount1Desired, width);

      // increase liquidity
      const additionalAmount0 = ethers.utils.parseEther("50");
      const additionalAmount1 = ethers.utils.parseEther("100");

      await dai.connect(user).mint(user.address, additionalAmount0);
      await weth.connect(user).mint(user.address, additionalAmount1);

      await dai.connect(user).approve(contract.address, additionalAmount0);
      await weth.connect(user).approve(contract.address, additionalAmount1);

      await expect(
        contract
          .connect(user)
          .increaseLiquidity(0, additionalAmount0, additionalAmount1)
      )
        .to.emit(contract, "LiquidityIncreased")
        .withArgs(
          0,
          ethers.BigNumber.from("150"),
          additionalAmount0,
          additionalAmount1
        ); // liquidity is simplified

      // check token balances
      expect(await dai.balanceOf(user.address)).to.be.equal(
        ethers.utils.parseEther("850")
      ); // 900 - 50
      expect(await weth.balanceOf(user.address)).to.be.equal(
        ethers.utils.parseEther("700")
      ); // 800 - 100
    });

    it("Should revert if position does not exist", async function () {
      const additionalAmount0 = ethers.utils.parseEther("50");
      const additionalAmount1 = ethers.utils.parseEther("100");

      await expect(
        contract
          .connect(user)
          .increaseLiquidity(1, additionalAmount0, additionalAmount1)
      ).to.be.reverted; // mock does not handle non-existing positions
    });
  });

  describe("decreaseLiquidity", function () {
    it("Should decrease liquidity for an existing position", async function () {
      // 1-st, create a position
      const amount0Desired = ethers.utils.parseEther("100");
      const amount1Desired = ethers.utils.parseEther("200");
      const width = 100;

      await contract
        .connect(user)
        .createPosition(pool.address, amount0Desired, amount1Desired, width);

      // decrease liquidity
      const liquidityToRemove = 50;

      await expect(
        contract.connect(user).decreaseLiquidity(0, liquidityToRemove)
      )
        .to.emit(contract, "LiquidityDecreased")
        .withArgs(0, 0, 0); // simplified amounts in mock

      // since mock contracts simplify, token balances remain unchanged
    });

    it("Should revert if position does not exist", async function () {
      const liquidityToRemove = 50;

      await expect(
        contract.connect(user).decreaseLiquidity(1, liquidityToRemove)
      ).to.be.reverted; // mock does not handle non-existing positions
    });
  });

  describe("collectFees", function () {
    it("Should collect fees from a position", async function () {
      // 1-st, create a position
      const amount0Desired = ethers.utils.parseEther("100");
      const amount1Desired = ethers.utils.parseEther("200");
      const width = 100;

      await contract
        .connect(user)
        .createPosition(pool.address, amount0Desired, amount1Desired, width);

      // collect fees
      await expect(contract.connect(user).collectFees(0))
        .to.emit(contract, "FeesCollected")
        .withArgs(0, ethers.BigNumber.from("0"), ethers.BigNumber.from("0")); // simplified fees in mock
    });

    it("Should revert if position does not exist", async function () {
      await expect(contract.connect(user).collectFees(1)).to.be.reverted; // mock does not handle non-existing positions
    });
  });
});
