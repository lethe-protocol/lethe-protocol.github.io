---
title: "Encrypted Delivery"
---

# Lethe Encrypted Delivery Architecture

This document specifies how Lethe should deliver audit results without exposing
plaintext findings outside the TEE boundary.

It complements:

- [MARKET_PRINCIPLES.md](MARKET_PRINCIPLES.md)
- [MARKET_RESULTS_AND_SETTLEMENT.md](MARKET_RESULTS_AND_SETTLEMENT.md)
- [ROADMAP.md](ROADMAP.md)

The core design rule is simple:

> Signal, Telegram, email, GitHub, or webhooks may notify. They must not become
> the primary plaintext delivery channel for vulnerability details.

---

## Design Goal

Production delivery should satisfy all of the following:

1. plaintext findings stay inside the TEE until encrypted for the requester,
2. the operator cannot read the delivered result,
3. notification channels carry only metadata or ciphertext handles,
4. on-chain settlement records integrity anchors, not plaintext content,
5. the model works for both open-source and closed-source repos.

---

## Delivery Planes

Encrypted delivery should be split into three planes.

### 1. Authorization Plane

Determines who is allowed to decrypt the result.

Minimum requester-owned inputs:

- `requesterEncryptionPubKey`
- `deliveryMode`
- `notifyTargets`

Recommended initial `deliveryMode` values:

- `RequesterOnly`
- `CollaboratorsOnly`
- `PublicAfterApproval`

For the first production implementation, Lethe should support only
`RequesterOnly`.

### 2. Data Plane

Defines how the TEE packages, encrypts, and stores audit output.

The TEE should produce a single `review packet` containing:

- audit metadata,
- finding report,
- optional patch bundle,
- optional regression evidence,
- settlement-facing integrity fields.

The packet is encrypted to the requester's public key before leaving the TEE.

### 3. Notification Plane

Defines how the requester learns that a packet is available.

Allowed notification content:

- result ready,
- bounty id / audit id,
- result type,
- handle or retrieval URI,
- ciphertext hash,
- optional very short non-sensitive summary.

Disallowed notification content:

- plaintext finding details,
- plaintext patch diff,
- exploit instructions,
- source excerpts.

Signal, Telegram, email, and webhook adapters all belong here.

---

## Policy Model

The correct policy split is not `open-source vs closed-source`.

The correct split is:

- who may see plaintext,
- when plaintext may be disclosed,
- whether public disclosure requires requester approval.

### Recommended Rules

#### Default rule

All repos, including open-source repos, default to:

- `deliveryMode = RequesterOnly`

#### Open-source repos

Open-source repos may later opt into:

- `PublicAfterApproval`

But that should not change the default private delivery path.

#### Closed-source repos

Closed-source repos should remain:

- `RequesterOnly`

This keeps disclosure policy explicit instead of inferring it from repo
visibility.

---

## Review Packet Format

The TEE should generate a structured packet before encryption.

Example logical shape:

```json
{
  "version": 1,
  "bountyId": 1,
  "auditId": 12,
  "repoRef": {
    "owner": "lethe-protocol",
    "repo": "vuln-test-repo",
    "commit": "c076738d9c1aa58fec6eb840d4a4789463ac5bc3"
  },
  "result": {
    "executionOutcome": "Executed",
    "findingOutcome": "FindingsFound",
    "remediationOutcome": "FindingOnly",
    "findingCount": 4
  },
  "auditContext": {
    "triggerReason": "first-audit",
    "scopeMode": 1,
    "toolMode": 1,
    "ruleVersion": 1,
    "poeHash": "0x..."
  },
  "report": {
    "summary": "...",
    "findings": []
  },
  "patch": {
    "format": "git-diff",
    "content": "..."
  },
  "regression": {
    "format": "files",
    "files": []
  }
}
```

### Required Packet Sections

- `version`
- `bountyId`
- `auditId`
- `repoRef.commit`
- `result`
- `auditContext`
- `report`

### Optional Packet Sections

- `patch`
- `regression`
- `mitigation`

### No-findings Packet Rule

When `findingOutcome = NoFindings`, packet text must say:

`No findings were identified for this commit under the configured audit scope and tooling. This is not a security guarantee.`

---

## Cryptography Model

### Recommended MVP

Use hybrid encryption:

1. generate a random symmetric content key inside the TEE,
2. encrypt the packet with that content key,
3. wrap the content key to the requester's public key,
4. emit:
   - encrypted packet ciphertext,
   - encrypted content key,
   - packet manifest,
   - ciphertext hash.

### Recommended Key Type

Use a dedicated requester delivery key, not the requester's transaction key.

Recommended choice:

- X25519 public key for packet delivery

This keeps delivery keys separate from settlement keys and makes future
collaborator fan-out easier.

### Why Not Put Plaintext in Signal or Telegram

- bot operators can see or log message content,
- message platforms become durable plaintext stores,
- patch and regression artifacts do not fit well in chat messages,
- channel metadata leaks too much about result timing and severity.

---

## Storage Model

Encrypted delivery needs a ciphertext store. The store does not need to be
trusted if it only sees ciphertext.

### Recommended MVP Storage

