// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/general/BeefyVaultV6.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../lp/LPYeetIn.sol";
import "../YeetIn.sol";

contract YeetInBeefy is YeetIn {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor(address _treasury) Yeet(50, _treasury) {
    }

    function PerformYeetIn(
        address _fromTokenContractAddress,
        uint256 _amount,
        uint256 _minPoolTokens,
        address beefyVault,
        address underlyingYeet
    ) external payable stopInEmergency returns (uint256) {
        address want = address(BeefyVaultV6(beefyVault).want());
        uint256 beforeBalanceOfWant = IERC20(want).balanceOf(address(this));

        uint256 pulledTokens = _pullTokens(
            _fromTokenContractAddress,
            _amount,
            false
        );

        _approveToken(_fromTokenContractAddress, underlyingYeet);
        LpYeetIn(underlyingYeet).PerformYeetIn(
            _fromTokenContractAddress,
            want,
            pulledTokens,
            _minPoolTokens
        );

        uint256 afterBalanceOfWant = IERC20(want).balanceOf(address(this));
        uint256 toInvest = afterBalanceOfWant.sub(beforeBalanceOfWant);

        uint256 beforeBalanceOfMoo = IERC20(beefyVault).balanceOf(address(this));
        _approveToken(want, beefyVault);
        BeefyVaultV6(beefyVault).deposit(toInvest);
        uint256 afterBalanceOfMoo = IERC20(beefyVault).balanceOf(address(this));

        uint256 amountBought = afterBalanceOfMoo.sub(beforeBalanceOfMoo);
        emit YeetedIn(msg.sender, beefyVault, amountBought);

        IERC20(beefyVault).safeTransfer(msg.sender, amountBought);
        return amountBought;
    }

    /**
     * @dev Rescues random funds stuck that the strat can't handle.
     * @param _token address of the token to rescue.
     */
    function inCaseTokensGetStuck(address _token) external onlyOwner {
        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(msg.sender, amount);
    }
}