// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAnyswap.sol";

contract AnyswapProvider is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IAnyswap public anyswapRouter;

    event ERC20FundsTransferred(
        address receiver,
        uint256 toChainId,
        uint256 amount,
        address tokenAddress
    );

    constructor(address _anyswapRouter) {
        anyswapRouter = IAnyswap(_anyswapRouter);
    }

    function transferERC20(
        uint64 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        bytes memory extraData
    ) external nonReentrant {
        require(amount > 0, "WagPay: Please send amount greater than 0");
        address wrapper = abi.decode(extraData, (address));

        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        IERC20(tokenAddress).safeIncreaseAllowance(
            address(anyswapRouter),
            amount
        );

        anyswapRouter.anySwapOutUnderlying(
            wrapper,
            receiver,
            amount,
            toChainId
        );

        emit ERC20FundsTransferred(receiver, toChainId, amount, tokenAddress);
    }

    function changePool(address newPool) external onlyOwner {
        anyswapRouter = IAnyswap(newPool);
    }

    function rescueFunds(address tokenAddr, uint256 amount) external onlyOwner {
        if (tokenAddr == NATIVE_TOKEN_ADDRESS) {
            uint256 balance = address(this).balance;
            payable(msg.sender).transfer(balance);
        } else {
            IERC20(tokenAddr).transferFrom(address(this), msg.sender, amount);
        }
    }
}
