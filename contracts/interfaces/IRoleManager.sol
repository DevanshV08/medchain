// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IRoleManager
/// @notice Interface for MedChain's participant registry and role-based access control.
/// @dev Implemented by RoleManager.sol. Other MedChain contracts query this interface
///      to check whether an address is allowed to perform a supply-chain action.
interface IRoleManager {
    /// @notice Emitted when the regulator registers a new supply-chain participant.
    event ParticipantRegistered(address indexed account, bytes32 indexed role, string name);

    /// @notice Emitted when a participant is removed or suspended.
    event ParticipantRevoked(address indexed account, bytes32 indexed role);

    /// @notice Registers a participant (manufacturer, distributor or pharmacy) and assigns its role.
    /// @dev Only callable by an account holding REGULATOR_ROLE.
    /// @param account Wallet address of the participant.
    /// @param role One of MANUFACTURER_ROLE, DISTRIBUTOR_ROLE or PHARMACY_ROLE.
    /// @param name Human-readable organization name (e.g. "Acme Pharma Ltd.").
    function registerParticipant(address account, bytes32 role, string calldata name) external;

    /// @notice Revokes a participant's role, e.g. if a licence is suspended.
    /// @dev Only callable by REGULATOR_ROLE.
    function revokeParticipant(address account, bytes32 role) external;

    /// @notice Returns true if `account` currently holds `role`.
    function isAuthorized(address account, bytes32 role) external view returns (bool);

    /// @notice Returns the registered organization name for an address.
    function participantName(address account) external view returns (string memory);
}
