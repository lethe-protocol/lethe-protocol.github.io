---
title: "PoE Protocol"
---

# LETHE Proof of Erasure v2 (PoE v2) Protocol Specification

**Version**: 2.0
**Date**: 2026-04-01
**Supersedes**: PoE v1 (`docs/poe-protocol.md`) and Memory-PoE v1.1 (Section 9 therein)
**Status**: Phase A — Protocol Specification

---

## 1. Overview

PoE v2 extends the Proof of Erasure protocol from **code-only erasure** (v1) to cover **three distinct erasure types**: code erasure (STANDARD), LLM reasoning trace erasure (MEMORY), and proprietary model weight erasure (ALPHA). The protocol provides cryptographic assurance that sensitive data has been irreversibly destroyed inside a TEE, with optional zkSNARK proofs for O(1) on-chain verification.

```
PoE v1:  Semgrep audit → shred → ECDSA sign → on-chain resolve
PoE v2:  Semgrep audit → shred + memory sanitization + alpha zeroing
         → ECDSA/ZK proof → on-chain resolve (by PoEType)
```

---

## 2. Protocol Modes

PoE v2 supports four erasure modes, selected at audit creation:

```
┌─────────────────────────────────────────────────────────────────┐
│                      PoE v2 Erasure Modes                       │
│                                                                 │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────┐   │
│  │ STANDARD  │  │    ZK     │  │   MEMORY  │  │   ALPHA   │   │
│  │   (v1)   │  │  (v2.0)  │  │  (v1.1)  │  │  (NEW)   │   │
│  └───────────┘  └───────────┘  └───────────┘  └───────────┘   │
│       ↓             ↓              ↓              ↓            │
│  Code shred    + snarkjs PLONK  KV cache +   Model weight     │
│  only          O(1) verify     activation buf  zeroing        │
└─────────────────────────────────────────────────────────────────┘
```

| Mode | PoEType | Erasure Target | Verification | On-Chain Cost |
|------|---------|----------------|--------------|---------------|
| STANDARD | `0` | Source code files | ECDSA sig only | ~50K gas |
| ZK | `1` | Source code + memory | snarkjs PLONK proof | ~300K gas |
| MEMORY | `2` | KV cache, activation buffers, reasoning traces | memCommitment (keccak256) | ~100K gas |
| ALPHA | `3` | Proprietary model weights | alphaCommitment | TBD |

---

## 3. Memory-PoE Mode (Reasoning Trace Erasure)

### 3.1 Motivation

LLM-based audit agents produce intermediate state beyond source code that must be erased:
- **KV Cache**: Key-value attention states encoding all input context
- **Activation Buffers**: Intermediate layer activations during LLM inference
- **Reasoning Traces**: Explicit thought traces, deliberation data, multi-step reasoning outputs

### 3.2 Critical Finding: `sgx_destroy_enclave()` Insufficiency

`sgx_destroy_enclave()` performs `EREMOVE` operations that disconnect EPC pages from the enclave's SECS, but **does NOT explicitly erase memory contents**. Hardware-encrypted memory returns to the untrusted pool without sanitization. Gramine does NOT automatically shred memory — applications MUST explicitly zero sensitive regions before signing.

**Reference**: `broker/tee.py:239-255` — `_perform_multipass_zero()` enforces this.

### 3.3 NIST 800-88 Clear Multi-Pass Zeroing

Memory-PoE applies the NIST 800-88 "Clear" standard via 3-pass overwrite:

```
Pass 1: Write 0x00 to all bytes
Pass 2: Write 0xFF to all bytes
Pass 3: Write 0x00 to all bytes
```

**Reference**: `broker/tee.py:177-232` — `ERASURE_PATTERNS` and `_perform_multipass_zero()`

### 3.4 Token Format Comparison

| Version | Format | Erasure Scope |
|---------|--------|---------------|
| v1 | `poe-{audit_id}-{timestamp}` | Source code only |
| v1.1 | `poe-{audit_id}-{timestamp}-{memCommitment}` | Code + reasoning traces |
| v2 | `poe-{audit_id}-{timestamp}-{memCommitment}-{zkProof}` | Code + reasoning traces + zkSNARK proof |

**Reference**: `broker/tee.py:580-600` — `zero_memory_regions()` and `zero_memory_regions_zk()`

### 3.5 memCommitment Computation

```
memCommitment = keccak256(
    "LETHE_MEMORY_SANITIZED_V1" ||
    region_hash_0 ||
    region_hash_1 ||
    ... ||
    erasure_timestamp
)

region_hash_i = sha256(name_i || address_i || size_i)
```

