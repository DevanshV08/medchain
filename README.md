line1
  line2 `x`
line3
# MedChain: Pharmaceutical Supply Chain Tracking on Ethereum

**CSE 540: Engineering Blockchain Applications (Fall 2026 B), Arizona State University**
Team: Naman Dewan, Manan Batra, Devansh Verma, Omkar Hundekari

> **Status: Smart Contract Design Draft.** Contract structure, interfaces, events and function signatures are defined and documented. Most state-changing functions are stubs marked `TODO` and will be implemented for the interim demo.

## Project description

Counterfeit and diverted medicines are a serious global problem, and today each party in the drug supply chain keeps its own records, so there is no single trusted history of where a batch came from or who handled it.

MedChain records the full lifecycle of each drug batch on Ethereum:

1. A **manufacturer** mints each production batch as a unique **ERC-721 token**, with drug name, batch number, manufacture and expiry dates, and an IPFS link to supporting documents.
2. Each hand-off (manufacturer → distributor → pharmacy) is a **two-step ship/receive handshake**, so custody only changes when the receiver confirms delivery.
3. A **pharmacy** marks the batch as dispensed when it reaches patients.
4. A **regulator** can **recall** a batch at any time, and the recall is immediately visible to everyone.
5. Anyone (pharmacist, patient) can **verify** a batch's authenticity, status and expiry through a public QR-code page.

## Architecture

```
                 ┌──────────────────────┐
                 │     RoleManager      │  OpenZeppelin AccessControl
                 │  REGULATOR / MANUF.  │  regulator registers participants
                 │  DISTRIBUTOR / PHARM │
                 └──────────▲───────────┘
                            │ isAuthorized()
                 ┌──────────┴───────────┐
                 │      DrugBatch       │  ERC-721, one token per batch
                 │ mint / ship / receive│  custody = token ownership
                 │ dispense / recall    │  events = audit trail
                 └──────────▲───────────┘
                            │ ethers.js
      ┌─────────────────────┼─────────────────────┐
  Role dashboards (React + MetaMask)     Public QR verification page
                            │
                    IPFS (certificates, QA reports; only CID on-chain)
```

### Contracts

| File | Purpose |
|---|---|
| `contracts/interfaces/IRoleManager.sol` | Interface for participant registration and role checks |
| `contracts/interfaces/IDrugBatch.sol` | Interface for batch data model, lifecycle `Status` enum, events and custody functions |
| `contracts/RoleManager.sol` | Role-based access control (regulator, manufacturer, distributor, pharmacy) |
| `contracts/DrugBatch.sol` | ERC-721 batch tokens and chain-of-custody logic |

### Batch lifecycle

```
Manufactured ──ship──▶ InTransit ──receive──▶ Received ──ship──▶ InTransit ... ──▶ Received ──dispense──▶ Dispensed
      └────────────────────────── recall (regulator, any non-terminal state) ─────────────────────────▶ Recalled
```

### Key functions

| Function | Caller | Description |
|---|---|---|
| `registerParticipant(account, role, name)` | Regulator | Onboard a manufacturer, distributor or pharmacy |
| `revokeParticipant(account, role)` | Regulator | Suspend a participant |
| `mintBatch(drugName, batchNumber, mfgDate, expiryDate, documentsCID)` | Manufacturer | Create a batch token |
| `shipBatch(batchId, to)` | Current holder | Start a hand-off to a registered receiver |
| `receiveBatch(batchId)` | Pending receiver | Confirm delivery; token transfers to receiver |
| `dispenseBatch(batchId)` | Pharmacy | Mark batch dispensed (terminal) |
| `recallBatch(batchId, reason)` | Regulator | Flag batch unsafe (terminal) |
| `verifyBatch(batchId)` | Anyone | Returns authenticity, status, and whether it is expired |

### Design decisions

- **Custody = token ownership.** Regular ERC-721 transfers are blocked in `_update`; custody can only move through `shipBatch` / `receiveBatch`, which enforce roles and batch state.
- **Two-step hand-off** prevents a sender from pushing a batch onto someone who never received it.
- **Minimal on-chain data.** Documents live on IPFS; only the CID is stored, keeping gas costs low and business data off the public chain.
- **Events for every action**, so the frontend can rebuild a batch's full history without extra storage.

## Tech stack

- Solidity 0.8.24, OpenZeppelin Contracts 5.x
- Hardhat (compile, test, local node, deployment), ethers.js
- Ethereum Sepolia testnet
- IPFS for documents
- React + ethers.js + MetaMask frontend (planned)

## Setup

Requirements: Node.js 18+ and npm.

```bash
git clone <this-repo-url>
cd medchain
npm install
npm run compile
npm test
```

## Deploy

**Local network**

```bash
npm run node          # terminal 1: starts a local Hardhat chain
npm run deploy:local  # terminal 2: deploys RoleManager, then DrugBatch
```

**Sepolia testnet** (planned for the interim demo)

```bash
cp .env.example .env  # add SEPOLIA_RPC_URL and a test-wallet PRIVATE_KEY
npm run deploy:sepolia
```

## Usage (intended flow)

1. Deployer is the regulator; it calls `registerParticipant` for each manufacturer, distributor and pharmacy.
2. Manufacturer calls `mintBatch` and gets a `batchId`.
3. Manufacturer calls `shipBatch(batchId, distributor)`; distributor calls `receiveBatch(batchId)`.
4. Distributor ships to a pharmacy the same way; pharmacy receives, then calls `dispenseBatch`.
5. At any point, the regulator can call `recallBatch`.
6. Anyone calls `verifyBatch(batchId)` (or scans the QR code) to check authenticity and status.

## Repository structure

```
contracts/
  interfaces/IRoleManager.sol
  interfaces/IDrugBatch.sol
  RoleManager.sol
  DrugBatch.sol
scripts/deploy.js
test/deploy.test.js
hardhat.config.js
.env.example
```

## Roadmap

| Milestone | Due | Scope |
|---|---|---|
| Smart contract design draft | Nov 1 | This repo: interfaces, signatures, documentation |
| Interim demo | Nov 15 | Implement custody functions, unit tests, deploy to Sepolia, basic frontend |
| Final deliverables | Dec 4 | Full frontend + QR verification, gas analysis, report, presentation |
