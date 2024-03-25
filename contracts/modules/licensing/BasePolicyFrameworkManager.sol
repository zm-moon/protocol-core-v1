// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

// external
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// contracts
import { IPolicyFrameworkManager } from "../../interfaces/modules/licensing/IPolicyFrameworkManager.sol";
import { ILicensingModule } from "../../interfaces/modules/licensing/ILicensingModule.sol";
import { Errors } from "../../lib/Errors.sol";

/// @title BasePolicyFrameworkManager
/// TODO: If we want to open this, we need an upgradeable and non-upgradeable Base version, or just promote
/// the IPolicyFrameworkManager in the docs.
/// @notice Base contract for policy framework managers.
abstract contract BasePolicyFrameworkManager is IPolicyFrameworkManager, ERC165, Initializable {
    /// @dev Storage for BasePolicyFrameworkManager
    /// @param name The name of the policy framework manager
    /// @param licenseTextUrl The URL to the off chain legal agreement template text
    /// @custom:storage-location erc7201:story-protocol.BasePolicyFrameworkManager
    struct BasePolicyFrameworkManagerStorage {
        string name;
        string licenseTextUrl;
    }

    // keccak256(abi.encode(uint256(keccak256("story-protocol.BasePolicyFrameworkManager")) - 1))
    // & ~bytes32(uint256(0xff));
    bytes32 private constant BasePolicyFrameworkManagerStorageLocation =
        0xa55803740ac9329334ad7b6cde0ec056cc3ba32125b59c579552512bed001f00;

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ILicensingModule public immutable LICENSING_MODULE;

    /// @notice Modifier for authorizing the calling entity to only the LicensingModule.
    modifier onlyLicensingModule() {
        if (msg.sender != address(LICENSING_MODULE)) {
            revert Errors.BasePolicyFrameworkManager__CallerNotLicensingModule();
        }
        _;
    }

    /// @notice Constructor function
    /// @param licensing The address of the LicensingModule
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address licensing) {
        LICENSING_MODULE = ILicensingModule(licensing);
    }

    /// @notice initializer for this implementation contract
    /// @param _name The name of the policy framework manager
    /// @param _licenseTextUrl The URL to the off chain legal agreement template text
    function __BasePolicyFrameworkManager_init(
        string memory _name,
        string memory _licenseTextUrl
    ) internal onlyInitializing {
        _getBasePolicyFrameworkManagerStorage().name = _name;
        _getBasePolicyFrameworkManagerStorage().licenseTextUrl = _licenseTextUrl;
    }

    /// @notice Returns the name of the policy framework manager
    function name() public view override returns (string memory) {
        return _getBasePolicyFrameworkManagerStorage().name;
    }

    /// @notice Returns the URL to the off chain legal agreement template text
    function licenseTextUrl() public view override returns (string memory) {
        return _getBasePolicyFrameworkManagerStorage().licenseTextUrl;
    }

    /// @notice IERC165 interface support.
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IPolicyFrameworkManager).interfaceId || super.supportsInterface(interfaceId);
    }

    function _getBasePolicyFrameworkManagerStorage()
        internal
        pure
        returns (BasePolicyFrameworkManagerStorage storage $)
    {
        assembly {
            $.slot := BasePolicyFrameworkManagerStorageLocation
        }
    }
}
