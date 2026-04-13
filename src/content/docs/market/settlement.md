---
title: "Results & Settlement"
---

# Lethe Market Results and Settlement

This document turns the market principles into a concrete design for:

- audit result schema,
- payout semantics,
- dispute flow,
- patch and regression evidence handling.

It is intentionally narrower than [MARKET_PRINCIPLES.md](MARKET_PRINCIPLES.md).
The principles document explains *why* the market should work this way. This
document explains *how* to encode those choices into protocol behavior.

For the delivery-specific architecture, storage, and notification split, see
[ENCRYPTED_DELIVERY_ARCHITECTURE.md](ENCRYPTED_DELIVERY_ARCHITECTURE.md).

---

## Scope

This design is for the **single-performer, pre-mainnet phase** that Lethe is in now,
but it is written to avoid painting the protocol into a corner before future
multi-performer expansion.

The immediate goal is:

1. pay for verified audit execution,
2. reward validated finding quality,
3. support patch and regression evidence when feasible,
4. avoid forcing unsafe or low-confidence patch proposals,
5. preserve a path to encrypted requester-only delivery.

---

## Design Position

The protocol should not overload a single enum with every meaning.

Instead, settlement should distinguish:

1. **Was the audit actually executed?**
2. **Did it produce findings?**
3. **What kind of remediation artifact exists?**
4. **How much of the payout is immediately claimable vs challengeable?**

This split keeps the market honest:

- `NoFindings` remains a real outcome,
- `NotExecuted` is not confused with a clean audit,
- patchability is tracked without forcing every finding into a patch,
- dispute logic can focus on the contested portion of the payout.

---

## Result Schema

### 1. Execution Outcome

This is the first gate and should be explicit.

```text
ExecutionOutcome
- Executed
- NotExecuted
- Disputed
```

Meaning:

- `Executed`: the worker completed the audit lifecycle and submitted a valid receipt.
- `NotExecuted`: the worker did not complete an audit. Examples: repo access failure, clone failure, timeout, precondition failure, unsupported config.
- `Disputed`: a previously submitted result is under formal challenge.

### 2. Finding Outcome

This describes what the audit concluded, but only when the audit was executed.

```text
FindingOutcome
- FindingsFound
- NoFindings
```

Meaning:

- `FindingsFound`: the run produced one or more findings.
- `NoFindings`: the run completed, but no findings were identified under the configured scope/tooling.

### 3. Remediation Outcome

This describes what kind of requester-actionable artifact accompanies the result.

```text
RemediationOutcome
- None
- PatchAttached
- MitigationOnly
- FindingOnly
```

Meaning:

- `None`: no remediation artifact is attached. Expected for `NoFindings` or `NotExecuted`.
- `PatchAttached`: a concrete patch and regression evidence are included.
- `MitigationOnly`: a safe direct patch is not proposed, but concrete mitigations are provided.
- `FindingOnly`: a validated finding exists, but a patch or mitigation artifact is not safely available yet.

### Recommended Valid Combinations

| Execution | Finding | Remediation | Meaning |
|----------|---------|-------------|---------|
| Executed | NoFindings | None | audit completed, nothing found under configured settings |
| Executed | FindingsFound | PatchAttached | best-case closed loop |
| Executed | FindingsFound | MitigationOnly | finding is real, but direct patch is unsafe or incomplete |
| Executed | FindingsFound | FindingOnly | finding exists, remediation artifact not ready |
| NotExecuted | None | None | worker did not complete the audit |
| Disputed | FindingsFound/NoFindings | any prior value | result is frozen pending dispute |

`NotExecuted + FindingsFound` should be invalid.

`NoFindings + PatchAttached` should be invalid.

---

## Requester-Facing Result Packet

The requester should receive a structured packet. The exact transport can differ
between testnet and production, but the content model should stay stable.

### Minimum Packet Fields

- `bountyId`
- `auditId`
- `auditedCommit`
- `triggerReason`
- `scopeMode`
- `toolMode`
- `ruleVersion`
- `executionOutcome`
- `findingOutcome`
- `remediationOutcome`
- `findingCount`
- `completedAt`
- `poeHash`
- `limitations`

### If Findings Exist

Add:

- finding summaries
- severity labels
- file locations
- exploit or reproducer instructions
- mitigation rationale

### If a Patch Exists

Add:

- patch diff or patch bundle
- patch explanation
- reproducer test
- regression evidence

### If No Findings Exist

Add:

