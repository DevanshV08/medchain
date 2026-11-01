// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IDrugBatch} from "./interfaces/IDrugBatch.sol";
import {RoleManager} from "./RoleManager.sol";

/// @title DrugBatch
/// @notice ERC-721 token where each token is one production batch of a medicine.
///         Records the full chain of custody: manufacturer -> distributor(s) -> pharmacy.
/// @dev Design decisions:
///      - Custody uses a two-step ship/receive handshake, so a batch is only "held" by
///        a party once that party confirms delivery.
///      - Plain ERC-721 transfers are blocked (see _update) so custody can only change
///        through shipBatch/receiveBatch, which enforce roles and batch state.
///      - Only hashes/CIDs go on-chain; documents stay on IPFS to keep gas low.
contract DrugBatch is ERC721, IDrugBatch {
    /// @dev Access-control registry deployed separately (see RoleManager.sol).
    RoleManager public immutable roles;

    /// @dev batchId => batch metadata and lifecycle state.
    mapping(uint256 => Batch) private _batches;

    /// @dev Next token ID to mint. Starts at 1 so 0 can mean "no batch".
    uint256 private _nextId = 1;

    /// @dev Set while shipBatch/receiveBatch move a token, to allow that one transfer.
    bool private _custodyTransfer;

    /// @param roleManager Address of the deployed RoleManager contract.
    constructor(address roleManager) ERC721("MedChain Drug Batch", "MEDB") {
        roles = RoleManager(roleManager);
    }

    // ---------------------------------------------------------------------
    // Modifiers
    // ---------------------------------------------------------------------

    /// @dev Restricts a function to accounts holding `role` in RoleManager.
    modifier onlyRoleHolder(bytes32 role) {
        require(roles.isAuthorized(msg.sender, role), "DrugBatch: unauthorized role");
        _;
    }

    /// @dev Reverts if the batch is recalled, dispensed or past expiry.
    modifier onlyActive(uint256 batchId) {
        // TODO: check status != Recalled/Dispensed and block.timestamp < expiryDate.
        _;
    }

    // ---------------------------------------------------------------------
    // Manufacturer
    // ---------------------------------------------------------------------

    /// @inheritdoc IDrugBatch
    function mintBatch(
        string calldata drugName,
        string calldata batchNumber,
        uint64 manufactureDate,
        uint64 expiryDate,
        string calldata documentsCID
    ) external onlyRoleHolder(roles.MANUFACTURER_ROLE()) returns (uint256 batchId) {
        // TODO: require expiryDate > manufactureDate, store Batch with status
        // Manufactured, _safeMint to msg.sender, emit BatchMinted.
        drugName; batchNumber; manufactureDate; expiryDate; documentsCID;
        batchId = _nextId;
        revert("Not implemented");
    }

    // ---------------------------------------------------------------------
    // Custody transfers (manufacturer / distributor / pharmacy)
    // ---------------------------------------------------------------------

    /// @inheritdoc IDrugBatch
    function shipBatch(uint256 batchId, address to) external onlyActive(batchId) {
        // TODO:
        // 1. require ownerOf(batchId) == msg.sender
        // 2. require a valid hop: manufacturer->distributor, distributor->distributor,
        //    distributor->pharmacy (checked via roles.isAuthorized)
        // 3. set pendingReceiver = to, status = InTransit, emit BatchShipped
        batchId; to;
        revert("Not implemented");
    }

    /// @inheritdoc IDrugBatch
    function receiveBatch(uint256 batchId) external onlyActive(batchId) {
        // TODO: require msg.sender == pendingReceiver; set _custodyTransfer = true,
        // _transfer(owner, msg.sender, batchId), reset flag, clear pendingReceiver,
        // status = Received, emit BatchReceived.
        batchId;
        revert("Not implemented");
    }

    /// @inheritdoc IDrugBatch
    function dispenseBatch(uint256 batchId)
        external
        onlyRoleHolder(roles.PHARMACY_ROLE())
        onlyActive(batchId)
    {
        // TODO: require ownerOf(batchId) == msg.sender and status == Received;
        // set status = Dispensed, emit BatchDispensed.
        batchId;
        revert("Not implemented");
    }

    // ---------------------------------------------------------------------
    // Regulator
    // ---------------------------------------------------------------------

    /// @inheritdoc IDrugBatch
    function recallBatch(uint256 batchId, string calldata reason)
        external
        onlyRoleHolder(roles.REGULATOR_ROLE())
    {
        // TODO: require batch exists and is not Dispensed; set status = Recalled,
        // emit BatchRecalled. Recall is visible to everyone via verifyBatch.
        batchId; reason;
        revert("Not implemented");
    }

    // ---------------------------------------------------------------------
    // Public views (used by the QR verification page)
    // ---------------------------------------------------------------------

    /// @inheritdoc IDrugBatch
    function getBatch(uint256 batchId) external view returns (Batch memory) {
        return _batches[batchId];
    }

    /// @inheritdoc IDrugBatch
    function verifyBatch(uint256 batchId)
        external
        view
        returns (bool authentic, Status status, bool expired)
    {
        Batch storage b = _batches[batchId];
        authentic = b.manufacturer != address(0)
            && roles.isAuthorized(b.manufacturer, roles.MANUFACTURER_ROLE());
        status = b.status;
        expired = b.expiryDate != 0 && block.timestamp >= b.expiryDate;
    }

    // ---------------------------------------------------------------------
    // Internal
    // ---------------------------------------------------------------------

    /// @dev Blocks ordinary ERC-721 transfers. Minting (from == 0) and transfers made
    ///      inside receiveBatch (_custodyTransfer == true) are the only moves allowed,
    ///      so token ownership always reflects verified custody.
    function _update(address to, uint256 tokenId, address auth)
        internal
        override
        returns (address)
    {
        address from = _ownerOf(tokenId);
        require(from == address(0) || _custodyTransfer, "DrugBatch: use shipBatch/receiveBatch");
        return super._update(to, tokenId, auth);
    }
}
