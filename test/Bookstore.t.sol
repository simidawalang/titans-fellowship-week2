// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import {Test} from "forge-std/Test.sol";
import "forge-std/Vm.sol";
import {Bookstore} from "../src/Bookstore.sol";

contract BookstoreTest is Test {
    Bookstore public bookstore;
    uint subFee = 30;
    address user = address(0x123);

    

    function setUp() public {
        bookstore = new Bookstore(subFee);

        bookstore.addBook("The Wizard of Oz", true);
  
    }

    function testAddBook() external {
       
        // The number of books and highest book index should now be 2
        string memory title = "Snow White";
        bool premium = true;

        vm.expectEmit(); // since only the id is indexed
        emit Bookstore.BookAdded(2, title, premium);
        bookstore.addBook("Snow White", true);
        assertEq(bookstore.noOfBooks(), 2);

        vm.prank(user);
        vm.expectRevert(); // Since subscribers should not be able to add books themselves
        bookstore.addBook("Oceans 8", true);
    }

    function testSubscription() external {
        vm.expectRevert("You are the bookshop owner.");
        bookstore.subscribe{value: subFee}();

        vm.startPrank(user);
        assertFalse(bookstore.hasSubscribed(user)); // Not yet subscribed

        deal(user, 100); // Put 100 wei in the user's account

        vm.expectRevert("Incorrect subscription fee.");
        bookstore.subscribe{value: 45}();

        vm.expectEmit();
        emit Bookstore.SubscriptionPurchase(user);
        bookstore.subscribe{value: subFee}();
        assertTrue(bookstore.hasSubscribed(user)); // User is now a subscriber

        // Revert if a subscriber wants to subscribe twice
        vm.expectRevert("This account has already subscribed.");
        bookstore.subscribe{value: subFee}();

        vm.stopPrank();
    }

    function testAccessBook() external {
        // There is already a premium book created in the setUp function
        // Bookstore owner can access books without subscription
        assert(bookstore.accessBook(1));

        // Prank as user
        vm.startPrank(user);
        assertFalse(bookstore.accessBook(1));

        deal(user, 100);
        bookstore.subscribe{value: subFee}();

        assert(bookstore.accessBook(1));
        vm.stopPrank();
    }

    function testWithdrawal() external {
        uint initialBalance = address(bookstore.bookstoreOwner()).balance;

        deal(address(bookstore), 1 ether);
        bookstore.withdraw();
        assertEq(
            address(bookstore.bookstoreOwner()).balance,
            initialBalance + 1 ether
        );
        assertEq(address(bookstore).balance, 0);

        // Withdraw as non-owner
        vm.prank(user);

        deal(address(bookstore), 1 ether);
        vm.expectRevert();
        bookstore.withdraw();

        assertEq(address(bookstore).balance, 1 ether);
    }

    receive() external payable {}
}
