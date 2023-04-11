// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { UnitBaseSetup, IERC20, PrizePool, Vault } from "test/utils/UnitBaseSetup.t.sol";

contract VaultMigrateTest is UnitBaseSetup {
  /* ============ Events ============ */
  event MigrateToVault(
    Vault indexed fromVault,
    Vault indexed toVault,
    address indexed caller,
    uint256 assets,
    uint256 shares
  );

  /* ============ Variables ============ */
  Vault public toVault;

  /* ============ Setup ============ */
  function setUp() public override {
    super.setUp();

    toVault = new Vault(
      underlyingAsset,
      vaultName,
      vaultSymbol,
      twabController,
      yieldVault,
      PrizePool(address(prizePool)),
      claimer,
      address(this),
      0,
      address(this)
    );
  }

  /* ============ Tests ============ */

  /* ============ Withdraw ============ */
  function testRedeemToVaultSameYieldVault() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    underlyingAsset.mint(alice, _amount);
    _deposit(underlyingAsset, vault, _amount, alice);

    uint256 _shares = vault.convertToShares(_amount);

    vm.expectEmit();
    emit MigrateToVault(vault, toVault, alice, _amount, _shares);

    vault.redeemToVault(toVault, vault.maxRedeem(alice));

    // assertEq(vault.balanceOf(alice), 0);
    // assertEq(underlyingAsset.balanceOf(alice), _amount);

    // assertEq(twabController.balanceOf(address(vault), alice), 0);
    // assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    // assertEq(yieldVault.balanceOf(address(vault)), 0);
    // assertEq(underlyingAsset.balanceOf(address(yieldVault)), 0);

    vm.stopPrank();
  }
}
