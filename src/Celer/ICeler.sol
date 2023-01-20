// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

interface ICeler {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChinId,
        uint256 _nonce,
        uint32 _maxSlippage
    ) external;

    function sendNative(
        address _receiver,
        uint256 _amount,
        uint64 _dstChinId,
        uint256 _nonce,
        uint32 _maxSlippage
    ) external payable;
}
