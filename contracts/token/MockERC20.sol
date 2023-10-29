// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockERC20 is ERC20, Ownable {
    constructor(address initialOwner) ERC20("MockERC20", "MERC20") {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
