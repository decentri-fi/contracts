// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/uniswap/IUniswapV2Factory.sol";
import "../../interfaces/uniswap/IUniswapV2Router.sol";
import "../../interfaces/uniswap/IUniswapV2Pair.sol";
import "../../interfaces/general/IWETH.sol";
import "@uniswap/lib/contracts/libraries/Babylonian.sol";
import "../YeetIn.sol";
import "./LPYeetIn.sol";

contract YeetInSushi is YeetIn, LpYeetIn {
    using SafeERC20 for IERC20;

    IUniswapV2Factory public sushiFactory;
    IUniswapV2Router02 public sushiRouter;

    address private constant wmaticTokenAddress = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);

    uint256 private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant permitAllowance = 79228162514260000000000000000;

    constructor(uint256 _goodwill, address _treasury, address _sushiFactory, address _sushiRouter) Yeet(_goodwill, _treasury) {
        require(_sushiFactory != address(0), "Sushifactory cannot be null address");
        require(_sushiRouter != address(0), "SushiRouter cannot be null address");
        sushiFactory = IUniswapV2Factory(_sushiFactory);
        sushiRouter = IUniswapV2Router02(_sushiRouter);
    }

    /**
    @notice Add liquidity to Sushiswap pools with ETH/ERC20 Tokens
    @param _FromTokenContractAddress The ERC20 token used (address(0x00) if ether)
    @param _pairAddress The Sushiswap pair address
    @param _amount The amount of fromToken to invest
    @param _minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
    @return Amount of LP bought
     */
    function PerformYeetIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens
    ) external override payable stopInEmergency returns (uint256) {
        uint256 toInvest = _pullTokens(
            _FromTokenContractAddress,
            _amount,
            true
        );

        uint256 LPBought = _performYeetIn(
            _FromTokenContractAddress,
            _pairAddress,
            toInvest
        );
        require(LPBought >= _minPoolTokens, "High Slippage");

        emit YeetedIn(msg.sender, _pairAddress, LPBought);

        IERC20(_pairAddress).safeTransfer(msg.sender, LPBought);


        uint256 restBalance = IERC20(_FromTokenContractAddress).balanceOf(address(this));
        IERC20(_FromTokenContractAddress).safeTransfer(treasury, restBalance);
        return LPBought;
    }

    function _getPairTokens(address _pairAddress)
    internal
    pure
    returns (address token0, address token1)
    {
        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);
        token0 = uniPair.token0();
        token1 = uniPair.token1();
    }

    function _performYeetIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount
    ) internal returns (uint256) {

        uint256 intermediateAmt;
        address intermediateToken;

        (address _ToUniswapToken0, address _ToUniswapToken1) = _getPairTokens(_pairAddress);

        if (
            _FromTokenContractAddress != _ToUniswapToken0 &&
            _FromTokenContractAddress != _ToUniswapToken1
        ) {
            // swap input to wmatic
            (intermediateAmt, intermediateToken) = _swapToIntermediate(
                _FromTokenContractAddress,
                _amount
            );
        } else {
            intermediateToken = _FromTokenContractAddress;
            intermediateAmt = _amount;
        }

        // divide intermediate into appropriate amount to add liquidity
        (uint256 token0Bought, uint256 token1Bought) = _swapIntermediate(
            intermediateToken,
            _ToUniswapToken0,
            _ToUniswapToken1,
            intermediateAmt
        );

        return _uniDeposit(
            _ToUniswapToken0,
            _ToUniswapToken1,
            token0Bought,
            token1Bought
        );
    }

    function _uniDeposit(
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 token0Bought,
        uint256 token1Bought
    ) internal returns (uint256) {
        _approveToken(_ToUnipoolToken0, address(sushiFactory), token0Bought);
        _approveToken(_ToUnipoolToken1, address(sushiFactory), token1Bought);

        (uint256 amountA, uint256 amountB, uint256 LP) =
        sushiRouter.addLiquidity(
            _ToUnipoolToken0,
            _ToUnipoolToken1,
            token0Bought,
            token1Bought,
            1,
            1,
            address(this),
            deadline
        );

        //Returning Residue in token0, if any.
        if (token0Bought - amountA > 0) {
            IERC20(_ToUnipoolToken0).safeTransfer(
                msg.sender,
                token0Bought - amountA
            );
        }

        //Returning Residue in token1, if any
        if (token1Bought - amountB > 0) {
            IERC20(_ToUnipoolToken1).safeTransfer(
                msg.sender,
                token1Bought - amountB
            );
        }

        return LP;
    }

    function _swapToIntermediate(
       address _fromContractAddress,
       uint256 amount
    ) internal returns (uint256 amountBought, address intermediate) {
        uint256 amountIntermediateBought = _token2Token(_fromContractAddress, wmaticTokenAddress, amount);
        return (amountIntermediateBought, wmaticTokenAddress);
    }

    function _swapIntermediate(
        address _fromToken,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 _amount
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {

        IUniswapV2Pair pair = IUniswapV2Pair(
            sushiFactory.getPair(_ToUnipoolToken0, _ToUnipoolToken1)
        );

        (uint256 res0, uint256 res1,) = pair.getReserves();

        if (_fromToken == _ToUnipoolToken0) {
            uint256 amountToSwap = calculateSwapInAmount(res0, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token1Bought = _token2Token(
                _fromToken,
                _ToUnipoolToken1,
                amountToSwap
            );
            token0Bought = _amount - amountToSwap;
        } else if(_fromToken == _ToUnipoolToken1) {
            uint256 amountToSwap = calculateSwapInAmount(res1, _amount);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = _amount / 2;
            token0Bought = _token2Token(
                _fromToken,
                _ToUnipoolToken0,
                amountToSwap
            );
            token1Bought = _amount - amountToSwap;
        } else if(_fromToken == wmaticTokenAddress) {
            uint256 half = (_amount / 2) - 1;
            token0Bought = _token2Token(
                _fromToken,
                _ToUnipoolToken0,
                half
            );
            token1Bought = _token2Token(
                _fromToken,
                _ToUnipoolToken1,
                half
            );
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
    internal
    pure
    returns (uint256)
    {
        return
        (Babylonian.sqrt(
            reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))
        ) - (reserveIn * 1997)) / 1994;
    }

    /**
    @notice This function is used to swap ERC20 <> ERC20
    @param _FromTokenContractAddress The token address to swap from.
    @param _ToTokenContractAddress The token address to swap to.
    @param tokens2Trade The amount of tokens to swap
    @return tokenBought The quantity of tokens bought
    */
    function _token2Token(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        if (_FromTokenContractAddress == _ToTokenContractAddress) {
            return tokens2Trade;
        }

        _approveToken(
            _FromTokenContractAddress,
            address(sushiFactory),
            tokens2Trade
        );

        address pair =
        sushiFactory.getPair(
            _FromTokenContractAddress,
            _ToTokenContractAddress
        );
        require(pair != address(0), "No Swap Available");
        address[] memory path = new address[](2);
        path[0] = _FromTokenContractAddress;
        path[1] = _ToTokenContractAddress;

        tokenBought = sushiRouter.swapExactTokensForTokens(
            tokens2Trade,
            1,
            path,
            address(this),
            deadline
        )[path.length - 1];

        require(tokenBought > 0, "Error Swapping Tokens 2");
    }
}