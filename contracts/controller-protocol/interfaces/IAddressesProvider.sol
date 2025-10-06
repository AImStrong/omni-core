// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.26;

/**
 * @title IAddressesProvider interface
 * @dev Main registry of addresses part of or connected to the cross-chain protocol
 * @author Trava
 **/
interface IAddressesProvider {
    event AddressSet(uint256 indexed chainId, bytes32 indexed id, address indexed newAddress, bool hasProxy);
    event GovernanceUpdated(address indexed newAddress);
    event CrossChainControllerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event ControllerConfiguratorUpdated(address indexed newAddress);
    event ControllerUpdateManagerUpdated(address indexed newAddress);
    event ControllerOwnerUpdated(address indexed newOwner);
    event ProxyCreated(bytes32 indexed id, address indexed newAddress);
    event ConnectedMessengerUpdated(uint256 indexed chainId, address indexed messengerAddr);
    event ControllerConfigured(address indexed controller);
    event ControllerUpdated(address indexed controller);
    event UniversalMessengerUpdated(address indexed newAddress);

    function setGovernance(address newGovernance) external;
    function getGovernance() external view returns(address);

    function checkOwner(address owner) external view returns (bool);
    function getControllerOwner() external view returns (address);
    function setControllerOwner(address owner) external;

    function setCrossChainLendingControllerImpl(address implementation) external;
    function getCrossChainLendingController() external view returns (address);
    
    function getControllerConfigurator() external view returns (address);
    function setControllerConfiguratorImpl(address configurator) external;

    function getControllerUpdateManager() external view returns (address);
    function setControllerUpdateManager(address manager) external;

    function getPriceOracle() external view returns (address);
    function setPriceOracle(address oracle) external;

    function setConnectedMessengersForChains(
        uint256[] calldata chainIds,
        address[] calldata messengerAddrs
    ) external;
    function getConnectedMessengerForChain(uint256 chainId) external view returns (address);

    function getSupportedChainIds() external view returns (uint256[] memory);

    function setUniversalMessenger(address newMessenger) external;
    function getUniversalMessenger() external view returns (address);

    function setAddress(
        uint256 chainId,
        bytes32 id,
        address addr
    ) external;
    function getAddress(
        uint256 chainId,
        bytes32 id
    ) external view returns (address);

    function initController(
        address controller,
        address priceOracle,
        address controllerConfigurator
    ) external;
}