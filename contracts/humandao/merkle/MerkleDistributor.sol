import "./IMerkleDistributor.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleDistributor is IMerkleDistributor {
    bytes32 public immutable override merkleRoot;

    /// @param _merkleRoot Merkle root for the game
    constructor(bytes32 _merkleRoot) public {
        merkleRoot = _merkleRoot;
    }

    /// @notice Responsible for validating player merkle proof
    /// @param index Merkle Proof Player Index
    /// @param account Player Address
    /// @param isValid Bool Flag
    /// @param merkleProof Merkle proof of the player
    function claim(
        uint256 index,
        address account,
        bool isValid,
        bytes32[] calldata merkleProof
    ) public view override {
        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, isValid));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof"
        );
    }
}