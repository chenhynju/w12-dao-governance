// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts/utils/Nonces.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorCountingSimple} from "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import {GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {
    GovernorVotesQuorumFraction
} from "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {GovernorTimelockControl} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";

/// @notice Fixed supply voting power with delegation and historical checkpoints.
contract DaoVotes is ERC20, ERC20Permit, ERC20Votes {
    constructor(address distributor) ERC20("DAO Governance", "DAOG") ERC20Permit("DAO Governance") {
        _mint(distributor, 1_000_000 ether);
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(address owner) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}

/// @notice Routes successful proposals through a dedicated timelock.
contract DaoGovernor is GovernorCountingSimple, GovernorVotesQuorumFraction, GovernorTimelockControl {
    constructor(IVotes votes, TimelockController timelock)
        Governor("Portfolio DAO")
        GovernorVotes(votes)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(timelock)
    {}

    function votingDelay() public pure override returns (uint256) {
        return 7200;
    }

    function votingPeriod() public pure override returns (uint256) {
        return 36000;
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 10_000 ether;
    }

    function state(uint256 id) public view override(Governor, GovernorTimelockControl) returns (ProposalState) {
        return super.state(id);
    }

    function proposalNeedsQueuing(uint256 id) public view override(Governor, GovernorTimelockControl) returns (bool) {
        return super.proposalNeedsQueuing(id);
    }

    function _queueOperations(
        uint256 id,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory data,
        bytes32 description
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return super._queueOperations(id, targets, values, data, description);
    }

    function _executeOperations(
        uint256 id,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory data,
        bytes32 description
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(id, targets, values, data, description);
    }

    function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory data, bytes32 description)
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    {
        return super._cancel(targets, values, data, description);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }
}
