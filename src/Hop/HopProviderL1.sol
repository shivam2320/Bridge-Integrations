// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IHop.sol";

contract HopProviderL1 is Ownable, ReentrancyGuard {
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

    /**
	// @notice function responsible to bridge Native tokens
	// @param toChainId Id of destination chain
	// @param receiver Address of receiver
	// @param amount Amount to be bridged
	// param extraData extra data if needed
	 */
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
        address bridgeAddress = abi.decode(extraData, (address));
        IHop(bridgeAddress).sendToL2{value: amount}(
            toChainId,
            receiver,
            amount,
            0,
            block.timestamp + 10,
            address(0),
            0
        );
        emit NativeFundsTransferred(receiver, toChainId, amount);
    }

    /**
	// @notice function responsible to bridge ERC20 tokens
	// @param toChainId Id of destination chain
	// @param tokenAddress Address of token to be bridged
	// @param receiver Address of receiver
	// @param amount Amount to be bridged
	// param extraData extra data if needed
	 */
    function transferERC20(
        uint64 toChainId,
        address tokenAddress,
        address receiver,
        uint256 amount,
        bytes memory extraData
    ) external nonReentrant {
        require(amount > 0, "WagPay: Please send amount greater than 0");
        address bridgeAddress = abi.decode(extraData, (address));
        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        IERC20(tokenAddress).safeIncreaseAllowance(
            address(bridgeAddress),
            amount
        );

        IHop(bridgeAddress).sendToL2(
            toChainId,
            receiver,
            amount,
            0,
            block.timestamp + 10,
            address(0),
            0
        );

        emit ERC20FundsTransferred(receiver, toChainId, amount, tokenAddress);
    }

    /**
	// @notice function responsible to rescue funds if any
	// @param  tokenAddr address of token
	 */
    function rescueFunds(address tokenAddr) external onlyOwner nonReentrant {
        if (tokenAddr == NATIVE_TOKEN_ADDRESS) {
            uint256 balance = address(this).balance;
            payable(msg.sender).transfer(balance);
        } else {
            uint256 balance = IERC20(tokenAddr).balanceOf(address(this));
            IERC20(tokenAddr).transferFrom(address(this), msg.sender, balance);
        }
    }
}
