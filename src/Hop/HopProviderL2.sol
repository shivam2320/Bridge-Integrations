// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IHop.sol";

contract HopProviderL2 is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    event NativeFundsTransferred(
        address receiver,
        uint256 toChainId,
        uint256 amount
    );

    event ERC20FundsTransferred(
        address receiver,
        uint256 toChainId,
        uint256 amount,
        address tokenAddress
    );

    function transferNative(
        uint256 amount,
        address receiver,
        uint64 toChainId,
        bytes memory extraData
    ) external payable nonReentrant {
        require(msg.value != 0, "WagPay: Please send amount greater than 0");
        require(
            msg.value == amount,
            "WagPay: Please send amount same to msg.value"
        );
        (address bridgeAddress, uint256 bonderFee) = abi.decode(
            extraData,
            (address, uint256)
        );
        IHop(bridgeAddress).swapAndSend{value: amount}(
            toChainId,
            receiver,
            amount,
            bonderFee,
            0,
            block.timestamp + 10,
            0,
            block.timestamp + 10
        );
        emit NativeFundsTransferred(receiver, toChainId, amount);
    }

    function transferERC20(
        uint64 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        bytes memory extraData
    ) external nonReentrant {
        require(amount > 0, "WagPay: Please send amount greater than 0");
        (address bridgeAddress, uint256 bonderFee) = abi.decode(
            extraData,
            (address, uint256)
        );
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        IERC20(tokenAddress).safeIncreaseAllowance(
            address(bridgeAddress),
            amount
        );

        IHop(bridgeAddress).swapAndSend(
            toChainId,
            receiver,
            amount,
            bonderFee,
            0,
            block.timestamp + 10,
            0,
            block.timestamp + 10
        );

        emit ERC20FundsTransferred(receiver, toChainId, amount, tokenAddress);
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
