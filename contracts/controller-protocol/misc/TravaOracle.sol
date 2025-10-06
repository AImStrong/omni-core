// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "../interfaces/ITravaOracle.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TravaOracle
 * @notice Oracle contract for Trava protocol that uses Pyth Network price feeds
 */
contract TravaOracle is ITravaOracle, Ownable {
    // Pyth interface
    IPyth public pyth;
    
    // Mapping from token address to Pyth price feed ID
    mapping(address => bytes32) public priceFeedIds;
    
    // Max price staleness in seconds
    uint256 public maxPriceStaleness;
    
    /**
     * @param pythContract The address of the Pyth contract
     */
    constructor(address pythContract, uint256 _maxPriceStaleness) Ownable(msg.sender) {
        require(pythContract != address(0), "Invalid Pyth address");
        pyth = IPyth(pythContract);
        maxPriceStaleness = _maxPriceStaleness;
    }
    
    /**
     * @notice Sets a price feed ID for a token
     * @param token The token address
     * @param priceFeedId The Pyth price feed ID for the token
     */
    function setPriceFeed(address token, bytes32 priceFeedId) external onlyOwner {
        require(token != address(0), "Invalid token address");
        priceFeedIds[token] = priceFeedId;
        emit PriceFeedSet(token, priceFeedId);
    }
    
    /**
     * @notice Sets multiple price feeds at once
     * @param tokens Array of token addresses
     * @param feedIds Array of corresponding Pyth price feed IDs
     */
    function setMultiplePriceFeeds(address[] calldata tokens, bytes32[] calldata feedIds) external onlyOwner {
        require(tokens.length == feedIds.length, "Array length mismatch");
        for (uint i = 0; i < tokens.length; i++) {
            require(tokens[i] != address(0), "Invalid token address");
            priceFeedIds[tokens[i]] = feedIds[i];
            emit PriceFeedSet(tokens[i], feedIds[i]);
        }
    }
    
    /**
     * @notice Sets the max price staleness in seconds
     * @param newMaxPriceStaleness Max staleness in seconds
     */
    function setMaxPriceStaleness(uint256 newMaxPriceStaleness) external onlyOwner {
        require(newMaxPriceStaleness > 0, "Invalid staleness value");
        uint256 oldValue = maxPriceStaleness;
        maxPriceStaleness = newMaxPriceStaleness;
        emit MaxPriceStalnessUpdated(oldValue, newMaxPriceStaleness);
    }
    
    /**
     * @notice Updates the Pyth oracle address
     * @param newPythAddress New Pyth oracle address
     */
    function updatePythOracle(address newPythAddress) external onlyOwner {
        require(newPythAddress != address(0), "Invalid Pyth address");
        address oldAddress = address(pyth);
        pyth = IPyth(newPythAddress);
        emit PriceOracleUpdated(oldAddress, newPythAddress);
    }
    
    /**
     * @notice Updates price feeds with the latest data from Pyth
     * @param priceUpdates The encoded price update data from Pyth
     */
    function updatePriceFeeds(bytes[] calldata priceUpdates) external payable {
        uint fee = pyth.getUpdateFee(priceUpdates);
        require(msg.value >= fee, "Insufficient fee for price update");
        
        pyth.updatePriceFeeds{value: fee}(priceUpdates);
        
        // Return any excess ETH
        if (msg.value > fee) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - fee}("");
            require(success, "ETH refund failed");
        }
    }
    
    /**
     * @notice Gets the price of a token in USD 
     * @param asset The address of the token
     * @return The price in USD with 18 decimals
     */
    function getAssetPrice(address asset) external view override returns (uint256) {
        bytes32 priceFeedId = priceFeedIds[asset];
        require(priceFeedId != bytes32(0), "Price feed not configured");
        
        try pyth.getPriceNoOlderThan(priceFeedId, maxPriceStaleness) returns (PythStructs.Price memory price) {
          
            require(price.price >= 0, "Negative price");
            return uint256(int256(price.price));
        } catch {
            revert("Failed to get fresh price");
        }
    }

    /**
     * @notice Gets the prices of multiple tokens in USD 
     * @param assets Array of token addresses
     * @return prices Array of prices in USD 
     */
    function getAssetPrices(address[] calldata assets) external view returns (uint256[] memory prices) {
        prices = new uint256[](assets.length);
        
        for (uint i = 0; i < assets.length; i++) {
            bytes32 priceFeedId = priceFeedIds[assets[i]];
            require(priceFeedId != bytes32(0), "Price feed not configured");

            try pyth.getPriceNoOlderThan(priceFeedId, maxPriceStaleness) returns (PythStructs.Price memory price) {
                require(price.price >= 0, "Negative price");
                prices[i] = uint256(int256(price.price));
            } catch {
                revert("Failed to get fresh price");
            }
        }
        return prices;
    }
    
    /**
     * @notice Gets the feed ID for a token
     * @param asset The token address
     * @return The Pyth price feed ID
     */
    function getFeedId(address asset) external view returns (bytes32) {
        return priceFeedIds[asset];
    }
    
    /**
     * @notice Gets all configured feed IDs
     * @param assets Array of token addresses to get feed IDs for
     * @return feedIds Array of corresponding Pyth price feed IDs
     */
    function getFeedIds(address[] calldata assets) external view returns (bytes32[] memory feedIds) {
        feedIds = new bytes32[](assets.length);
        for (uint i = 0; i < assets.length; i++) {
            feedIds[i] = priceFeedIds[assets[i]];
        }
        return feedIds;
    }
    
    /**
     * @notice Emergency function to withdraw stuck ETH
     * @param to Address to send the ETH to
     */
    function emergencyWithdraw(address to) external onlyOwner {
        require(to != address(0), "Invalid address");
        (bool success, ) = payable(to).call{value: address(this).balance}("");
        require(success, "ETH transfer failed");
    }
}