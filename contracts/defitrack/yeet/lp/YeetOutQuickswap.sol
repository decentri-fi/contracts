//// SPDX-License-Identifier: MIT
//
//pragma solidity ^0.8.0;
//
//import "./interfaces/uniswap/IUniswapV2Factory.sol";
//import "./interfaces/uniswap/IUniswapV2Router.sol";
//import "./YeetIn.sol";
//import "./YeetOut.sol";
//import "./interfaces/uniswap/IUniswapV2Pair.sol";
//import "./interfaces/general/IWETH.sol";
//import "@uniswap/lib/contracts/libraries/Babylonian.sol";
//
//contract YeetQuickswap is YeetIn, YeetOut {
//    using SafeERC20 for IERC20;
//
//    IUniswapV2Factory private constant quickswapFactory = IUniswapV2Factory(0x5757371414417b8C6CAad45bAeF941aBc7d3Ab32);
//    IUniswapV2Router02 private constant quickswapRouter = IUniswapV2Router02(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);
//
//    address private constant wmaticTokenAddress = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
//
//    uint256 private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;
//
//    uint256 private constant permitAllowance = 79228162514260000000000000000;
//
//    constructor(uint256 _goodwill) Yeet(_goodwill) {
//    }
//
//    /**
//    @notice Add liquidity to Quickswap pools with ETH/ERC20 Tokens
//    @param _FromTokenContractAddress The ERC20 token used (address(0x00) if ether)
//    @param _pairAddress The Quickswap pair address
//    @param _amount The amount of fromToken to invest
//    @param _minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
//    @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
//    @return Amount of LP bought
//     */
//    function PerformYeetIn(
//        address _FromTokenContractAddress,
//        address _pairAddress,
//        uint256 _amount,
//        uint256 _minPoolTokens,
//        bool shouldSellEntireBalance
//    ) external payable stopInEmergency returns (uint256) {
//        uint256 toInvest = _pullTokens(
//            _FromTokenContractAddress,
//            _amount,
//            true,
//            shouldSellEntireBalance
//        );
//
//        uint256 LPBought = _performYeetIn(
//            _FromTokenContractAddress,
//            _pairAddress,
//            toInvest
//        );
//        require(LPBought >= _minPoolTokens, "High Slippage");
//
//        emit YeetedIn(msg.sender, _pairAddress, LPBought);
//
//        IERC20(_pairAddress).safeTransfer(msg.sender, LPBought);
//        return LPBought;
//    }
//
//    function PerformYeetOut2PairToken(
//        address fromPoolAddress,
//        uint256 incomingLP
//    ) public stopInEmergency returns (uint256 amountA, uint256 amountB) {
//        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);
//
//        require(address(pair) != address(0), "Pool Cannot be Zero Address");
//
//        // get reserves
//        address token0 = pair.token0();
//        address token1 = pair.token1();
//
//        IERC20(fromPoolAddress).safeTransferFrom(msg.sender, address(this), incomingLP);
//
//        _approveToken(fromPoolAddress, address(quickswapRouter), incomingLP);
//
//        (amountA, amountB) = quickswapRouter.removeLiquidity(
//            token0,
//            token1,
//            incomingLP,
//            1,
//            1,
//            address(this),
//            deadline
//        );
//
//        // subtract goodwill
//        uint256 tokenAGoodwill = _subtractGoodwill(token0, amountA, true);
//        uint256 tokenBGoodwill = _subtractGoodwill(token1, amountB, true);
//
//        // send tokens
//        IERC20(token0).safeTransfer(msg.sender, amountA - tokenAGoodwill);
//        IERC20(token1).safeTransfer(msg.sender, amountB - tokenBGoodwill);
//
//        emit YeetedOut(msg.sender, fromPoolAddress, token0, amountA);
//        emit YeetedOut(msg.sender, fromPoolAddress, token1, amountB);
//    }
//
//    /**
//    @notice Yeet out in a single token
//    @param toTokenAddress Address of desired token
//    @param fromPoolAddress Pool from which to remove liquidity
//    @param incomingLP Quantity of LP to remove from pool
//    @param minTokensRec Minimum quantity of tokens to receive
//    @param swapTargets Execution targets for swaps
//    @param swapData DEX swap data
//    @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
//    */
//    function PerformYeetOut(
//        address toTokenAddress,
//        address fromPoolAddress,
//        uint256 incomingLP,
//        uint256 minTokensRec,
//        address[] memory swapTargets,
//        bytes[] memory swapData,
//        bool shouldSellEntireBalance
//    ) public stopInEmergency returns (uint256 tokensRec) {
//        (uint256 amount0, uint256 amount1) =
//        _removeLiquidity(
//            fromPoolAddress,
//            incomingLP,
//            shouldSellEntireBalance
//        );
//
//        //swaps tokens to token
//        tokensRec = _swapTokens(
//            fromPoolAddress,
//            amount0,
//            amount1,
//            toTokenAddress
//        );
//        require(tokensRec >= minTokensRec, "High Slippage");
//
//        uint256 totalGoodwillPortion;
//
//        // transfer toTokens to sender
//        if (toTokenAddress == address(0)) {
//            totalGoodwillPortion = _subtractGoodwill(
//                ETHAddress,
//                tokensRec,
//                true
//            );
//
//            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
//        } else {
//            totalGoodwillPortion = _subtractGoodwill(
//                toTokenAddress,
//                tokensRec,
//                true
//            );
//
//            IERC20(toTokenAddress).safeTransfer(
//                msg.sender,
//                tokensRec - totalGoodwillPortion
//            );
//        }
//
//        tokensRec = tokensRec - totalGoodwillPortion;
//
//        emit YeetedOut(msg.sender, fromPoolAddress, toTokenAddress, tokensRec);
//
//        return tokensRec;
//    }
//
//    /**
//    @notice Yeet out in both tokens with permit
//    @param fromPoolAddress Pool from which to remove liquidity
//    @param incomingLP Quantity of LP to remove from pool
//    @param permitSig Signature for permit
//    @return amountA Quantity of tokenA received
//    @return amountB Quantity of tokenB received
//    */
//    function PerformYeetOut2PairTokenWithPermit(
//        address fromPoolAddress,
//        uint256 incomingLP,
//        bytes calldata permitSig
//    ) external stopInEmergency returns (uint256 amountA, uint256 amountB) {
//        // permit
//        _permit(fromPoolAddress, permitAllowance, permitSig);
//
//        (amountA, amountB) = PerformYeetOut2PairToken(
//            fromPoolAddress,
//            incomingLP
//        );
//    }
//
//    /**
//    @notice Yeet out in a single token with permit
//    @param toTokenAddress Address of desired token
//    @param fromPoolAddress Pool from which to remove liquidity
//    @param incomingLP Quantity of LP to remove from pool
//    @param minTokensRec Minimum quantity of tokens to receive
//    @param permitSig Signature for permit
//    @param swapTargets Execution targets for swaps
//    @param swapData DEX swap data
//    */
//    function PerformYeetOutWithPermit(
//        address toTokenAddress,
//        address fromPoolAddress,
//        uint256 incomingLP,
//        uint256 minTokensRec,
//        bytes calldata permitSig,
//        address[] memory swapTargets,
//        bytes[] memory swapData
//    ) public stopInEmergency returns (uint256) {
//        // permit
//        _permit(fromPoolAddress, permitAllowance, permitSig);
//
//        return (
//        PerformYeetOut(
//            toTokenAddress,
//            fromPoolAddress,
//            incomingLP,
//            minTokensRec,
//            false
//        )
//        );
//    }
//
//    function _permit(
//        address fromPoolAddress,
//        uint256 amountIn,
//        bytes memory permitSig
//    ) internal {
//        require(permitSig.length == 65, "Invalid signature length");
//
//        bytes32 r;
//        bytes32 s;
//        uint8 v;
//        assembly {
//            r := mload(add(permitSig, 32))
//            s := mload(add(permitSig, 64))
//            v := byte(0, mload(add(permitSig, 96)))
//        }
//        IUniswapV2Pair(fromPoolAddress).permit(
//            msg.sender,
//            address(this),
//            amountIn,
//            deadline,
//            v,
//            r,
//            s
//        );
//    }
//
//    function _removeLiquidity(
//        address fromPoolAddress,
//        uint256 incomingLP,
//        bool shouldSellEntireBalance
//    ) internal returns (uint256 amount0, uint256 amount1) {
//        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);
//
//        require(address(pair) != address(0), "Pool Cannot be Zero Address");
//
//        address token0 = pair.token0();
//        address token1 = pair.token1();
//
//        _pullTokens(fromPoolAddress, incomingLP, shouldSellEntireBalance);
//
//        _approveToken(fromPoolAddress, address(quickswapRouter), incomingLP);
//
//        (amount0, amount1) = quickswapRouter.removeLiquidity(
//            token0,
//            token1,
//            incomingLP,
//            1,
//            1,
//            address(this),
//            deadline
//        );
//        require(amount0 > 0 && amount1 > 0, "Removed Insufficient Liquidity");
//    }
//
//    function _swapTokens(
//        address fromPoolAddress,
//        uint256 amount0,
//        uint256 amount1,
//        address toToken
//    ) internal returns (uint256 tokensBought) {
//        address token0 = IUniswapV2Pair(fromPoolAddress).token0();
//        address token1 = IUniswapV2Pair(fromPoolAddress).token1();
//
//        //swap token0 to toToken
//        if (token0 == toToken) {
//            tokensBought = tokensBought + amount0;
//        } else {
//            (uint256 amount0Bought, address intermediateToken) = _swapFromTokenToToken(
//                token0,
//                toToken,
//                amount0
//            );
//
//            tokensBought = tokensBought + amount0Bought;
//        }
//
//        //swap token1 to toToken
//        if (token1 == toToken) {
//            tokensBought = tokensBought + amount1;
//        } else {
//
//            (uint256 amountBought, address intermdiateToken) = _swapFromTokenToToken(
//                token1,
//                toToken,
//                amount1
//            );
//
//            tokensBought = tokensBought + amountBought;
//        }
//    }
//
//    function _getPairTokens(address _pairAddress)
//    internal
//    pure
//    returns (address token0, address token1)
//    {
//        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);
//        token0 = uniPair.token0();
//        token1 = uniPair.token1();
//    }
//
//    function _performYeetIn(
//        address _FromTokenContractAddress,
//        address _pairAddress,
//        uint256 _amount
//    ) internal returns (uint256) {
//
//        uint256 intermediateAmt;
//        address intermediateToken;
//
//        (address _ToUniswapToken0, address _ToUniswapToken1) = _getPairTokens(_pairAddress);
//
//        if (
//            _FromTokenContractAddress != _ToUniswapToken0 &&
//            _FromTokenContractAddress != _ToUniswapToken1
//        ) {
//            // swap to intermediate
//            (intermediateAmt, intermediateToken) = _fillQuote(
//                _FromTokenContractAddress,
//                _pairAddress,
//                _amount
//            );
//        } else {
//            intermediateToken = _FromTokenContractAddress;
//            intermediateAmt = _amount;
//        }
//
//        // divide intermediate into appropriate amount to add liquidity
//        (uint256 token0Bought, uint256 token1Bought) = _swapIntermediate(
//            intermediateToken,
//            _ToUniswapToken0,
//            _ToUniswapToken1,
//            intermediateAmt
//        );
//
//        return _uniDeposit(
//            _ToUniswapToken0,
//            _ToUniswapToken1,
//            token0Bought,
//            token1Bought
//        );
//    }
//
//    function _uniDeposit(
//        address _ToUnipoolToken0,
//        address _ToUnipoolToken1,
//        uint256 token0Bought,
//        uint256 token1Bought
//    ) internal returns (uint256) {
//        _approveToken(_ToUnipoolToken0, address(quickswapRouter), token0Bought);
//        _approveToken(_ToUnipoolToken1, address(quickswapRouter), token1Bought);
//
//        (uint256 amountA, uint256 amountB, uint256 LP) =
//        quickswapRouter.addLiquidity(
//            _ToUnipoolToken0,
//            _ToUnipoolToken1,
//            token0Bought,
//            token1Bought,
//            1,
//            1,
//            address(this),
//            deadline
//        );
//
//        //Returning Residue in token0, if any.
//        if (token0Bought - amountA > 0) {
//            IERC20(_ToUnipoolToken0).safeTransfer(
//                msg.sender,
//                token0Bought - amountA
//            );
//        }
//
//        //Returning Residue in token1, if any
//        if (token1Bought - amountB > 0) {
//            IERC20(_ToUnipoolToken1).safeTransfer(
//                msg.sender,
//                token1Bought - amountB
//            );
//        }
//
//        return LP;
//    }
//
//    function _swapFromTokenToToken(
//        address fromTokenAddress,
//        address toToken,
//        uint256 amount
//    ) internal returns (uint256) {
//        if (fromTokenAddress == wmaticTokenAddress && toToken == address(0)) {
//            IWETH(wmaticTokenAddress).withdraw(amount);
//            return amount;
//        }
//
//        uint256 valueToSend;
//        if (fromTokenAddress == address(0)) {
//            valueToSend = amount;
//        } else {
//            _approveToken(fromTokenAddress, swapTarget, amount);
//        }
//
//        uint256 initialBalance = _getBalance(toToken);
//
//        require(approvedTargets[swapTarget], "Target not Authorized");
//        (bool success,) = swapTarget.call{value : valueToSend}(swapData);
//        require(success, "Error Swapping Tokens");
//
//        uint256 finalBalance = _getBalance(toToken) - initialBalance;
//
//        require(finalBalance > 0, "Swapped to Invalid Intermediate");
//
//        return finalBalance;
//    }
//
//
//    function _swapIntermediate(
//        address _toContractAddress,
//        address _ToUnipoolToken0,
//        address _ToUnipoolToken1,
//        uint256 _amount
//    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
//        IUniswapV2Pair pair = IUniswapV2Pair(
//            quickswapFactory.getPair(_ToUnipoolToken0, _ToUnipoolToken1)
//        );
//
//        (uint256 res0, uint256 res1,) = pair.getReserves();
//
//        if (_toContractAddress == _ToUnipoolToken0) {
//            uint256 amountToSwap = calculateSwapInAmount(res0, _amount);
//            //if no reserve or a new pair is created
//            if (amountToSwap <= 0) amountToSwap = _amount / 2;
//            token1Bought = _token2Token(
//                _toContractAddress,
//                _ToUnipoolToken1,
//                amountToSwap
//            );
//            token0Bought = _amount - amountToSwap;
//        } else {
//            uint256 amountToSwap = calculateSwapInAmount(res1, _amount);
//            //if no reserve or a new pair is created
//            if (amountToSwap <= 0) amountToSwap = _amount / 2;
//            token0Bought = _token2Token(
//                _toContractAddress,
//                _ToUnipoolToken0,
//                amountToSwap
//            );
//            token1Bought = _amount - amountToSwap;
//        }
//    }
//
//    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
//    internal
//    pure
//    returns (uint256)
//    {
//        return
//        (Babylonian.sqrt(
//            reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
//        ) - (reserveIn * 1997)) / 1994;
//    }
//
//    /**
//    @notice This function is used to swap ERC20 <> ERC20
//    @param _FromTokenContractAddress The token address to swap from.
//    @param _ToTokenContractAddress The token address to swap to.
//    @param tokens2Trade The amount of tokens to swap
//    @return tokenBought The quantity of tokens bought
//    */
//    function _token2Token(
//        address _FromTokenContractAddress,
//        address _ToTokenContractAddress,
//        uint256 tokens2Trade
//    ) internal returns (uint256 tokenBought) {
//        if (_FromTokenContractAddress == _ToTokenContractAddress) {
//            return tokens2Trade;
//        }
//
//        _approveToken(
//            _FromTokenContractAddress,
//            address(quickswapRouter),
//            tokens2Trade
//        );
//
//        address pair =
//        quickswapFactory.getPair(
//            _FromTokenContractAddress,
//            _ToTokenContractAddress
//        );
//        require(pair != address(0), "No Swap Available");
//        address[] memory path = new address[](2);
//        path[0] = _FromTokenContractAddress;
//        path[1] = _ToTokenContractAddress;
//
//        tokenBought = quickswapRouter.swapExactTokensForTokens(
//            tokens2Trade,
//            1,
//            path,
//            address(this),
//            deadline
//        )[path.length - 1];
//
//        require(tokenBought > 0, "Error Swapping Tokens 2");
//    }
//}