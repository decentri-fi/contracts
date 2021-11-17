pragma solidity ^0.8.0;

interface LpYeetIn {
    function PerformYeetIn(
        address _FromTokenContractAddress,
        address _pairAddress,
        uint256 _amount,
        uint256 _minPoolTokens
    ) external payable returns (uint256) ;
}