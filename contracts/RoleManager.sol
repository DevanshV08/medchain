// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IRoleManager} from "./interfaces/IRoleManager.sol";

/// @title RoleManager
/// @notice Central registry of who is allowed to do what in the MedChain supply chain.
/// @dev Built on OpenZeppelin AccessControl. The deployer becomes the regulator (admin).
///      The regulator onboards manufacturers, distributors and pharmacies; DrugBatch.sol
///      calls `isAuthorized` before every custody action.
contract RoleManager is AccessControl, IRoleManager {
    /// @dev Regulator: registers participants and can recall batches. Admin of all roles.
    bytes32 public constant REGULATOR_ROLE = keccak256("REGULATOR_ROLE");
    /// @dev Manufacturer: can mint new batch tokens.
    bytes32 public constant MANUFACTURER_ROLE = keccak256("MANUFACTURER_ROLE");
    /// @dev Distributor: can receive batches and ship them onward.
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    /// @dev Pharmacy: can receive batches and mark them dispensed.
    bytes32 public constant PHARMACY_ROLE = keccak256("PHARMACY_ROLE");

    /// @dev Organization name for each registered address (shown in the frontend).
    mapping(address => string) private _names;

    /// @notice Deployer is set up as the regulator and as admin of every role.
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REGULATOR_ROLE, msg.sender);
        _setRoleAdmin(MANUFACTURER_ROLE, REGULATOR_ROLE);
        _setRoleAdmin(DISTRIBUTOR_ROLE, REGULATOR_ROLE);
        _setRoleAdmin(PHARMACY_ROLE, REGULATOR_ROLE);
    }

    /// @inheritdoc IRoleManager
    function registerParticipant(address account, bytes32 role, string calldata name)
        external
        onlyRole(REGULATOR_ROLE)
    {
        // TODO: validate that `role` is one of the three participant roles,
        // reject zero address and empty names, then grant the role and store the name.
        account; role; name;
        revert("Not implemented");
    }

    /// @inheritdoc IRoleManager
    function revokeParticipant(address account, bytes32 role) external onlyRole(REGULATOR_ROLE) {
        // TODO: revoke the role and emit ParticipantRevoked.
        // Batches already held by the participant stay on-chain; the frontend flags them.
        account; role;
        revert("Not implemented");
    }

    /// @inheritdoc IRoleManager
    function isAuthorized(address account, bytes32 role) external view returns (bool) {
        return hasRole(role, account);
    }

    /// @inheritdoc IRoleManager
    function participantName(address account) external view returns (string memory) {
        return _names[account];
    }
}
