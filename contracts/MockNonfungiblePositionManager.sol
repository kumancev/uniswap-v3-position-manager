// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockNonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    uint256 public nextTokenId;
    mapping(uint256 => address) public s_positions;

    event Minted(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event IncreasedLiquidity(uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    event DecreasedLiquidity(uint256 tokenId, uint256 amount0, uint256 amount1);
    event CollectedFees(uint256 tokenId, uint256 amount0, uint256 amount1);

    function mint(MintParams calldata params) external returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    ) {
        tokenId = nextTokenId++;
        s_positions[tokenId] = params.recipient;
        liquidity = uint128(params.amount0Desired + params.amount1Desired);
        amount0 = params.amount0Desired;
        amount1 = params.amount1Desired;

        emit Minted(tokenId, liquidity, amount0, amount1);
    }

    function increaseLiquidity(IncreaseLiquidityParams calldata params) external returns (
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    ) {
        liquidity = uint128(params.amount0Desired + params.amount1Desired);
        amount0 = params.amount0Desired;
        amount1 = params.amount1Desired;

        emit IncreasedLiquidity(params.tokenId, liquidity, amount0, amount1);
    }

    function decreaseLiquidity(DecreaseLiquidityParams calldata params) external returns (
        uint256 amount0,
        uint256 amount1
    ) {
        amount0 = params.amount0Min;
        amount1 = params.amount1Min;

        emit DecreasedLiquidity(params.tokenId, amount0, amount1);
    }

    function collect(CollectParams calldata params) external returns (
        uint256 amount0,
        uint256 amount1
    ) {
        amount0 = params.amount0Max;
        amount1 = params.amount1Max;

        emit CollectedFees(params.tokenId, amount0, amount1);
    }

    function positions(uint256 tokenId) external view returns (address) {
        return s_positions[tokenId];
    }
}