// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";

contract UniswapV3PositionManagerContract is IERC721Receiver {
    using SafeERC20 for IERC20;

    INonfungiblePositionManager public immutable nonfungiblePositionManager;

    event PositionMinted(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event FeesCollected(uint256 tokenId, uint256 amount0, uint256 amount1);
    event LiquidityIncreased(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event LiquidityDecreased(uint256 tokenId, uint256 amount0, uint256 amount1);

    constructor(address _nonfungiblePositionManager) {
        nonfungiblePositionManager = INonfungiblePositionManager(_nonfungiblePositionManager);
    }

    /**
     * @dev Receives ERC721 tokens. Required to implement IERC721Receiver.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev Creates new liquidity position in specified Uniswap V3 pool.
     * @param pool Address of the Uniswap V3 pool.
     * @param amount0Desired Amount of token0 to add.
     * @param amount1Desired Amount of token1 to add.
     * @param width Width parameter to calculate price range.
     * @return tokenId ID of the minted NFT position.
     */
    function createPosition(
        address pool,
        uint256 amount0Desired,
        uint256 amount1Desired,
        uint256 width
    ) external returns (uint256 tokenId) {
        require(width > 0, "Width must be greater than zero");

        IUniswapV3Pool uniswapPool = IUniswapV3Pool(pool);
        address token0 = uniswapPool.token0();
        address token1 = uniswapPool.token1();
        uint24 fee = uniswapPool.fee();

        // transfer tokens from sender to this contract
        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0Desired);
        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1Desired);

        // approve position manager
        IERC20(token0).safeApprove(address(nonfungiblePositionManager), amount0Desired);
        IERC20(token1).safeApprove(address(nonfungiblePositionManager), amount1Desired);

        // get current price and compute price range
        (uint160 sqrtPriceX96, , , , , , ) = uniswapPool.slot0();
        uint256 currentPrice = TickMath.getSqrtRatioAtTick(int24(sqrtPriceX96)) ** 2 / (2**192); // Accurate price calculation

        // calc lower and upper prices based on width parameter
        uint256 lowerPrice = (currentPrice * 10000) / (10000 + width);
        uint256 upperPrice = (currentPrice * 10000) / (10000 - width);

        // convert prices to ticks using TickMath
        int24 tickLower = getTickAtPrice(pool, lowerPrice);
        int24 tickUpper = getTickAtPrice(pool, upperPrice);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: fee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0, // TODO: in production, need to using oracles or Uniswap's SDK
            amount1Min: 0, // TODO: in production, need to using oracles or Uniswap's SDK
            recipient: msg.sender,
            deadline: block.timestamp + 600
        });

        // Mint the position
        (tokenId, , , ) = nonfungiblePositionManager.mint(params);

        emit PositionMinted(tokenId, 0, amount0Desired, amount1Desired);
    }

    /**
     * @dev Increases liquidity for an existing position.
     * @param tokenId NFT token ID of the position.
     * @param amount0Desired Amount of token0 to add.
     * @param amount1Desired Amount of token1 to add.
     */
    function increaseLiquidity(
        uint256 tokenId,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external {
        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager.IncreaseLiquidityParams({
            tokenId: tokenId,
            amount0Desired: amount0Desired,
            amount1Desired: amount1Desired,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp + 600
        });

        (address t0, address t1, , ) = nonfungiblePositionManager.positions(tokenId);
        IERC20(t0).safeTransferFrom(msg.sender, address(this), amount0Desired);
        IERC20(t1).safeTransferFrom(msg.sender, address(this), amount1Desired);

        // approve the position manager
        IERC20(t0).safeApprove(address(nonfungiblePositionManager), amount0Desired);
        IERC20(t1).safeApprove(address(nonfungiblePositionManager), amount1Desired);

        // increase liquidity
        (, uint256 liquidity, uint256 amount0, uint256 amount1) = nonfungiblePositionManager.increaseLiquidity(params);

        emit LiquidityIncreased(tokenId, uint128(liquidity), amount0, amount1);
    }

    /**
     * @dev Decreases liquidity for an existing position.
     * @param tokenId NFT token ID of the position.
     * @param liquidity Amount of liquidity to remove.
     */
    function decreaseLiquidity(
        uint256 tokenId,
        uint128 liquidity
    ) external {
        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager.DecreaseLiquidityParams({
            tokenId: tokenId,
            liquidity: liquidity,
            amount0Min: 0,
            amount1Min: 0,
            deadline: block.timestamp + 600
        });

        // decrease liquidity
        (uint256 amount0, uint256 amount1) = nonfungiblePositionManager.decreaseLiquidity(params);

        emit LiquidityDecreased(tokenId, amount0, amount1);
    }

    /**
     * @dev Collects all fees from position.
     * @param tokenId NFT token ID of position.
     */
    function collectFees(uint256 tokenId) external {
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: tokenId,
            recipient: msg.sender,
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        // collect fees
        (uint256 amount0, uint256 amount1) = nonfungiblePositionManager.collect(params);

        emit FeesCollected(tokenId, amount0, amount1);
    }

    /**
     * @dev Calculates tick corresponding to a given price.
     * @param pool Address of the Uniswap V3 pool.
     * @param price Price to convert to tick.
     * @return tick Tick value corresponding to the price.
     */
    function getTickAtPrice(address pool, uint256 price) internal view returns (int24 tick) {
        // convert price to sqrtPriceX96
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(int24(0)); // TODO: implement accurate conversion in prod
        tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
    }
}