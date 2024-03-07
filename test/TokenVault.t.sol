// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TokenVault} from "../src/TokenVault.sol";
import {LayersToken} from "../src/LayersToken.sol";

contract TokenVaultTest is Test {
    // variables
    TokenVault public vault;
    address public bob = makeAddr("bob");
    address public alice = makeAddr("alice");
    uint256 public STARTING_BALANCE = 10000;

    // layersToken
    LayersToken public layersToken;

    function setUp() public {
        // create our underlying asset token that gets deposited to the 4626 vault
        layersToken = new LayersToken();

        // mint some tokens to our test users
        layersToken.mint(bob, 50e18);
        layersToken.mint(alice, 50e18);

        // create instance of our contract
        vault = new TokenVault(layersToken, "vaultLayers", "vLayers");

        // give our users some ETH to transact with
        vm.deal(bob, STARTING_BALANCE);
        vm.deal(alice, STARTING_BALANCE);
    }

    function test_depositAssets() public {
        depositAssetsAsBob();

        uint256 bobBalance = vault.totalSharesOfUser(bob); // this gets the 'shares' bob has
        assertEq(bobBalance, 100000);
    }

    function test_assetsDeposited() public {
        depositAssetsAsBob();

        uint256 bobBalance = vault.totalAssetsUserHasDeposited(bob); // this gets the 'assets' depostied using our own accounting/mapping
        assertEq(bobBalance, 100000); // test should always pass as this is just what we've put in, not the underlying pool of assets including any from our strategy
    }

    function test_assetsDepositedEqualBalanceOfTokenVault() public {
        depositAssetsAsBob();

        uint256 bobAssetDeposited = vault.totalAssetsUserHasDeposited(bob); // our own accounting
        uint256 bobShareBalance = vault.totalSharesOfUser(bob); // internal 'share' accounting - remember this is an ERC20 token so we can call balanceOf()
        assertEq(bobAssetDeposited, bobShareBalance);
    }

    function test_withdrawAssetsUsingShares() public {
        depositAssetsAsBob();

        vm.startPrank(bob);
        vault._withdraw(99111); // we're leaving just 456 LayersToken in the contract
        vm.stopPrank();

        uint256 bobBalance = vault.totalSharesOfUser(bob);
        assertEq(bobBalance, 889);
    }

    function test_previewRedeem_noStrategy() public {
        depositAssetsAsBob();

        uint256 sharesToAssetsRedemtion = vault.previewRedeem(10000); // how many assets do I get back fro 10,000 shares?
        assertEq(sharesToAssetsRedemtion, 10000); // assets back should be == shares sent (as there is no strategy to increase the underlying asset token)
    }

    function test_previewRedeem_withStrategy() public {
        depositAssetsAsBob();

        vm.startPrank(alice);
        layersToken.transfer(address(vault), 100000); // we are directly transferring tokens into the contract as if they have been earned using a strategy!
        vm.stopPrank();

        // bob: deposited 100,000 tokens (and was issued shares)
        // alice: *directly* transferred 100,000 (i.e. was not issued shares)
        // TOTAL TOKENS IN CONTRACT = 200,000

        // 200,000 tokens / 100,000 shares = 2

        console.log(vault.totalAssets());
        console.log(vault.balanceOf(bob));
        console.log(vault.balanceOf(alice));

        uint256 sharesToAssetsRedemtion = vault.previewRedeem(10000); // how many assets do I get back fro 10,000 shares?
        assertEq(sharesToAssetsRedemtion, 10000); // assets back should be == shares sent (as there is no strategy to increase the underlying asset token)
    }

    // === HELPERS ===
    function depositAssetsAsBob() public {
        vm.startPrank(bob);
        layersToken.approve(address(vault), 999000);
        vault._deposit(100000);
        vm.stopPrank();
    }
}
