// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title IDrugBatch
/// @notice Interface for MedChain's drug-batch tokens and chain-of-custody functions.
/// @dev Each physical production batch of a medicine is represented by one ERC-721 token.
///      The token's owner is always the party currently holding the batch, so ERC-721
///      ownership history doubles as the custody history.
interface IDrugBatch {
    /// @notice Lifecycle states a batch moves through.
    /// Manufactured -> InTransit -> Received -> (InTransit -> Received)* -> Dispensed
    /// Recalled can be reached from any state except Dispensed.
    enum Status {
        Manufactured, // minted by the manufacturer, still at the factory
        InTransit,    // shipped, not yet confirmed by the receiver
        Received,     // receiver confirmed delivery and now holds custody
        Dispensed,    // pharmacy dispensed the batch to patients (terminal)
        Recalled      // regulator flagged the batch as unsafe (terminal)
    }

    /// @notice On-chain metadata stored for every batch.
    /// @dev Large documents (certificates of analysis, QA reports) live on IPFS;
    ///      only their content identifier (CID) is stored here.
    struct Batch {
        string drugName;          // e.g. "Amoxicillin 500mg"
        string batchNumber;       // manufacturer's batch / lot number
        uint64 manufactureDate;   // unix timestamp
        uint64 expiryDate;        // unix timestamp
        string documentsCID;      // IPFS CID of supporting documents
        address manufacturer;     // original minter
        address pendingReceiver;  // set while InTransit, cleared on receipt
        Status status;
    }

    /// @notice Emitted when a manufacturer creates a new batch.
    event BatchMinted(uint256 indexed batchId, address indexed manufacturer, string drugName, string batchNumber);

    /// @notice Emitted when the current holder ships a batch to the next party.
    event BatchShipped(uint256 indexed batchId, address indexed from, address indexed to, uint64 timestamp);

    /// @notice Emitted when the receiver confirms delivery and takes custody.
    event BatchReceived(uint256 indexed batchId, address indexed by, uint64 timestamp);

    /// @notice Emitted when a pharmacy dispenses a batch.
    event BatchDispensed(uint256 indexed batchId, address indexed pharmacy, uint64 timestamp);

    /// @notice Emitted when the regulator recalls a batch.
    event BatchRecalled(uint256 indexed batchId, address indexed regulator, string reason);

    /// @notice Creates a new batch token owned by the calling manufacturer.
    /// @dev Only MANUFACTURER_ROLE. Expiry must be after manufacture date.
    /// @return batchId The token ID of the newly minted batch.
    function mintBatch(
        string calldata drugName,
        string calldata batchNumber,
        uint64 manufactureDate,
        uint64 expiryDate,
        string calldata documentsCID
    ) external returns (uint256 batchId);

    /// @notice Ships a batch the caller currently holds to a registered receiver.
    /// @dev Caller must own the token. Allowed hops: manufacturer -> distributor,
    ///      distributor -> distributor, distributor -> pharmacy. Reverts if the batch
    ///      is expired, recalled or already dispensed. Sets status to InTransit.
    function shipBatch(uint256 batchId, address to) external;

    /// @notice Confirms delivery of a batch that was shipped to the caller.
    /// @dev Caller must equal `pendingReceiver`. Transfers the ERC-721 token to the
    ///      caller, so custody on-chain matches physical possession.
    function receiveBatch(uint256 batchId) external;

    /// @notice Marks a batch as dispensed to patients. Terminal state.
    /// @dev Only the PHARMACY_ROLE holder that currently owns the batch.
    function dispenseBatch(uint256 batchId) external;

    /// @notice Flags a batch as recalled so every participant and the public sees it.
    /// @dev Only REGULATOR_ROLE. Blocks all further shipping and dispensing.
    function recallBatch(uint256 batchId, string calldata reason) external;

    /// @notice Returns the stored metadata for a batch.
    function getBatch(uint256 batchId) external view returns (Batch memory);

    /// @notice Public verification helper used by the QR-code page.
    /// @return authentic True if the batch exists and was minted by a registered manufacturer.
    /// @return status Current lifecycle status.
    /// @return expired True if block.timestamp is past the expiry date.
    function verifyBatch(uint256 batchId) external view returns (bool authentic, Status status, bool expired);
}
