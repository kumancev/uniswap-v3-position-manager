// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MockUniswapV3Pool {
    address public token0;
    address public token1;
    uint24 public fee;

    struct Slot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        uint8 feeProtocol;
        bool unlocked;
    }

    Slot0 public s_slot0;

    constructor(address _token0, address _token1, uint24 _fee) {
        token0 = _token0;
        token1 = _token1;
        fee = _fee;
        s_slot0.sqrtPriceX96 = 1 << 96; // init to 1.0
    }

    function slot0() external view returns (Slot0 memory) {
        return s_slot0;
    }

    function setPrice(uint160 _sqrtPriceX96) external {
        s_slot0.sqrtPriceX96 = _sqrtPriceX96;
    }
}