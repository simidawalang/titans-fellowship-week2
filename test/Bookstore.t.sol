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
        bookstore.addBook("Snow White", true);
        // The number of books and highest book index should now be 2
        assertEq(bookstore.noOfBooks(), 2);
    }

    function testFail_AddBook() external {
        vm.prank(user);

        bookstore.addBook("Sinbad", false);
        assertEq(bookstore.noOfBooks(), 2);
        // should normally fail since the person
        // attempting to add a book is not the owner
    }

    function testSubscription() external {
        vm.expectRevert("You are the bookshop owner.");
        bookstore.subscribe{value: subFee}();

        vm.startPrank(user);
        assertFalse(bookstore.hasSubscribed(user)); // Not yet subscribed

        deal(user, 100); // Put 100 wei in the user's account

        vm.expectRevert("Incorrect subscription fee.");
        bookstore.subscribe{value: 45}();

        bookstore.subscribe{value: subFee}();
        assertTrue(bookstore.hasSubscribed(user)); // User is now a subscriber

        // Revert if a subscriber wants to subscribe twice
        vm.expectRevert("This account has already subscribed.");
        bookstore.subscribe{value: subFee}();

        vm.stopPrank();
    }
}
