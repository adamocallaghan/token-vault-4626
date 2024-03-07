// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenVault} from "../src/TokenVault.sol";
import {USDC} from "../src/USDC.sol";

contract TokenVaultTest is Test {
    // variables
    TokenVault public vault; // our token vault
    USDC public usdc; // our asset token to deposit

    address public bob = makeAddr("bob");
    address public alice = makeAddr("alice");
    uint256 public STARTING_BALANCE = 10000;

    function setUp() public {
        // create our underlying asset token that gets deposited to the 4626 vault
        usdc = new USDC();

        // mint some tokens to our test users
        usdc.mint(bob, 50e18);
        usdc.mint(alice, 50e18);

        // create instance of our contract
        vault = new TokenVault(usdc, "vaultUSDC", "vUSDC");

        // give our users some ETH to transact with
        vm.deal(bob, STARTING_BALANCE);
        vm.deal(alice, STARTING_BALANCE);
    }

    function test_depositAssets() public {
        depositAssetsAsBob();

        uint256 bobBalance = vault.totalSharesOfUser(bob); // this gets the 'shares' bob has
        assertEq(bobBalance, 100000);
    }

    function test_withdrawAssetsUsingShares() public {
        depositAssetsAsBob();

        vm.startPrank(bob);
        vault._withdraw(99111); // we're leaving just 456 USDC in the contract
        vm.stopPrank();

        uint256 bobBalance = vault.totalSharesOfUser(bob);
        assertEq(bobBalance, 889);
    }

    // === NO STRATEGY ===
    function test_previewRedeem_noStrategy() public {
        depositAssetsAsBob();

        uint256 sharesToAssetsRedemtion = vault.previewRedeem(10000); // how many assets do I get back fro 10,000 shares?
        assertEq(sharesToAssetsRedemtion, 10000); // assets back should be == shares sent (as there is no strategy to increase the underlying asset token)
    }

    // === WITH STRATEGY ===
    function test_previewRedeem_withStrategy() public {
        depositAssetsAsBob();

        vm.startPrank(alice);
        usdc.transfer(address(vault), 100000); // we are directly transferring tokens into the contract as if they have been earned using a strategy!
        vm.stopPrank();

        // bob: deposited 100,000 tokens (and was issued shares)
        // alice: *directly* transferred 100,000 (i.e. was not issued shares) <=== "alice" is acting in place of a DeFi strategy here!
        // TOTAL TOKENS IN CONTRACT = 200,000

        // 200,000 tokens / 100,000 shares = 2

        uint256 sharesToAssetsRedemtion = vault.previewRedeem(10000); // how many assets do I get back for 10,000 shares?
        assertEq(sharesToAssetsRedemtion, 20000); // assets back should be the shares multiplied by 2 as this is
    }

    // === HELPERS ===
    function depositAssetsAsBob() public {
        vm.startPrank(bob);
        usdc.approve(address(vault), 999000);
        vault._deposit(100000);
        vm.stopPrank();
    }
}
