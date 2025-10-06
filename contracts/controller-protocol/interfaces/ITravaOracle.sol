// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title ITravaOracle
 * @notice Interface for the Trava oracle that uses Pyth Network price feeds
 */
interface ITravaOracle {
    event PriceOracleUpdated(address oldAddress, address newAddress);
    event PriceFeedSet(address token, bytes32 priceFeedId);
    event MaxPriceStalnessUpdated(uint256 oldValue, uint256 newValue);

    function setPriceFeed(address token, bytes32 priceFeedId) external;
    function setMultiplePriceFeeds(address[] calldata tokens, bytes32[] calldata feedIds) external;
    function setMaxPriceStaleness(uint256 newMaxPriceStaleness) external;
    function updatePythOracle(address newPythAddress) external;
    function updatePriceFeeds(bytes[] calldata priceUpdates) external payable;
    function getAssetPrice(address asset) external view returns (uint256);
    function getAssetPrices(address[] calldata assets) external view returns (uint256[] memory prices);
    function getFeedId(address asset) external view returns (bytes32);
    function getFeedIds(address[] calldata assets) external view returns (bytes32[] memory feedIds);
    function emergencyWithdraw(address to) external;
}