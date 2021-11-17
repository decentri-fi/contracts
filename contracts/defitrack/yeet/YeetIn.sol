// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Yeet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract YeetIn is Yeet {
    using SafeERC20 for IERC20;

    event YeetedIn(address sender, address pool, uint256 tokensRec);

    function _pullTokens(
        address token,
        uint256 amount,
        bool enableGoodwill
    ) internal returns (uint256 value) {
        uint256 totalGoodwillPortion;

        if (token == address(0)) {
            require(msg.value > 0, "No native currency sent");

            // subtract goodwill
            totalGoodwillPortion = _subtractGoodwill(
                ETHAddress,
                msg.value,
                enableGoodwill
            );

            return msg.value - totalGoodwillPortion;
        } else {
            require(IERC20(token).allowance(msg.sender, address(this)) > 0, "user hasn't approved yet");
        }
        require(amount > 0, "Invalid token amount");
        require(msg.value == 0, "Eth sent with token");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // subtract goodwill
        totalGoodwillPortion = _subtractGoodwill(
            token,
            amount,
            enableGoodwill
        );

        return amount - totalGoodwillPortion;
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        if (enableGoodwill && goodwill > 0) {
            totalGoodwillPortion = (amount * goodwill) / 10000;
            return totalGoodwillPortion;
        } else {
            return 0;
        }
    }
}