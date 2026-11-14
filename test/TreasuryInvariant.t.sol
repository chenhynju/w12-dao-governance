// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {Treasury} from "../src/Treasury.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TreasuryHandler is Test {
    Treasury public treasury;
    address public immutable recipient = address(0xBEEF);
    uint256 public deposits;
    uint256 public payments;
    bool public expectedPaused;

    constructor() {
        treasury = Treasury(
            payable(address(
                    new ERC1967Proxy(
                        address(new Treasury()), abi.encodeCall(Treasury.initialize, (address(this), address(this)))
                    )
                ))
        );
    }

    function deposit(uint256 amount) external {
        amount = bound(amount, 0, 10 ether);
        vm.deal(address(this), amount);
        (bool ok,) = address(treasury).call{value: amount}("");
        assertTrue(ok);
        deposits += amount;
    }

    function pay(uint256 amount) external {
        amount = bound(amount, 0, deposits - payments);
        if (expectedPaused) {
            vm.expectRevert(Treasury.SpendingPaused.selector);
            treasury.pay(payable(recipient), amount);
            return;
        }
        treasury.pay(payable(recipient), amount);
        payments += amount;
    }

    function setPaused(bool paused) external {
        if (paused) treasury.pause();
        else treasury.unpause();
        expectedPaused = paused;
    }
}

contract TreasuryInvariantTest is Test {
    TreasuryHandler handler;

    function setUp() public {
        handler = new TreasuryHandler();
        targetContract(address(handler));
    }

    function invariant_AccountingAndPauseAgreeWithModel() public view {
        Treasury treasury = handler.treasury();
        assertEq(handler.deposits(), address(treasury).balance + handler.payments());
        assertEq(handler.recipient().balance, handler.payments());
        assertEq(treasury.paused(), handler.expectedPaused());
    }
}