**Reference**: `broker/tee.py:460-490` — `SensitiveMemoryTracker.get_commitment()`

---

## 4. Alpha-Protection Mode (Model Weight Erasure)

### 4.1 Overview

Alpha-Protection Mode extends PoE to destroy **proprietary model parameters** after inference. Unlike Memory-PoE (which targets LLM intermediate activations), Alpha targets the frozen model weights themselves — the "alphas" representing proprietary trained parameters.

### 4.2 AlphaRegion Tracking (Stub — Not Yet Implemented)

```python
# broker/tee.py (future)
class AlphaMemoryTracker:
    """Tracks model weight regions for Alpha-Protection erasure."""

    def register_alpha_region(self, name: str, address: int, size: int, buffer: object):
        """Register a model weight region (e.g., embedding table, linear layer)."""

    def sanitize(self) -> None:
        """Multi-pass zero model weight regions."""

    def get_alpha_commitment(self, timestamp: str) -> str:
        """Compute keccak256(alpha_sanitized || region_hashes || timestamp)."""
```

### 4.3 Token Format with Alpha

```
PoE_Token_v2_alpha = f"poe-{audit_id}-{timestamp}-{memCommitment}-{alphaCommitment}"
```

### 4.4 Integration Points

| Component | File | Function | Status |
|-----------|------|----------|--------|
| AlphaMemoryTracker | `broker/tee.py` | Class stub | Not implemented |
| alphaCommitment | `broker/tee.py` | `get_alpha_commitment()` | Not implemented |
| resolveAlpha() | `contracts/LetheEscrow.sol` | On-chain verify | Not implemented |

---

## 5. Verified Destruction Market Primitives

PoE v2 enables differentiated market primitives based on erasure type:

| Primitive | Use Case | PoEType Required |
|-----------|----------|-----------------|
| **Code Audit** | Standard security audit | STANDARD or ZK |
| **LLM Reasoning Market** | Causal model prediction markets (Volva Phase 6) | MEMORY or ZK |
| **Model Serving** | Confidential inference with erasure guarantee | ALPHA |
| **Hybrid Audit** | Code + reasoning trace + model weights | ZK |

**Reference**: `docs/zkpoe-v2-implementation-report.md` — zkPoE v2 architecture diagram

---

## 6. Cryptographic Flow

### 6.1 Full PoE v2 Signing Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    TEE Enclave                               │
│                                                              │
│  Source Code → Semgrep → Findings                            │
│       ↓                                                      │
│  SensitiveMemoryTracker: register kv_cache, activations      │
│       ↓                                                      │
│  NIST 800-88 Clear: multi-pass zero                         │
│       ↓                                                      │
│  SensitiveMemoryTracker.sanitize() → memCommitment           │
│       ↓                                                      │
│  ZeroKnowledgeProof.generate_live_proof() → zkProof         │
│       (snarkjs PLONK, ~10KB, <1s generation)                 │
│       ↓                                                      │
│  Build PoE_Token_v2 = {                                      │
│    "token": "poe-{audit_id}-{timestamp}",                   │
│    "mem_commitment": "0x{a3f2...}",                         │
│    "zk_proof": {proof, public_signals, proof_type}          │
│  }                                                           │
│       ↓                                                      │
│  ECDSA_Sign(Broker_SK, keccak256(auditId || poeHash ||      │
│              memCommitment || zkProof))                      │
└──────────────────────────────────────────────────────────────┘
                              ↓
                    On-Chain LetheEscrow
                              ↓
              resolve(auditId, poeHash, signature)  [STANDARD]
              resolveZk(auditId, poeHash, zkProof) [ZK/MEMORY]
```

### 6.2 PoE Token v2 Structure

```python
PoE_Token_v2 = {
    "token": "poe-{audit_id}-{YYYYMMDDHHMMSSffffff}",
    "mem_commitment": "0x{a3f2e8d1b7c4...}",  # keccak256 from v1.1
    "zk_proof": {
        "proof": "0x{64-byte-groth16-placeholder}",  # ~10KB snarkjs proof
        "public_signals": ["0x{memCommitment}", "20260401120000000000", 3],
        "proof_type": "groth16",
        "is_simulated": False  # True if snarkjs unavailable
    },
    # Future (Alpha-Protection):
    # "alpha_commitment": "0x{...}"
}
```

**Reference**: `broker/tee.py:580-650` — `zero_memory_regions_zk()` return structure

### 6.3 ECDSA Signature Payload

```
Message_v2 = keccak256(abi.encodePacked(
    uint256(auditId), bytes32(poeHash), bytes32(memCommitment),
    bytes(zkProof.proof), bytes32(zkProof.public_signals[0])))
