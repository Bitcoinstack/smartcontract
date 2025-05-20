// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title BitcoinStack Stake & Yield Protocol
/// @author
/// @notice Allows users to stake BTC via Layer 2 bridges and earn yield.
/// @dev Designed for Rootstock (RSK) compatible chains.

interface ILayerBridge {
    function lockBTC(address user, uint256 amount) external;
    function releaseBTC(address user, uint256 amount) external;
}

contract BitcoinStakeYieldProtocol {
    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
        uint256 yieldAccrued;
    }

    address public admin;
    uint256 public yieldRatePerSecond; // Yield rate in wei per second
    ILayerBridge public lightningBridge;
    ILayerBridge public rootstockBridge;
    ILayerBridge public liquidBridge;

    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 amount, string layer);
    event Unstaked(address indexed user, uint256 amount, uint256 yieldEarned, string layer);
    event YieldClaimed(address indexed user, uint256 yieldAmount);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(
        address _lightningBridge,
        address _rootstockBridge,
        address _liquidBridge,
        uint256 _yieldRate
    ) {
        admin = msg.sender;
        lightningBridge = ILayerBridge(_lightningBridge);
        rootstockBridge = ILayerBridge(_rootstockBridge);
        liquidBridge = ILayerBridge(_liquidBridge);
        yieldRatePerSecond = _yieldRate;
    }

    function stake(string memory layer, uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        StakeInfo storage userStake = stakes[msg.sender];

        _routeToLayerBridge(layer).lockBTC(msg.sender, amount);

        _updateYield(msg.sender);

        userStake.amount += amount;
        userStake.timestamp = block.timestamp;

        emit Staked(msg.sender, amount, layer);
    }

    function unstake(string memory layer, uint256 amount) external {
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.amount >= amount, "Insufficient staked");

        _updateYield(msg.sender);

        userStake.amount -= amount;
        _routeToLayerBridge(layer).releaseBTC(msg.sender, amount);

        emit Unstaked(msg.sender, amount, userStake.yieldAccrued, layer);
    }

    function claimYield() external {
        _updateYield(msg.sender);

        uint256 yieldToClaim = stakes[msg.sender].yieldAccrued;
        require(yieldToClaim > 0, "No yield to claim");

        stakes[msg.sender].yieldAccrued = 0;

        // Mock transfer of yield - to be replaced by actual yield disbursement mechanism
        payable(msg.sender).transfer(yieldToClaim);

        emit YieldClaimed(msg.sender, yieldToClaim);
    }

    function _routeToLayerBridge(string memory layer) internal view returns (ILayerBridge) {
        if (keccak256(abi.encodePacked(layer)) == keccak256("lightning")) {
            return lightningBridge;
        } else if (keccak256(abi.encodePacked(layer)) == keccak256("rootstock")) {
            return rootstockBridge;
        } else if (keccak256(abi.encodePacked(layer)) == keccak256("liquid")) {
            return liquidBridge;
        } else {
            revert("Unknown Layer");
        }
    }

    function _updateYield(address user) internal {
        StakeInfo storage userStake = stakes[user];
        if (userStake.amount > 0) {
            uint256 timeElapsed = block.timestamp - userStake.timestamp;
            uint256 yieldEarned = userStake.amount * yieldRatePerSecond * timeElapsed / 1e18;
            userStake.yieldAccrued += yieldEarned;
            userStake.timestamp = block.timestamp;
        }
    }

    receive() external payable {}
}
