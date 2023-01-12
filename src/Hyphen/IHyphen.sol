// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ILiquidityPool {
    
    function depositErc20(uint chainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        string memory tag
    ) external;

    function depositNative(address receiver, uint256 toChainId, string memory tag)
        external
        payable;
}