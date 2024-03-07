// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC4626} from "lib/solmate/src/tokens/ERC4626.sol";
import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";

contract TokenVault is ERC4626 {
    mapping(address => uint256) public assetsDeposited;

    constructor(ERC20 _asset, string memory _name, string memory _symbol) ERC4626(_asset, _name, _symbol) {}

    function _deposit(uint256 _assets) public {
        require(_assets > 0, "Zero assets deposited");
        assetsDeposited[msg.sender] += _assets;
        deposit(_assets, msg.sender);
    }

    function _withdraw(uint256 _shares) public {
        // checks
        require(_shares > 0, "Zero shares sent to withdraw against");
        require(assetsDeposited[msg.sender] > 0, "No assets currently deposited");
        require(assetsDeposited[msg.sender] >= _shares, "Not enough shares sent");

        // effects
        assetsDeposited[msg.sender] -= _shares;

        // interactions
        redeem(_shares, msg.sender, msg.sender);
    }

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }

    function totalAssetsOfUser(address _user) public view returns (uint256) {
        return asset.balanceOf(_user);
    }

    function totalSharesOfUser(address _user) public view returns (uint256) {
        return this.balanceOf(_user);
    }

    function totalAssetsUserHasDeposited(address _user) public view returns (uint256) {
        return assetsDeposited[_user];
    }
}
