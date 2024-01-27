// SPDX-License-Identifier: UNLICENSED
// See https://github.com/storyprotocol/protocol-contracts/blob/main/StoryProtocol-AlphaTestingAgreement-17942166.3.pdf
pragma solidity ^0.8.23;

// contracts
import { ILinkParamVerifier } from "contracts/interfaces/licensing/ILinkParamVerifier.sol";
import { IMintParamVerifier } from "contracts/interfaces/licensing/IMintParamVerifier.sol";
import { IParamVerifier } from "contracts/interfaces/licensing/IParamVerifier.sol";
import { ITransferParamVerifier } from "contracts/interfaces/licensing/ITransferParamVerifier.sol";
import { Errors } from "contracts/lib/Errors.sol";
import { LicenseRegistry } from "contracts/registries/LicenseRegistry.sol";
import { ShortStringOps } from "contracts/utils/ShortStringOps.sol";

abstract contract BaseParamVerifier is IParamVerifier {
    // /// @notice Gets the protocol-wide module access controller.
    // IAccessController public immutable ACCESS_CONTROLLER;

    // /// @notice Gets the protocol-wide IP account registry.
    // IPAccountRegistry public immutable IP_ACCOUNT_REGISTRY;

    // /// @notice Gets the protocol-wide IP record registry.
    // IPRecordRegistry public immutable IP_RECORD_REGISTRY;

    /// @notice Gets the protocol-wide license registry.
    LicenseRegistry public immutable LICENSE_REGISTRY;

    string internal NAME;

    /// @notice Initializes the base module contract.
    /// @param licenseRegistry The address of the license registry.
    constructor(address licenseRegistry, string memory name_) {
        LICENSE_REGISTRY = LicenseRegistry(licenseRegistry);
        NAME = name_;
    }

    /// @notice Modifier for authorizing the calling entity.
    modifier onlyLicenseRegistry() {
        if (msg.sender != address(LICENSE_REGISTRY)) {
            revert Errors.BaseParamVerifier__Unauthorized();
        }
        _;
    }

    function name() external view override returns (bytes32) {
        return ShortStringOps.stringToBytes32(NAME);
    }

    function nameString() external view override returns (string memory) {
        return NAME;
    }

    // TODO: implement flexible json()
    function json() external view returns (string memory) {
        return "";
    }
}