// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface IPolygon {
    function depositEtherFor(address user) external payable;

    function depositFor(
        address sender,
        address token,
        bytes memory extraData
    ) external;

    function withdraw(uint256 amount) external;
}