- explicit wording:
  `No findings were identified for this commit under the configured audit scope and tooling. This is not a security guarantee.`

This wording matters. It avoids the false impression that the code is proven safe.

---

## Payout Semantics

### Payout Components

The payout should be modeled as separate buckets, not one opaque amount.

```text
Payout
- executionFee
- findingBonus
- patchBonus
- regressionBonus
```

### Why Separate Buckets

This improves incentive alignment:

- `executionFee` rewards real work even when no findings exist.
- `findingBonus` rewards validated signal quality.
- `patchBonus` rewards remediation quality, but only when a patch is appropriate.
- `regressionBonus` rewards proof that the submitted reproducer no longer succeeds on the patched revision.

### Recommended Settlement Rules

#### 1. Executed + NoFindings

Pay:

- `executionFee`

Do not pay:

- `findingBonus`
- `patchBonus`
- `regressionBonus`

#### 2. Executed + FindingsFound + FindingOnly

Pay immediately:

- `executionFee`

Hold in challenge window:

- `findingBonus`

Do not pay:

- `patchBonus`
- `regressionBonus`

#### 3. Executed + FindingsFound + MitigationOnly

Pay immediately:

- `executionFee`

Hold in challenge window:

- `findingBonus`

Optional:

- small `patchBonus` is not recommended here; keep mitigation quality as part of off-chain evaluation first

#### 4. Executed + FindingsFound + PatchAttached

Pay immediately:

- `executionFee`

Hold in challenge window:

- `findingBonus`
- `patchBonus`
- `regressionBonus`

This keeps high-value reward tied to post-submission validation.

### Challenge Window

The protocol should distinguish:

- **immediate settlement**
- **delayed settlement**

Recommended model:

- `executionFee`: claimable immediately once the audit is marked `Executed`
- all result-quality bonuses: claimable only after the challenge window closes without a successful dispute

This prevents the highest-value portion of the reward from leaving escrow before contested claims can be checked.

---

## Patch and Regression Rules

### Closed Loop Is Preferred, Not Mandatory

Lethe should prefer the cycle:

`finding -> patch proposal -> reproducer -> regression evidence`

But the protocol should not declare all findings invalid if the patch step is unsafe.

### Patchable Findings

When the performer claims `PatchAttached`, the result packet should include:

- a patch,
- a reproducer for the original issue,
- evidence that the reproducer no longer succeeds on the patched revision.

### Non-Patchable Findings

When the performer cannot safely provide a patch, the result packet should explain why.

Typical reasons:

- architectural defect,
- external dependency or upstream dependency issue,
- cross-system trust boundary problem,
- remediation requires migration or governance action,
- patch confidence is too low for automated proposal.

The protocol should reward honesty here rather than forcing unsafe diffs.

---

## Dispute Flow

### Goal

Disputes should be narrow, bounded, and expensive enough to discourage abuse,
without making valid challenges impractical.

### Proposed Flow

#### Level 0 — Challenge Window

The requester may challenge within a fixed window after result submission.

Grounds for challenge:

- finding is not reproducible,
- finding is duplicate,
- severity is materially overstated,
- patch is unsafe or does not address the claimed path,
- audit was marked `Executed` but did not meet the declared scope/tooling expectations.

#### Level 1 — Self Verification

Requester checks the delivered packet locally.

Possible outcomes:

- accept result,
- request no escalation,
- open dispute.

This should be cheap and expected for normal operations.

#### Level 2 — Fresh TEE Re-Verification

A fresh verifier run re-checks:

- original reproducer,
- patched revision if present,
- declared scope/tooling metadata,
- duplicate status if detectable.

This should be the default dispute mechanism.

#### Level 3 — Arbiter / Judge Path

Only used for unresolved cases such as:

- severity disagreement,
- unclear patch safety,
- ambiguous duplicate classification,
- partial reproducibility.

This can be human, agent, or mixed, but the protocol should keep this path exceptional.

### Dispute Effects On Settlement

When a dispute opens:

- `executionFee` should remain paid unless the audit was clearly fake or not executed,
- all challengeable bonus buckets should freeze,
- result status becomes `Disputed`,
- the losing side pays dispute cost in later market versions.

This split matters because it prevents total payout reversal for honest work while still protecting requesters from low-quality or false claims.

---

## Recommended On-Chain Modeling

The current single `submitAudit(... payout)` model is sufficient for testnet, but it is too compressed for the target market.

Recommended future shape:

