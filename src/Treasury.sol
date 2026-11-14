// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/// @notice Timelocked ETH treasury with a pause-only guardian.
contract Treasury is Initializable, UUPSUpgradeable {
    error Unauthorized();
    error InvalidAddress();
    error SpendingPaused();
    error PaymentFailed();

    event GuardianChanged(address indexed guardian);
    event SpendingStatusChanged(bool paused);
    event Payment(address indexed recipient, uint256 amount);

    address public timelock;
    address public guardian;
    bool public paused;

    constructor() {
        _disableInitializers();
    }

    modifier onlyTimelock() {
        if (msg.sender != timelock) revert Unauthorized();
        _;
    }

    function initialize(address timelock_, address guardian_) external initializer {
        if (timelock_ == address(0) || guardian_ == address(0)) revert InvalidAddress();
        timelock = timelock_;
        guardian = guardian_;
        emit GuardianChanged(guardian_);
    }

    receive() external payable {}

    function pause() external {
        if (msg.sender != guardian) revert Unauthorized();
        paused = true;
        emit SpendingStatusChanged(true);
    }

    function unpause() external onlyTimelock {
        paused = false;
        emit SpendingStatusChanged(false);
    }

    function setGuardian(address nextGuardian) external onlyTimelock {
        if (nextGuardian == address(0)) revert InvalidAddress();
        guardian = nextGuardian;
        emit GuardianChanged(nextGuardian);
    }

    function pay(address payable recipient, uint256 amount) external onlyTimelock {
        if (paused) revert SpendingPaused();
        if (recipient == address(0) || recipient == address(this)) revert InvalidAddress();
        (bool ok,) = recipient.call{value: amount}("");
        if (!ok) revert PaymentFailed();
        emit Payment(recipient, amount);
    }

    function _authorizeUpgrade(address) internal override onlyTimelock {}
}
