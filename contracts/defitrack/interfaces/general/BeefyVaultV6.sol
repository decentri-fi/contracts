import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface BeefyVaultV6 {
    function want() external view returns (IERC20);
    function deposit(uint _amount) external;
}