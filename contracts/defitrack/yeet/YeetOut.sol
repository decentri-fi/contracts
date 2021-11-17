// SPDX-License-Identifier: MIT

import "./Yeet.sol";

abstract contract YeetOut is Yeet {
    using SafeERC20 for IERC20;

    event YeetedOut(
        address sender,
        address pool,
        address token,
        uint256 tokensRec
    );

    /**
        @dev Transfer tokens from msg.sender to this contract
        @param token The ERC20 token to transfer to this contract
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
        @return Quantity of tokens transferred to this contract
     */
    function _pullTokens(
        address token,
        uint256 amount,
        bool shouldSellEntireBalance
    ) internal returns (uint256) {
        if (shouldSellEntireBalance) {
            require(
                Address.isContract(msg.sender),
                "ERR: shouldSellEntireBalance is true for EOA"
            );

            uint256 allowance =
            IERC20(token).allowance(msg.sender, address(this));
            IERC20(token).safeTransferFrom(
                msg.sender,
                address(this),
                allowance
            );

            return allowance;
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

            return amount;
        }
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        if (enableGoodwill && goodwill > 0) {
            return  (amount * goodwill) / 10000;
        } else {
            return 0;
        }
    }
}