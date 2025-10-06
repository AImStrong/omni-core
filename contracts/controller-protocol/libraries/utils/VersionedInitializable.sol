// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * @title VersionedInitializable
 * @dev Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 */
abstract contract VersionedInitializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    uint256 private lastInitializedRevision = 0;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();
        require(revision > lastInitializedRevision, "Contract instance has already been initialized");

        lastInitializedRevision = revision;

        _;
    }

    /**
     * @dev Returns the revision number of the contract.
     * Needs to be defined in the inherited class.
     */
    function getRevision() internal pure virtual returns (uint256);

    /**
     * @dev Returns true if and only if the function is running in the constructor
     */
    function isConstructor() private view returns (bool) {
        uint256 cs;
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    /**
     * @dev Returns the last initialized revision
     */
    function getLastInitializedRevision() public view returns (uint256) {
        return lastInitializedRevision;
    }
} 