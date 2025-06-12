// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Donation.sol";

contract DonationTest is Test {
    Donation public donation;

    address owner = address(0x1);
    address donor = address(0x2);
    address recipient = payable(address(0x3));

    function setUp() public {
        vm.prank(owner);
        donation = new Donation();
    }

    /// @notice Test that the contract owner can add a new donation case.
    function testAddCase() public {
        vm.prank(owner);
        donation.addCase("Case 1", "Help needed", payable(recipient));
        (string memory title,,,) = donation.getCase(0);
        assertEq(title, "Case 1");
    }

    /// @notice Test that a user can donate to an existing case with a valid amount.
    function testDonate() public {
        vm.prank(owner);
        donation.addCase("Case 1", "Help needed", payable(recipient));

        vm.prank(donor);
        vm.deal(donor, 1 ether);
        donation.donate{value: 0.1 ether}(0);

        (, , , uint256 total) = donation.getCase(0);
        assertEq(total, 0.1 ether);
    }

    /// @notice Test that donating less than 0.01 ETH reverts the transaction.
    function testDonateBelowMinimumReverts() public {
        vm.prank(owner);
        donation.addCase("Case 1", "Help needed", payable(recipient));

        vm.prank(donor);
        vm.deal(donor, 1 ether);
        vm.expectRevert("Min 0.01 ETH");
        donation.donate{value: 0.005 ether}(0);
    }

    /// @notice Test that the recipient can withdraw donated funds successfully.
    function testWithdraw() public {
        vm.prank(owner);
        donation.addCase("Case 1", "Help needed", payable(recipient));

        vm.prank(donor);
        vm.deal(donor, 1 ether);
        donation.donate{value: 0.2 ether}(0);

        vm.prank(recipient);
        vm.expectEmit(true, true, false, true);
        emit Donation.Withdrawal(0, recipient, 0.2 ether);
        donation.withdraw(0);
    }

    /// @notice Test that someone other than the recipient cannot withdraw funds.
    function testNonRecipientCannotWithdraw() public {
        vm.prank(owner);
        donation.addCase("Case 1", "Help needed", payable(recipient));

        vm.prank(donor);
        vm.deal(donor, 1 ether);
        donation.donate{value: 0.05 ether}(0);

        address attacker = address(0x4);
        vm.prank(attacker);
        vm.expectRevert("Not recipient");
        donation.withdraw(0);
    }
}
