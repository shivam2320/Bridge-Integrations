// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IPolygon.sol";

contract PolygonProviderL1 is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    address private constant NATIVE_TOKEN_ADDRESS =
        address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    IPolygon public PolygonPOS;
    address public erc20Predicate;

    constructor(address _PolygonPOS, address _erc20Predicate) {
        PolygonPOS = IPolygon(_PolygonPOS);
        erc20Predicate = _erc20Predicate;
    }

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
        bytes memory //extraData
    ) external payable nonReentrant {
        require(
            msg.value == amount,
            "Wagpay: Please send amount greater than 0"
        );
        require(msg.value != 0, "WagPay: Please send amount greater than 0");
        PolygonPOS.depositEtherFor{value: amount}(receiver);

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
        bytes memory //extraData
    ) external nonReentrant {
        require(amount > 0, "WagPay: Please send amount greater than 0");

        IERC20(tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        IERC20(tokenAddress).safeIncreaseAllowance(erc20Predicate, amount);

        PolygonPOS.depositFor(receiver, tokenAddress, abi.encode(amount));

        emit ERC20FundsTransferred(receiver, toChainId, amount, tokenAddress);
    }

    /**
	// @notice function responsible to change pool address
	// @param  newPool address of new pool
	 */
    function changePool(address newPool) external onlyOwner {
        PolygonPOS = IPolygon(newPool);
    }

    /**
	// @notice function responsible to change erc20Predicate address
	// @param  _erc20Predicate address of new erc20Predicate
	 */
    function changeERC20Predicate(address _erc20Predicate) external onlyOwner {
        erc20Predicate = _erc20Predicate;
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
