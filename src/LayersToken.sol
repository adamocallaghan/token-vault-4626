// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract LayersToken is ERC20 {
    constructor() ERC20("LayersToken", "LYRT", 18) {}

    function mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }
}
