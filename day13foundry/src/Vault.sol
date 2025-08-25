// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title Simple ETH Vault with Pause & Reentrancy Guard
/// @notice Users can deposit/withdraw ETH; owner can pause in emergencies.
contract Vault {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Paused(address indexed owner);
    event Unpaused(address indexed owner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                               STORAGE
    //////////////////////////////////////////////////////////////*/
    address public owner;
    bool public paused;

    // Simple, local reentrancy guard (no OZ dependency)
    uint256 private locked; // 0 = unlocked, 1 = locked

    mapping(address => uint256) public balanceOf;

    /*//////////////////////////////////////////////////////////////
                             MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyOwner() {
        require(msg.sender == owner, "NotOwner");
        _;
    }

    modifier notPaused() {
        require(!paused, "Paused");
        _;
    }

    modifier nonReentrant() {
        require(locked == 0, "Reentrancy");
        locked = 1;
        _;
        locked = 0;
    }

    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(address _owner) {
        require(_owner != address(0), "ZeroOwner");
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                         OWNER EMERGENCY CONTROLS
    //////////////////////////////////////////////////////////////*/
    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZeroOwner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /*//////////////////////////////////////////////////////////////
                         USER DEPOSIT/WITHDRAW
    //////////////////////////////////////////////////////////////*/
    /// @notice Deposit ETH to your balance.
    function deposit() external payable notPaused {
        require(msg.value > 0, "ZeroAmount");
        balanceOf[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /// @notice Withdraw a specific amount of your deposited ETH.
    function withdraw(uint256 amount) external notPaused nonReentrant {
        require(amount > 0, "ZeroAmount");
        uint256 bal = balanceOf[msg.sender];
        require(bal >= amount, "Insufficient");

        // Effects
        unchecked {
            balanceOf[msg.sender] = bal - amount;
        }

        // Interaction (after effects) + reentrancy guard is active
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "ETHTransferFailed");

        emit Withdrawn(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            RECEIVE / FALLBACK
    //////////////////////////////////////////////////////////////*/
    receive() external payable {
        // Allow direct sends to count as deposit (if not paused).
        require(!paused, "Paused");
        require(msg.value > 0, "ZeroAmount");
        balanceOf[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
}
