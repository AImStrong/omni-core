// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.26;

// OpenZeppelin dependencies
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Interfaces
import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";

interface IMockPyth {
    struct Price {
        int64 price;
        uint64 conf;
        int32 expo;
        uint256 publishTime;
    }
    function getPrice(bytes32 id) external view returns (Price memory);
}

contract MockOracle is IPriceOracleGetter {
    // address public pythContract;
    // address public owner;
    // mapping(address => bytes32) private feedIds;
    // address[] private feedKeys;
    
    // event FeedIDSet(address indexed asset, bytes32 feedId);
    // event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // modifier onlyOwner() {
    //     require(msg.sender == owner, "Caller is not the owner");
    //     _;
    // }

    // constructor(address _pythContract) {
    //     require(_pythContract != address(0), "Invalid contract address");
    //     pythContract = _pythContract;
    //     owner = msg.sender;
    // }

    // function transferOwnership(address newOwner) external onlyOwner {
    //     require(newOwner != address(0), "New owner is the zero address");
    //     emit OwnershipTransferred(owner, newOwner);
    //     owner = newOwner;
    // }

    // function getPrice(address asset) external view returns (uint256) {
    //     require(feedIds[asset] != bytes32(0), "Feed ID not set");
    //     IMockPyth.Price memory priceData = IMockPyth(pythContract).getPrice(feedIds[asset]);
    //     int256 result = int256(priceData.price) * int256(10 ** uint256(abs(priceData.expo)));
    //     require(result >= 0, "Value must be non-negative");
    //     return SafeCast.toUint256(result);
    // }


    function getAssetPrice(address) external pure returns (uint256) {
        return 1 ether;
    }

    // function abs(int32 x) private pure returns (uint32) {
    //     return x >= 0 ? uint32(x) : uint32(-x);
    // }

    // function setFeedID(address asset, bytes32 feedId) public onlyOwner {
    //     require(feedId != bytes32(0), "Invalid feed ID");
    //     if (feedIds[asset] == bytes32(0)) {
    //         feedKeys.push(asset);
    //     }
    //     feedIds[asset] = feedId;
    //     emit FeedIDSet(asset, feedId);
    // }

    // function getFeedId(address asset) external view returns (bytes32) {
    //     return feedIds[asset];
    // }

    // function getAllFeedIds() external view returns (address[] memory, bytes32[] memory) {
    //     bytes32[] memory ids = new bytes32[](feedKeys.length);
    //     for (uint256 i = 0; i < feedKeys.length; i++) {
    //         ids[i] = feedIds[feedKeys[i]];
    //     }
    //     return (feedKeys, ids);
    // }

    // function initFeedIds(address[] calldata assets, bytes32[] calldata ids) external onlyOwner {
    //     require(assets.length == ids.length, "Mismatched input lengths");
    //     for (uint256 i = 0; i < assets.length; i++) {
    //         setFeedID(assets[i], ids[i]);
    //     }
    // }
}