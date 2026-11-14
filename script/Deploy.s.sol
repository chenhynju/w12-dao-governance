// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Script} from "forge-std/Script.sol";
import {DaoGovernor, DaoVotes, TimelockController} from "../src/Dao.sol";
import {Treasury} from "../src/Treasury.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract Deploy is Script {
    function run() external returns (DaoVotes votes, DaoGovernor governor, TimelockController lock, Treasury treasury) {
        address admin = vm.envAddress("BOOTSTRAP_ADMIN");
        address distributor = vm.envAddress("VOTE_DISTRIBUTOR");
        address guardian = vm.envAddress("PAUSE_GUARDIAN");
        require(admin != address(0) && distributor != address(0) && guardian != address(0), "missing role");
        vm.startBroadcast(admin);
        address[] memory empty = new address[](0);
        lock = new TimelockController(2 days, empty, empty, admin);
        votes = new DaoVotes(distributor);
        governor = new DaoGovernor(votes, lock);
        lock.grantRole(lock.PROPOSER_ROLE(), address(governor));
        lock.grantRole(lock.CANCELLER_ROLE(), address(governor));
        lock.grantRole(lock.EXECUTOR_ROLE(), address(governor));
        treasury = Treasury(
            payable(address(
                    new ERC1967Proxy(
                        address(new Treasury()), abi.encodeCall(Treasury.initialize, (address(lock), guardian))
                    )
                ))
        );
        lock.renounceRole(lock.DEFAULT_ADMIN_ROLE(), admin);
        vm.stopBroadcast();
    }
}