```text
AuditResult
- executionOutcome
- findingOutcome
- remediationOutcome
- findingCount
- receiptHash
- ciphertextHash
- payoutBreakdown
```

Where `payoutBreakdown` contains:

- `executionFee`
- `findingBonus`
- `patchBonus`
- `regressionBonus`

And settlement state tracks:

- `claimableNow`
- `lockedUntil`
- `disputeStatus`

This should eventually replace the opaque single-payout semantics.

---

## Suggested LetheMarket Contract Delta

This section translates the settlement model into a concrete next-step contract
shape for [LetheMarket.sol](../contracts/contracts/LetheMarket.sol).

The intent is not to redesign the whole market at once. The intent is to evolve
the current contract from:

- one `AuditResult` enum,
- one `payout` number,
- one `AuditState`,

into a model that can support:

- real `NoFindings` settlement,
- patch and regression bonuses,
- challenge windows,
- partial payout locking.

### 1. Replace the Current Audit Result Shape

Current contract state is too compressed:

- `AuditResult { FindingsFound, NoFindings }`
- `AuditState { Pending, Verified, Disputed }`
- one `payout`

Recommended replacement:

```solidity
enum ExecutionOutcome { Executed, NotExecuted, Disputed }
enum FindingOutcome { None, FindingsFound, NoFindings }
enum RemediationOutcome { None, PatchAttached, MitigationOnly, FindingOnly }
enum DisputeStatus { None, Open, ResolvedRequester, ResolvedPerformer }
```

WHY:

- `NotExecuted` should not be overloaded onto `AuditState`
- `NoFindings` should remain distinct from "audit never ran"
- remediation quality should be tracked separately from finding existence
- dispute lifecycle should not erase the original result semantics

### 2. Add Explicit Payout Breakdown

```solidity
struct PayoutBreakdown {
    uint256 executionFee;
    uint256 findingBonus;
    uint256 patchBonus;
    uint256 regressionBonus;
}
```

This should replace the current single `payout` field as the source of truth.

The contract may still expose `totalPayout` as a derived value:

```solidity
uint256 totalPayout =
    p.executionFee +
    p.findingBonus +
    p.patchBonus +
    p.regressionBonus;
```

### 3. Split Audit Record From Settlement State

The current `Audit` struct mixes result semantics and settlement facts together.
That makes future dispute logic awkward.

Recommended shape:

```solidity
struct AuditRecord {
    uint256 bountyId;
    bytes32 commitHash;
    bytes32 poeHash;
    bytes32 receiptHash;      // requester-facing packet hash
    bytes32 ciphertextHash;   // encrypted delivery artifact hash
    uint256 completedAt;
    uint256 findingCount;
    uint256 ruleVersion;
    ExecutionOutcome executionOutcome;
    FindingOutcome findingOutcome;
    RemediationOutcome remediationOutcome;
}

struct AuditSettlement {
    PayoutBreakdown payout;
    uint256 claimableNow;
    uint256 lockedUntil;
    DisputeStatus disputeStatus;
    bool performerClaimed;
}
```

WHY:

- `AuditRecord` becomes the immutable statement of what happened
- `AuditSettlement` becomes the mutable settlement/dispute state
- dispute handling no longer requires mutating the semantic result fields

### 4. Replace `submitAudit(...)` With A Settlement-Aware Submission Path

Current signature:

```solidity
submitAudit(
    uint256 _bountyId,
    bytes32 _commitHash,
    bytes32 _poeHash,
    uint256 _ruleVersion,
    uint8 _resultType,
    uint256 _findingCount,
    uint256 _payout
)
```

Recommended next-step signature:

```solidity
// checks: bounty is Open, caller is attested ROFL TEE, result tuple is coherent,
//         payout breakdown fits the remaining bounty amount
// effects: stores immutable audit record, creates settlement state, releases
//          execution fee immediately, locks bonus buckets until challenge expiry
// returns: auditId
//
// WHY: separate semantic result fields from settlement timing so disputes can
//      freeze only the contested value instead of the whole audit outcome
// SECURITY: onlyTEE keeps payout-affecting writes behind attested ROFL origin
function submitAuditResult(
    uint256 _bountyId,
    bytes32 _commitHash,
    bytes32 _poeHash,
    bytes32 _receiptHash,
    bytes32 _ciphertextHash,
    uint256 _ruleVersion,
    uint8 _executionOutcome,
    uint8 _findingOutcome,
    uint8 _remediationOutcome,
    uint256 _findingCount,
    uint256 _executionFee,
    uint256 _findingBonus,
    uint256 _patchBonus,
    uint256 _regressionBonus
) external onlyTEE returns (uint256);
```