EthMessage = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", Message_v2))
Signature = ECDSA_Sign(Broker_SK, EthMessage)
```

**Reference**: `broker/main.py:_sign_proof()`

---

## 7. Threat Model

PoE v2 prevents attacks that v1 cannot address:

| Attack | v1 | v2 | Mitigation |
|--------|----|----|------------|
| Source code extraction | ✅ | ✅ | NIST 800-88 multi-pass shred |
| Memory dump post-enclave | ❌ | ✅ | `sgx_destroy_enclave()` + explicit zero |
| KV cache reuse | ❌ | ✅ | `SensitiveMemoryTracker.sanitize()` |
| Reasoning trace leakage | ❌ | ✅ | `memCommitment` + zkSNARK proof |
| Model weight extraction | ❌ | ✅ (stub) | `AlphaMemoryTracker` (future) |

**v1 does NOT cover**: LLM reasoning traces (KV cache), activation buffers, model weights (alphas), or EPC memory reuse after enclave exit (`sgx_destroy_enclave()` does not wipe pages — see `docs/poe-protocol.md:9.2`).

---

## 8. Integration Points

| File | Component | Lines | Purpose |
|------|-----------|-------|---------|
| `broker/tee.py` | `SensitiveMemoryTracker` | 290-490 | Track and sanitize memory regions |
| `broker/tee.py` | `_perform_multipass_zero()` | 177-232 | NIST 800-88 3-pass overwrite |
| `broker/tee.py` | `zero_memory_regions()` | 550-580 | Memory-PoE entry point |
| `broker/tee.py` | `zero_memory_regions_zk()` | 600-650 | Memory-PoE v2 with zkProof |
| `broker/tee.py` | `ZeroKnowledgeProof` | 689-1248 | snarkjs PLONK proof generation |
| `broker/tee.py` | `generate_live_proof()` | 960-1050 | Live snarkjs proof (fallback: mock) |
| `broker/main.py` | `_sign_proof()` | ~350 | ECDSA signature generation |
| `broker/main.py` | `_run_audit_inline()` | ~200 | Audit + PoE generation |
| `broker/main.py` | Memory-PoE call | ~220 | `tee.zero_memory_regions()` before sign |
| `contracts/LetheEscrow.sol` | `resolve()` | ~45 | ECDSA-based verification |
| `contracts/LetheEscrow.sol` | `resolveZk()` | ~70 | ZK proof verification (stub) |
| `contracts/LetheEscrow.sol` | `Audit` struct | ~15 | On-chain audit state |

---

## 9. On-Chain Verification

**PoEType Enum** (proposed update for `LetheEscrow.sol`):
```solidity
enum PoEType { STANDARD=0, ZK=1, MEMORY=2, ALPHA=3 }
```

**Verification Dispatch**:
```solidity
function resolvePoE(uint256 _auditId, bytes32 _poeHash, bytes calldata _sig, PoEType _t) external {
    if (_t == PoEType.STANDARD) resolve(_auditId, _poeHash, _sig);
    else resolveZk(_auditId, _poeHash, ZkProof({...}));  // ZK, MEMORY, ALPHA
}
```

**Gas Cost Comparison**:

| Version | Verification | Complexity | Gas |
|---------|--------------|------------|-----|
| v1 (ECDSA) | Recover signer | O(1) | ~50K |
| v1.1 (keccak256) | Recompute region hashes | O(n) | ~100K |
| v2 (zkSNARK) | Verify PLONK proof | O(1) | ~300K |

---

## 10. Related Documents & History

| File | Purpose |
|------|---------|
| `docs/poe-protocol.md` | PoE v1 spec (Sections 3-4 superseded) |
| `docs/moat/poe_protocol.md` | Extended threat model analysis |
| `docs/zkpoe-v2-implementation-report.md` | zkPoE v2 implementation details |
| `broker/tee.py:290-650` | `SensitiveMemoryTracker`, `zero_memory_regions[_zk]()` |
| `broker/tee.py:689-1248` | `ZeroKnowledgeProof` class |
| `broker/main.py` | `_sign_proof()`, `_run_audit_inline()` |
| `contracts/LetheEscrow.sol` | `resolve()`, `resolveZk()` (stub) |
| `tests/test_memory_poe.py` | Memory-PoE v1.1 tests (14 tests) |
| `tests/test_zkpoe_v2.py` | zkPoE v2 tests (41 tests) |
