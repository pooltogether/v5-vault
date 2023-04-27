// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { UnitBaseSetup, IERC20, PrizePool, VaultMock } from "test/utils/UnitBaseSetup.t.sol";

contract VaultMigrateTest is UnitBaseSetup {
  /* ============ Events ============ */
  event MigrateToVault(
    VaultMock indexed toVault,
    address indexed caller,
    uint256 assets,
    uint256 shares
  );

  /* ============ Variables ============ */
  VaultMock public toVault;

  /* ============ Setup ============ */
  function setUp() public override {
    super.setUp();

    toVault = new VaultMock(
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
    vault.approveToVault(toVault);

    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    underlyingAsset.mint(alice, _amount);
    _deposit(underlyingAsset, vault, _amount, alice);

    uint256 _shares = vault.convertToShares(_amount);

    vm.expectEmit();
    emit MigrateToVault(toVault, alice, _amount, _shares);

    vault.redeemToVault(toVault, vault.maxRedeem(alice));

    assertEq(vault.balanceOf(alice), 0);
    assertEq(toVault.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), 0);
    assertEq(twabController.balanceOf(address(toVault), alice), _amount);

    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);
    assertEq(twabController.delegateBalanceOf(address(toVault), alice), _amount);

    assertEq(yieldVault.balanceOf(address(vault)), 0);
    assertEq(yieldVault.balanceOf(address(toVault)), _amount);

    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _amount);

    vm.stopPrank();
  }
}
