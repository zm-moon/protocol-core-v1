// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.23;

import { AccessControlled } from "../../../access/AccessControlled.sol";
import { ILicenseRegistry } from "../../../interfaces/registries/ILicenseRegistry.sol";

/// @title LicensorApprovalChecker
/// @notice Manages the approval of derivative IP accounts by the licensor. Used to verify
/// licensing terms like "Derivatives With Approval" in PIL.
abstract contract LicensorApprovalChecker is AccessControlled {
    /// @notice Emits when a derivative IP account is approved by the licensor.
    /// @param licenseId The ID of the license waiting for approval
    /// @param ipId The ID of the derivative IP to be approved
    /// @param caller The executor of the approval
    /// @param approved Result of the approval
    event DerivativeApproved(uint256 indexed licenseId, address indexed ipId, address indexed caller, bool approved);

    /// @notice Storage for derivative IP approvals.
    /// @param approvals Approvals for derivative IP.
    /// @dev License Id => licensor => childIpId => approved
    /// @custom:storage-location erc7201:story-protocol.LicensorApprovalChecker
    struct LicensorApprovalCheckerStorage {
        mapping(uint256 => mapping(address => mapping(address => bool))) approvals;
    }

    /// @notice Returns the license registry address
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    ILicenseRegistry public immutable LICENSE_REGISTRY;

    // keccak256(abi.encode(uint256(keccak256("story-protocol.LicensorApprovalChecker")) - 1)) & ~bytes32(uint256(0xff));
    // WARNINGWARNINGWARNINGWARNINGWARNINGWARNINGWARNINGWARNINGWARNINGWARNINGWARNINGWARNINGWARNINGWARNINGWARNINGWARNINGWARNINGWARNINGWARNING: NOT TRUE UPDATE
    bytes32 private constant LicensorApprovalCheckerStorageLocation = 0xaed547d8331715caab0800583ca79170ef3186de64f009413517d98c5b905c00;

    /// @notice Constructor function
    /// @param accessController The address of the AccessController contract
    /// @param ipAccountRegistry The address of the IPAccountRegistry contract
    /// @param licenseRegistry The address of the LicenseRegistry contract
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address accessController,
        address ipAccountRegistry,
        address licenseRegistry
    ) AccessControlled(accessController, ipAccountRegistry) {
        LICENSE_REGISTRY = ILicenseRegistry(licenseRegistry);
    }

    /// @notice Approves or disapproves a derivative IP account.
    /// @param licenseId The ID of the license waiting for approval
    /// @param childIpId The ID of the derivative IP to be approved
    /// @param approved Result of the approval
    function setApproval(uint256 licenseId, address childIpId, bool approved) external {
        address licensorIpId = LICENSE_REGISTRY.licensorIpId(licenseId);
        _setApproval(licensorIpId, licenseId, childIpId, approved);
    }

    /// @notice Checks if a derivative IP account is approved by the licensor.
    /// @param licenseId The ID of the license NFT issued from a policy of the licensor
    /// @param childIpId The ID of the derivative IP to be approved
    /// @return approved True if the derivative IP account using the license is approved
    function isDerivativeApproved(uint256 licenseId, address childIpId) public view returns (bool) {
        address licensorIpId = LICENSE_REGISTRY.licensorIpId(licenseId);
        LicensorApprovalCheckerStorage storage $ = _getLicensorApprovalCheckerStorage();
        return $.approvals[licenseId][licensorIpId][childIpId];
    }

    /// @notice Sets the approval for a derivative IP account.
    /// @dev This function is only callable by the licensor IP account.
    /// @param licensorIpId The ID of the licensor IP account
    /// @param licenseId The ID of the license waiting for approval
    /// @param childIpId The ID of the derivative IP to be approved
    /// @param approved Result of the approval
    function _setApproval(
        address licensorIpId,
        uint256 licenseId,
        address childIpId,
        bool approved
    ) internal verifyPermission(licensorIpId) {
        LicensorApprovalCheckerStorage storage $ = _getLicensorApprovalCheckerStorage();
        $.approvals[licenseId][licensorIpId][childIpId] = approved;
        emit DerivativeApproved(licenseId, licensorIpId, msg.sender, approved);
    }

    function _getLicensorApprovalCheckerStorage() private pure returns (LicensorApprovalCheckerStorage storage $) {
        assembly {
            $.slot := LicensorApprovalCheckerStorageLocation
        }
    }
}
