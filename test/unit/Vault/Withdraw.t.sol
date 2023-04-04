// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import { UnitBaseSetup, IERC20 } from "test/utils/UnitBaseSetup.t.sol";

contract VaultWithdrawTest is UnitBaseSetup {
  /* ============ Events ============ */
  event Withdraw(
    address indexed sender,
    address indexed receiver,
    address indexed owner,
    uint256 assets,
    uint256 shares
  );

  /* ============ Tests ============ */

  /* ============ Withdraw ============ */
  function testWithdraw() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    underlyingAsset.mint(alice, _amount);
    _deposit(underlyingAsset, vault, _amount, alice);

    vm.expectEmit(true, true, true, true);
    emit Withdraw(alice, alice, alice, _amount, _amount);

    vault.withdraw(vault.maxWithdraw(alice), alice, alice);

    assertEq(vault.balanceOf(alice), 0);
    assertEq(underlyingAsset.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    assertEq(yieldVault.balanceOf(address(vault)), 0);
    assertEq(underlyingAsset.balanceOf(address(yieldVault)), 0);

    vm.stopPrank();
  }

  function testWithdrawHalfAmount() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    uint256 _halfAmount = _amount / 2;
    underlyingAsset.mint(alice, _amount);
    _deposit(underlyingAsset, vault, _amount, alice);

    vm.expectEmit(true, true, true, true);
    emit Withdraw(alice, alice, alice, _halfAmount, _halfAmount);

    vault.withdraw(_halfAmount, alice, alice);

    assertEq(vault.balanceOf(alice), _halfAmount);
    assertEq(underlyingAsset.balanceOf(alice), _halfAmount);

    assertEq(twabController.balanceOf(address(vault), alice), _halfAmount);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), _halfAmount);

    assertEq(yieldVault.maxWithdraw(address(vault)), _halfAmount);
    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _halfAmount);

    vm.stopPrank();
  }

  function testWithdrawFullAmountYieldAccrued() external {
    uint256 _amount = 1000e18;
    underlyingAsset.mint(alice, _amount);

    vm.startPrank(alice);

    _deposit(underlyingAsset, vault, _amount, alice);

    vm.stopPrank();

    uint256 _yield = 10e18;
    _accrueYield(underlyingAsset, yieldVault, _yield);

    vm.startPrank(alice);

    vm.expectEmit(true, true, true, true);
    emit Withdraw(alice, alice, alice, _amount, _amount);

    vault.withdraw(vault.maxWithdraw(alice), alice, alice);

    assertEq(vault.balanceOf(alice), 0);
    assertEq(underlyingAsset.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    assertEq(yieldVault.maxWithdraw(address(vault)), _yield);
    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _yield);

    vm.stopPrank();
  }

  function testWithdrawOnBehalf() external {
    uint256 _amount = 1000e18;
    underlyingAsset.mint(bob, _amount);

    vm.startPrank(bob);

    _deposit(underlyingAsset, vault, _amount, bob);
    IERC20(vault).approve(alice, _amount);

    vm.stopPrank();

    vm.startPrank(alice);

    vm.expectEmit(true, true, true, true);
    emit Withdraw(alice, bob, bob, _amount, _amount);

    vault.withdraw(vault.maxWithdraw(bob), bob, bob);

    assertEq(vault.balanceOf(bob), 0);
    assertEq(underlyingAsset.balanceOf(bob), _amount);

    assertEq(twabController.balanceOf(address(vault), bob), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), bob), 0);

    assertEq(yieldVault.balanceOf(address(vault)), 0);
    assertEq(underlyingAsset.balanceOf(address(yieldVault)), 0);

    vm.stopPrank();
  }

  /* ============ Redeem ============ */
  function testRedeemFullAmount() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    underlyingAsset.mint(alice, _amount);

    _deposit(underlyingAsset, vault, _amount, alice);
    vault.redeem(vault.maxRedeem(alice), alice, alice);

    assertEq(vault.balanceOf(alice), 0);
    assertEq(underlyingAsset.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    assertEq(underlyingAsset.balanceOf(address(yieldVault)), 0);
    assertEq(yieldVault.balanceOf(address(vault)), 0);

    vm.stopPrank();
  }

  function testRedeemHalfAmount() external {
    vm.startPrank(alice);

    uint256 _amount = 1000e18;
    uint256 _halfAmount = _amount / 2;
    underlyingAsset.mint(alice, _amount);

    uint256 _shares = _deposit(underlyingAsset, vault, _amount, alice);
    vault.redeem(_shares / 2, alice, alice);

    assertEq(vault.balanceOf(alice), _halfAmount);
    assertEq(underlyingAsset.balanceOf(alice), _halfAmount);

    assertEq(twabController.balanceOf(address(vault), alice), _halfAmount);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), _halfAmount);

    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _halfAmount);
    assertEq(yieldVault.balanceOf(address(vault)), _halfAmount);

    vm.stopPrank();
  }

  function testRedeemFullAmountYieldAccrued() external {
    uint256 _amount = 1000e18;
    underlyingAsset.mint(alice, _amount);

    vm.startPrank(alice);

    _deposit(underlyingAsset, vault, _amount, alice);

    vm.stopPrank();

    uint256 _yield = 10e18;
    _accrueYield(underlyingAsset, yieldVault, _yield);

    vm.startPrank(alice);

    vault.redeem(vault.maxRedeem(alice), alice, alice);

    assertEq(vault.balanceOf(alice), 0);
    assertEq(underlyingAsset.balanceOf(alice), _amount);

    assertEq(twabController.balanceOf(address(vault), alice), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), alice), 0);

    assertEq(yieldVault.balanceOf(address(vault)), yieldVault.convertToShares(_yield));
    assertEq(underlyingAsset.balanceOf(address(yieldVault)), _yield);

    vm.stopPrank();
  }

  function testRedeemOnBehalf() external {
    uint256 _amount = 1000e18;
    underlyingAsset.mint(bob, _amount);

    vm.startPrank(bob);

    _deposit(underlyingAsset, vault, _amount, bob);
    IERC20(vault).approve(alice, _amount);

    vm.stopPrank();

    vm.startPrank(alice);

    vm.expectEmit(true, true, true, true);
    emit Withdraw(alice, bob, bob, _amount, _amount);

    vault.redeem(vault.maxRedeem(bob), bob, bob);

    assertEq(vault.balanceOf(bob), 0);
    assertEq(underlyingAsset.balanceOf(bob), _amount);

    assertEq(twabController.balanceOf(address(vault), bob), 0);
    assertEq(twabController.delegateBalanceOf(address(vault), bob), 0);

    assertEq(yieldVault.balanceOf(address(vault)), 0);
    assertEq(underlyingAsset.balanceOf(address(yieldVault)), 0);

    vm.stopPrank();
  }
}