- object storage such as S3 or R2
- random object key or opaque packet handle

### TEE Output

The TEE should upload:

- encrypted packet blob
- small encrypted manifest or cleartext manifest with only non-sensitive fields

### On-Chain Anchors

The contract should record:

- `ciphertextHash`
- `manifestHash`
- `deliveryMode`
- `deliveryStatus`
- optional `packetLocatorHash`

The chain should not store the packet itself.

---

## Notification Adapters

Notification adapters should only announce availability.

### Allowed Adapters

- webhook
- email
- Signal
- Telegram

### Common Notification Payload

```json
{
  "type": "audit_result_ready",
  "bountyId": 1,
  "auditId": 12,
  "resultType": "FindingsFound",
  "deliveryMode": "RequesterOnly",
  "handle": "pkt_01J...",
  "ciphertextHash": "0x..."
}
```

### Adapter Rules

#### Webhook

- easiest first implementation
- good for requester-owned backend automation
- should carry no plaintext result body

#### Signal / Telegram

- suitable as alert channels
- should never carry plaintext findings
- should only carry handle + integrity reference + optional non-sensitive status

---

## Contract Delta

`LetheMarket.sol` should grow a delivery-specific state surface.

### Suggested Fields

```text
DeliveryMode
- RequesterOnly
- CollaboratorsOnly
- PublicAfterApproval

DeliveryStatus
- None
- Pending
- Delivered
- Acknowledged
- Failed
```

### Suggested Requester Registration Fields

- `bytes requesterEncryptionPubKey`
- `uint8 preferredDeliveryMode`
- `bytes32 notificationPolicyHash`

### Suggested Audit Settlement Fields

Add to the settlement record:

- `bytes32 ciphertextHash`
- `bytes32 manifestHash`
- `uint8 deliveryMode`
- `uint8 deliveryStatus`

### Suggested Functions

```text
setRequesterDeliveryConfig(bytes pubKey, uint8 deliveryMode, bytes32 notificationPolicyHash)
getRequesterDeliveryConfig(address requester)
recordEncryptedDelivery(uint256 auditId, bytes32 ciphertextHash, bytes32 manifestHash, uint8 deliveryMode)
acknowledgeDelivery(uint256 auditId)
```

`recordEncryptedDelivery(...)` should remain on the high-trust path:

- `onlyTEE`

---

## Worker Module Split

The worker should gain two dedicated modules.

### 1. `delivery.py`

Responsibilities:

- build the review packet,
- compute `receiptHash`, `manifestHash`, `ciphertextHash`,
- encrypt to requester key,
- upload ciphertext,
- return delivery record.

Suggested interface:

```python
def build_review_packet(...) -> dict: ...
def encrypt_review_packet(packet: dict, requester_pubkey: str) -> EncryptedPacket: ...
def upload_encrypted_packet(packet: EncryptedPacket) -> DeliveryHandle: ...
```

### 2. `notify.py`

Responsibilities:

- translate delivery completion into adapter-specific notification payloads,
- send webhook / Signal / Telegram alerts,
- never accept plaintext findings as adapter input.

Suggested interface:

```python
def notify_result_ready(policy: NotificationPolicy, envelope: DeliveryEnvelope) -> None: ...
```

---

## Delivery Flow

### Production Flow

1. worker completes audit inside TEE,
2. worker generates finding/no-finding result packet,
3. worker adds patch and regression evidence when available,
4. worker encrypts packet to requester delivery key,
5. worker uploads ciphertext,
6. worker submits settlement with ciphertext and manifest hashes,
7. worker sends notification with delivery handle only,
8. requester retrieves and decrypts packet off-chain.

### Testnet Compatibility Flow

During migration:

- GitHub PR delivery remains testnet-only,
- encrypted packet generation can run in parallel,
- settlement fields should start carrying real ciphertext hashes before
  GitHub plaintext is removed.

---

## MVP Order

The first implementation should stay narrow.

### Phase A

- support `RequesterOnly` only
- support `webhook` only
- generate encrypted packet
- upload ciphertext to object storage
- store `ciphertextHash` + `manifestHash` on-chain

### Phase B

- add requester acknowledgement
- add packet retrieval helper
- stop treating GitHub PR as the primary production result path

### Phase C

- add Signal / Telegram notification adapters
- add collaborator fan-out
- add `PublicAfterApproval`

---

## Open Questions That Should Stay Open For Now

These do not block MVP encrypted delivery:

- multi-recipient collaborator packet fan-out,
- public disclosure scheduling for open-source repos,
- requester-managed escrow release tied to acknowledgement,
- dispute-time selective plaintext re-exposure inside a fresh verifier TEE.

They should not be solved before the basic requester-only encrypted path exists.

---

## Recommended Next Implementation Step

The next concrete coding step should be:

1. add requester delivery config to `LetheMarket.sol`,
2. add `delivery.py` to the worker,
3. make `submitAuditResult(...)` carry real `ciphertextHash` and `manifestHash`,
4. keep Signal/Telegram out of scope until ciphertext delivery itself works.

This keeps Lethe aligned with its main claim:

> the notification channel may be public, but the vulnerability details are not.
