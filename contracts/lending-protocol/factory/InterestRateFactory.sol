// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";
import {ReserveInterestRateStrategy} from "../pool/ReserveInterestRateStrategy.sol";

/**
 * @title InterestRateFactory contract
 * @dev Contract for manage interestRateStrategy in Trava
 * - Owned by the Trava
 * @author Trava
 **/
contract InterestRateFactory {
    
    address[] private interestRateStrategies;

    struct TokenInfor {
        uint256 utilizationOptimal;
        uint256 BaseInterstRate;
        uint256 slope1;
        uint256 slope2;
    }

    /**
     * @dev init InterestrateStrategy for new pool
     * @param providerAddress The address to addressesProviderFactory
     * @param tokenInput Information of corresponding reserves
     */
    function initInterestRateStrategy(
        address providerAddress,
        TokenInfor[] calldata tokenInput
    ) external returns (address[] memory) {
        IAddressesProvider addressesProvider = IAddressesProvider(providerAddress);

        require(
            msg.sender == addressesProvider.getPoolOwner(),
            "Caller not pool owner"
        );

        for (uint256 i = 0; i < tokenInput.length; i++) {
            ReserveInterestRateStrategy _reserveInterestRateStrategy =
                new ReserveInterestRateStrategy(
                    addressesProvider,
                    tokenInput[i].utilizationOptimal,
                    tokenInput[i].BaseInterstRate,
                    tokenInput[i].slope1,
                    tokenInput[i].slope2
                );

            interestRateStrategies.push(address(_reserveInterestRateStrategy));
        }
        return interestRateStrategies;
    }

    /**
     * @dev Returns list of InterestRate of corresponding pool
     * @return interestRateStrategies
     */
    function getListInterestRateAddress() external view returns (address[] memory) {
        return interestRateStrategies;
    }
}