// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IAnyswap {
    function anySwapOutUnderlying(
        address token,
        address to,
        uint256 amount,
        uint256 toChainID
    ) external;
}
