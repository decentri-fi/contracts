// SPDX-License-Identifier: MIT
// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.0/contracts/utils/cryptography/MerkleProof.sol

pragma solidity ^0.8.0;

import "./MerkleProof.sol";

contract MerkleProofHelper {

    function verify(
        bytes32 merkleRoot, uint256 amount, bytes32[] calldata merkleProof, address owner
    ) pure external returns (bool valid, uint256 index){
        bytes32 leaf = keccak256(abi.encodePacked(owner, amount));
        return MerkleProof.verify(merkleProof, merkleRoot, leaf);
    }
}