### 5. Add Explicit Validation Rules

The contract should reject incoherent tuples.

Examples:

- `NotExecuted + FindingsFound` → invalid
- `NoFindings + PatchAttached` → invalid
- `NoFindings + findingCount > 0` → invalid
- `FindingsFound + findingCount == 0` → invalid
- `NotExecuted + any payout except maybe zero execution fee policy` → invalid unless the protocol deliberately chooses to reward failed but costly attempts

Current recommendation:

- do **not** pay `NotExecuted` on-chain in the first production version
- only `Executed` results can create payout state

This keeps the first contract iteration simpler.

### 6. Add Challenge-Window State

The contract needs to represent "paid now vs locked until later."

Recommended per-audit fields:

```solidity
uint256 claimableNow;   // execution fee
uint256 lockedUntil;    // block.timestamp + challengeWindow
DisputeStatus disputeStatus;
```

And recommended market-level config:

```solidity
uint256 public challengeWindow;
```

Settable by owner/admin for now. Per-bounty override can come later if needed.

### 7. Add Claim / Dispute / Finalize Functions

The current contract pays the performer immediately inside `submitAudit`.
That is too early once bonus buckets and disputes exist.

Recommended additions:

```solidity
function claimAuditPayout(uint256 _auditId) external;
function disputeAudit(uint256 _auditId, bytes32 _reasonHash) external;
function resolveAuditDispute(
    uint256 _auditId,
    bool _requesterWins
) external onlyOwner;
function finalizeAuditSettlement(uint256 _auditId) external;
```

Recommended semantics:

- `claimAuditPayout`
  - performer claims `claimableNow`
  - later claims unlocked bonus buckets after challenge expiry

- `disputeAudit`
  - requester freezes bonus buckets
  - result becomes `Disputed` at the settlement layer, not by deleting the original record

- `resolveAuditDispute`
  - temporary centralized path for the single-performer phase
  - can later be replaced by verifier / arbiter logic

- `finalizeAuditSettlement`
  - after challenge expiry, unlocks the remaining performer payout if no dispute succeeded

### 8. Event Surface

Current `AuditSubmitted(auditId, bountyId, result, findingCount)` is not rich enough.

Recommended event set:

```solidity
event AuditResultSubmitted(
    uint256 indexed auditId,
    uint256 indexed bountyId,
    ExecutionOutcome executionOutcome,
    FindingOutcome findingOutcome,
    RemediationOutcome remediationOutcome,
    uint256 findingCount,
    uint256 executionFee,
    uint256 lockedBonusTotal,
    uint256 lockedUntil
);

event AuditDisputed(uint256 indexed auditId, bytes32 reasonHash);
event AuditSettlementFinalized(uint256 indexed auditId, uint256 releasedAmount);
event AuditPayoutClaimed(uint256 indexed auditId, address indexed performer, uint256 amount);
```

### 9. Minimal Migration Path

The safest incremental path from the current contract is:

1. keep `submitAudit` untouched on testnet while the worker and docs stabilize,
2. add new enums/structs in a fresh contract version,
3. replace immediate full payout with:
   - immediate `executionFee`
   - locked bonus buckets
4. keep dispute resolution owner-gated in the first version,
5. only then move to verifier-driven dispute settlement.

This avoids trying to solve multi-performer economics and decentralized arbitration
in the same contract migration as encrypted delivery and query-key auth.

---

## Suggested Implementation Order

### Immediate

1. finalize result classes and naming,
2. decide which fields stay on-chain vs encrypted in the requester packet,
3. add payout breakdown to the design even if testnet still settles as a single amount,
4. define challenge-window semantics.

### After Hybrid Query-Key Auth

1. implement encrypted requester delivery,
2. migrate result packet transport off plaintext PRs,
3. add patch and regression artifact hashing,
4. add dispute-aware settlement buckets.

### Later

1. extend the same model to multi-performer competition,
2. add verifier rewards and false-positive slashing,
3. connect performer reputation updates to validated outcome quality.

---

## Summary

The market should settle on four principles:

1. pay for real audits, not just positive findings,
2. keep `NoFindings` as a real result,
3. reward patches and regression evidence when they are safe and credible,
4. use dispute logic to challenge quality claims, not as a substitute for confidentiality design.
