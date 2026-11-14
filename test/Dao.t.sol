// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {IGovernor} from "@openzeppelin/contracts/governance/IGovernor.sol";
import {DaoVotes, DaoGovernor, TimelockController} from "../src/Dao.sol";
import {Treasury} from "../src/Treasury.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TreasuryV2 is Treasury {
    function version() external pure returns (uint256) {
        return 2;
    }
}

contract DaoTest is Test {
    DaoVotes token;
    DaoGovernor governor;
    TimelockController lock;
    Treasury treasury;
    address guardian = makeAddr("guardian");
    address recipient = makeAddr("recipient");

    function setUp() public {
        address[] memory empty = new address[](0);
        lock = new TimelockController(2 days, empty, empty, address(this));
        token = new DaoVotes(address(this));
        governor = new DaoGovernor(token, lock);
        lock.grantRole(lock.PROPOSER_ROLE(), address(governor));
        lock.grantRole(lock.CANCELLER_ROLE(), address(governor));
        lock.grantRole(lock.EXECUTOR_ROLE(), address(governor));
        lock.renounceRole(lock.DEFAULT_ADMIN_ROLE(), address(this));
        treasury = Treasury(
            payable(address(
                    new ERC1967Proxy(
                        address(new Treasury()), abi.encodeCall(Treasury.initialize, (address(lock), guardian))
                    )
                ))
        );
        token.delegate(address(this));
        vm.roll(block.number + 1);
        vm.deal(address(treasury), 10 ether);
    }

    function testFuzz_TreasuryProposalConservesEth(uint256 amount) public {
        amount = bound(amount, 1, 10 ether);
        _pass(abi.encodeCall(Treasury.pay, (payable(recipient), amount)), "Fund grant");
        assertEq(recipient.balance, amount);
        assertEq(address(treasury).balance, 10 ether - amount);
    }

    function testGuardianPauseAndGovernanceRecovery() public {
        vm.prank(guardian);
        treasury.pause();
        assertTrue(treasury.paused());
        vm.prank(guardian);
        vm.expectRevert(Treasury.Unauthorized.selector);
        treasury.unpause();
        _pass(abi.encodeCall(Treasury.unpause, ()), "Restore spending");
        assertFalse(treasury.paused());
    }

    function testUpgradePreservesStorageAndBalance() public {
        vm.prank(guardian);
        treasury.pause();
        TreasuryV2 next = new TreasuryV2();
        vm.expectRevert(Treasury.Unauthorized.selector);
        treasury.upgradeToAndCall(address(next), "");
        _pass(abi.encodeCall(treasury.upgradeToAndCall, (address(next), "")), "Upgrade treasury");
        assertEq(TreasuryV2(payable(address(treasury))).version(), 2);
        assertEq(treasury.timelock(), address(lock));
        assertEq(treasury.guardian(), guardian);
        assertTrue(treasury.paused());
        assertEq(address(treasury).balance, 10 ether);
    }

    function testBootstrapAdminRemovedAndDirectPaymentDenied() public {
        assertFalse(lock.hasRole(lock.DEFAULT_ADMIN_ROLE(), address(this)));
        assertTrue(lock.hasRole(lock.DEFAULT_ADMIN_ROLE(), address(lock)));
        vm.expectRevert(Treasury.Unauthorized.selector);
        treasury.pay(payable(recipient), 1 ether);
        vm.expectRevert();
        treasury.initialize(address(this), guardian);
    }

    function testPauseBlocksEvenTimelockPayment() public {
        vm.prank(guardian);
        treasury.pause();
        vm.prank(address(lock));
        vm.expectRevert(Treasury.SpendingPaused.selector);
        treasury.pay(payable(recipient), 1 ether);
        assertEq(address(treasury).balance, 10 ether);
    }

    function testOutsiderCannotScheduleOrPause() public {
        vm.prank(recipient);
        vm.expectRevert();
        lock.schedule(address(treasury), 0, abi.encodeCall(Treasury.unpause, ()), bytes32(0), bytes32(0), 2 days);
        vm.prank(recipient);
        vm.expectRevert(Treasury.Unauthorized.selector);
        treasury.pause();
    }

    function testHistoricalVotingPowerSurvivesTransfer() public {
        uint256 snapshot = block.number - 1;
        token.transfer(recipient, 500_000 ether);
        vm.prank(recipient);
        token.delegate(recipient);
        assertEq(token.getPastVotes(address(this), snapshot), 1_000_000 ether);
        assertEq(token.getPastVotes(recipient, snapshot), 0);
    }

    function _pass(bytes memory action, string memory description) internal {
        address[] memory targets = new address[](1);
        uint256[] memory values = new uint256[](1);
        bytes[] memory data = new bytes[](1);
        targets[0] = address(treasury);
        data[0] = action;
        bytes32 hash = keccak256(bytes(description));

        uint256 id = governor.propose(targets, values, data, description);
        vm.roll(governor.proposalSnapshot(id) + 1);
        governor.castVote(id, 1);
        vm.roll(governor.proposalDeadline(id) + 1);
        governor.queue(targets, values, data, hash);
        vm.expectRevert();
        governor.execute(targets, values, data, hash);
        vm.warp(governor.proposalEta(id));
        governor.execute(targets, values, data, hash);
        assertEq(uint256(governor.state(id)), uint256(IGovernor.ProposalState.Executed));
        vm.expectRevert();
        governor.execute(targets, values, data, hash);
    }
}
