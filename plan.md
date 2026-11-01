# AirCrypt Secure Transfer Implementation Plan

## 0. Purpose

This plan defines the implementation of end-to-end file encryption and integrity protection for AirCrypt.

The implementation target is the existing Flutter/Dart AirCrypt codebase. The agent must first review the complete existing codebase and understand the current transfer/protocol flow before modifying production code.

The implementation requested by the project owner is:

1. AES-256-GCM encryption for every file chunk.
2. A fresh AES-256 session key for every transfer.
3. A fresh RSA-2048 key pair for every transfer.
4. RSA-OAEP using SHA-256 to protect the AES session key.
5. A SHA-256 checksum for every encrypted chunk.
6. Receiver-side checksum verification before decryption/acceptance.
7. Reverse workflow for decryption and reconstruction.
8. Cryptographic implementation in the project code itself; no cloud/API/online cryptography service and no third-party cryptography package.
9. A separate critic-agent review after implementation.
10. `plan.md` is the persistent implementation log and must be updated throughout the work.

The existing AirCrypt SRS specifies AES-256, RSA-2048, SHA-256, chunked transfer, integrity verification, and reverse receiver-side processing. This plan deliberately updates the AES mode to AES-256-GCM and RSA padding to RSA-OAEP-SHA256 according to the owner's clarified requirements.

---

## 1. Non-negotiable constraints

### 1.1 Cryptography

The following algorithms and parameters are fixed:

- AES-256-GCM
  - 256-bit AES key.
  - Independent GCM nonce/IV for every encrypted chunk.
  - Never reuse the same `(AES key, nonce)` pair.
  - Authentication tag must be preserved and transmitted with the chunk.
- RSA-2048
  - Fresh key pair for every transfer.
  - RSA-OAEP.
  - OAEP hash: SHA-256.
  - MGF1 hash: SHA-256.
- SHA-256
  - Compute over the complete transmitted encrypted-chunk representation selected by the protocol.
  - The receiver recomputes the SHA-256 value before accepting/decrypting a chunk.
- Cryptographic randomness must come from a secure OS-backed randomness source available to the Dart/Flutter application.
- No hard-coded keys.
- No fixed IV/nonces.
- No reuse of session keys between transfers.
- No plaintext AES key on the network.

### 1.2 No online/third-party cryptography

Do not use:

- Cloud cryptography APIs.
- Web APIs for encryption.
- Remote key-generation services.
- Online hashing services.
- Third-party cryptography packages.

Existing non-cryptographic project dependencies may remain unless the agent discovers that a dependency is specifically performing the cryptographic operations.

The cryptographic primitives must be implemented locally in project code.

### 1.3 Important engineering rule

Do NOT implement cryptographic primitives from memory without standards-based tests.

The agent must implement and test against published/standard test vectors for:

- SHA-256
- AES
- GCM
- RSA
- RSA-OAEP
- MGF1
- modular arithmetic/primality routines used by RSA generation

If a primitive cannot be implemented and verified correctly, the agent must stop and record the issue in `plan.md` rather than silently shipping an unverified implementation.

---

## 2. Existing project review required before implementation

Before modifying code, the implementation agent must inspect all relevant Dart code, not only the currently visible TCP files.

At minimum review:

```text
lib/main.dart

lib/core/
  database/
  models/
  services/
  security/

lib/features/files/
lib/features/history/
lib/features/settings/
lib/features/trash/

lib/features/transfer/
  connection/
  finder/
  protocol/
  incoming_message.dart
  tcp_client.dart
  tcp_connection.dart
  tcp_receiver_screen.dart
  tcp_sender_screen.dart
  tcp_server.dart

pubspec.yaml
```

Also inspect:

- Android/iOS configuration only where required for secure randomness, file I/O, or platform constraints.
- Existing tests.
- Existing README/project documentation if present.
- Existing Git history/branches if available locally.

### Review objective

Trace the real data flow:

```text
UI
 ↓
file selection
 ↓
transfer request
 ↓
ProtocolMessage
 ↓
ProtocolEncoder
 ↓
TCP
 ↓
ProtocolStreamParser
 ↓
ProtocolMessage
 ↓
receiver
 ↓
chunk verification
 ↓
decryption
 ↓
file reconstruction
```

The agent must identify the actual production path rather than assuming that `tcp_client.dart` itself is the file-transfer layer.

---

## 3. Current-code findings that must be verified during review

The supplied code snapshot currently contains a protocol abstraction with:

```text
ProtocolMessage
ProtocolEncoder
ProtocolDecoder
ProtocolStreamParser
MessageType
ChunkMetadata
FileMetadata
TransferMetadata
TransferRequest
```

The current `TcpClient.sendMessage()` encodes a `ProtocolMessage` and writes the encoded bytes to the socket.

Therefore:

- Do not put encryption blindly inside `TcpClient.sendMessage()`.
- Encryption must occur at the file/chunk security boundary before the encrypted chunk becomes a protocol payload.
- The protocol must be extended in a backward-consistent way to carry security metadata.

The supplied snapshot also contains a file named:

```text
lib/core/security/encryption
```

whose current contents appear to be copied TCP-client code rather than a cryptographic implementation.

The agent must inspect this and replace/fix it as part of the security-layer cleanup.

The current discovery implementation broadcasts:

```text
magic
device id
device name
tcp port
```

and does not currently advertise an RSA public key. The agent must therefore design the RSA public-key availability/handshake correctly rather than assuming it already exists.

The current protocol `MessageType` already has handshake, verification challenge/response, transfer request, metadata, chunk, acknowledgement, and retransmission message types. Reuse those existing concepts where possible instead of creating unnecessary duplicate message types.

---

## 4. Required security architecture

Recommended structure:

```text
lib/
└── core/
    └── security/
        ├── aes_gcm.dart
        ├── rsa.dart
        ├── rsa_oaep.dart
        ├── sha256.dart
        ├── gcm.dart
        ├── secure_random.dart
        ├── key_generation.dart
        ├── key_exchange.dart
        ├── secure_chunk.dart
        ├── security_exceptions.dart
        └── encryption_service.dart
```

The exact file split may be changed by the implementation agent if the existing architecture supports a cleaner structure, but the responsibilities must remain separated.

### Responsibilities

#### `secure_random.dart`

Provide cryptographically secure random bytes required for:

- AES keys.
- GCM nonces.
- RSA prime generation.
- OAEP randomness.
- Any protocol challenges.

Do not use predictable PRNGs such as `Random()` for cryptographic material.

#### `sha256.dart`

Implement SHA-256 locally.

Must expose a clean API suitable for:

```text
digest(bytes) -> 32 bytes
```

and have known-answer tests.

#### `aes_gcm.dart` / `gcm.dart`

Implement:

- AES-256 key schedule.
- AES block encryption.
- GCM GHASH.
- GCM counter construction.
- GCM authentication tag.
- Encrypt/decrypt operations.

The implementation must reject invalid authentication tags.

#### `rsa.dart`

Implement:

- RSA-2048 key-pair generation.
- Big-integer modular arithmetic using Dart's supported arbitrary-precision integer type.
- Probable-prime generation.
- Miller-Rabin or another standards-appropriate primality test with sufficient rounds.
- Modular inverse.
- RSA public/private operations.

The agent must document the exact primality/randomness approach.

#### `rsa_oaep.dart`

Implement:

- OAEP encoding.
- OAEP decoding.
- MGF1 using SHA-256.
- RSA-OAEP-SHA256 encryption/decryption.

The implementation must enforce RSA-OAEP size limits. The AES-256 key is only 32 bytes, so it fits comfortably in RSA-2048 OAEP-SHA256.

#### `key_generation.dart`

Expose high-level APIs:

```text
generateAes256Key()
generateRsa2048KeyPair()
```

and ensure every transfer gets fresh keys.

#### `key_exchange.dart`

Handle:

```text
receiver RSA public key
sender AES-256 session key
RSA-OAEP-SHA256 encrypted AES key
receiver RSA private key
```

#### `secure_chunk.dart`

Represent a secure chunk containing at minimum:

```text
transferId
fileId
chunkIndex
totalChunks
plaintextLength (if needed)
ciphertext
gcmNonce
gcmTag
sha256
```

Do not include the plaintext chunk in the secure packet.

---

## 5. Critical key-exchange issue to solve

The requirement says:

- A fresh RSA-2048 pair is generated for every transfer.
- The sender encrypts the AES session key using the receiver's RSA public key.
- The encrypted AES key is included in the transfer request.

Therefore the receiver's fresh RSA public key must be available to the sender BEFORE the sender sends the transfer request containing the wrapped AES key.

The agent must explicitly design and document this sequence.

Preferred sequence:

```text
1. Receiver becomes available for a transfer.
2. Receiver creates a fresh RSA-2048 key pair for the pending transfer/session.
3. Receiver makes the public key available to the sender through the existing secure connection/handshake.
4. Sender validates the protocol context.
5. Sender generates a fresh AES-256 key.
6. Sender encrypts AES key with receiver RSA public key using RSA-OAEP-SHA256.
7. Sender places the RSA-wrapped AES key in the transfer request.
8. Receiver accepts request.
9. Sender begins encrypted chunk transfer.
10. Receiver uses its RSA private key to recover the AES session key.
11. RSA private key and AES session key are discarded after transfer completion/failure.
```

If the existing UI requires the transfer request before the receiver has a key, the agent must adapt the handshake rather than violating the requirement.

Do NOT simply broadcast one RSA public key permanently if doing so causes the same key pair to be reused across transfers.

---

## 6. AES-256-GCM chunk workflow

For every plaintext chunk:

```text
plaintext chunk
      ↓
generate fresh 96-bit GCM nonce
      ↓
AES-256-GCM encrypt
      ↓
ciphertext + 128-bit authentication tag
      ↓
construct secure chunk representation
      ↓
SHA-256 of the transmitted encrypted representation
      ↓
ProtocolMessage(chunk)
      ↓
TCP
```

Recommended nonce size:

```text
96 bits / 12 bytes
```

Recommended GCM tag size:

```text
128 bits / 16 bytes
```

The implementation must never reuse a nonce with the same AES key.

### Associated data

The implementation should bind protocol metadata to GCM authentication as Additional Authenticated Data (AAD), where practical.

Recommended AAD fields:

```text
protocol version
transferId
fileId
chunkIndex
totalChunks
```

This prevents an encrypted chunk from being moved to a different transfer/file/chunk position without authentication failure.

The exact canonical byte encoding of AAD must be specified and tested.

---

## 7. SHA-256 checksum workflow

The requested checksum is computed for each encrypted chunk.

Recommended canonical representation:

```text
secureChunkBytes =
    version
    + transferId
    + fileId
    + chunkIndex
    + totalChunks
    + nonce
    + ciphertext
    + gcmTag
```

Then:

```text
sha256 = SHA256(secureChunkBytes)
```

The protocol sends the checksum alongside the secure chunk.

Receiver:

```text
receive secure chunk
       ↓
reconstruct canonical secureChunkBytes
       ↓
calculate SHA-256
       ↓
compare against transmitted SHA-256
       ↓
MATCH ───────────────→ continue
MISMATCH ────────────→ reject + retransmission request
```

Important:

- Compare digests in constant-time where practical.
- Do not decrypt a chunk whose SHA-256 verification failed.
- Do not write failed chunks to storage.
- Do not treat SHA-256 alone as proof of sender identity.

---

## 8. Authentication clarification

SHA-256 provides integrity detection when compared against a trusted expected digest, but an unauthenticated hash sent alongside attacker-controlled ciphertext is not a cryptographic authentication mechanism.

Therefore the implementation must distinguish:

### Integrity

```text
SHA-256(encrypted chunk)
```

detects accidental corruption and modifications when the expected digest is trusted.

### Encryption authenticity

AES-GCM's authentication tag detects unauthorized modification of the ciphertext/AAD under the session key.

### Identity authentication

RSA encryption and SHA-256 alone do NOT establish that a particular human/device is the legitimate sender.

The current project requirements do not define a persistent trusted identity/PKI.

Therefore:

- Implement SHA-256 + AES-GCM authentication/integrity as required.
- Do not claim that SHA-256 alone authenticates the sender.
- If the existing handshake already supports a verification challenge/response, inspect and reuse it where appropriate.
- If adding RSA-PSS signatures is considered, document it as an explicit extension requiring a trust model; do not silently claim that an ephemeral public key proves device identity.

---

## 9. Transfer-request changes

The transfer request must be extended to carry the RSA-protected AES session key.

At minimum, the request security fields should include:

```text
keyExchangeVersion
rsaAlgorithm = RSA-2048-OAEP-SHA256
encryptedAesKey
```

If required by the handshake:

```text
receiverPublicKeyFingerprint
keyId / transferKeyId
```

Do not send the raw AES key.

The receiver must reject:

- malformed encrypted AES keys.
- unsupported algorithm versions.
- invalid RSA ciphertext.
- wrong key length.
- unexpected transfer/key identifiers.

---

## 10. Protocol changes

The agent must inspect existing protocol framing before modifying it.

Potential changes:

### `TransferRequest`

Add encrypted AES key/security metadata.

### `ChunkMetadata`

Add or reference:

```text
nonce
authenticationTag
sha256
```

Do not duplicate data unnecessarily.

### Chunk payload

Keep binary data binary. Avoid converting encrypted bytes to UTF-8 strings.

If the current JSON payload wrapper requires text, use an explicitly defined binary-safe encoding such as base64 only where necessary and document the performance/memory implications.

Prefer a binary payload for large encrypted chunks if the existing protocol architecture permits it.

---

## 11. Chunking decision

The project documentation currently describes 64 KB chunks.

The implementation must determine whether the existing file handling already chunks data.

Required behavior:

```text
plaintext file
 ↓
read 64 KB
 ↓
AES-GCM encrypt that chunk
 ↓
SHA-256 secure representation
 ↓
send
 ↓
next chunk
```

Do NOT load an entire multi-GB file into memory merely to encrypt it.

The implementation must be streaming/chunk-oriented.

---

## 12. Receiver workflow

Receiver must implement:

```text
receive transfer request
      ↓
validate request
      ↓
recover AES key with RSA private key
      ↓
wait for encrypted chunks
      ↓
receive chunk
      ↓
validate protocol metadata
      ↓
verify SHA-256
      ↓
AES-GCM decrypt + verify GCM tag
      ↓
write/reassemble plaintext chunk
      ↓
ACK
      ↓
next chunk
```

If either:

```text
SHA-256 mismatch
```

or:

```text
GCM authentication-tag failure
```

occurs:

```text
do not write plaintext
do not ACK as successful
request retransmission
record error
```

---

## 13. Retransmission interaction

The agent must preserve the existing chunk acknowledgement/retransmission semantics.

A failed chunk must be retransmitted without generating an inconsistent protocol state.

For a retransmission:

- The sender may resend the exact same secure chunk bytes, including the same nonce, ciphertext, tag, and digest, because it is the same already-created ciphertext packet.
- Do NOT re-encrypt the same plaintext chunk with the same nonce.
- If a new encryption operation is performed, a new nonce must be generated and the resulting secure chunk must replace the old packet consistently.

The agent must inspect the existing `chunkAck` and `chunkRetransmit` behavior before changing it.

---

## 14. Key lifecycle

### Sender

```text
generate AES key
 ↓
wrap with receiver RSA public key
 ↓
use AES during transfer
 ↓
zero/dispose sensitive buffers where practical
 ↓
discard AES key
```

### Receiver

```text
generate RSA key pair
 ↓
private key retained only for transfer
 ↓
unwrap AES key
 ↓
decrypt chunks
 ↓
discard AES key
 ↓
discard RSA private key
```

Do not persist session keys to SQLite, files, SharedPreferences, logs, crash messages, or UI.

Do not print keys, plaintext, ciphertext, nonces, or private RSA parameters in debug logs.

---

## 15. Secure logging rules

`plan.md` may contain implementation status, but source-code logs must NEVER contain:

- AES keys
- RSA private keys
- RSA CRT parameters
- plaintext file data
- full encrypted payloads
- authentication secrets

Safe logs may contain:

```text
transfer ID
file ID
chunk index
total chunks
algorithm/version identifiers
success/failure
error category
timings
```

Even hashes should not be logged unnecessarily.

---

## 16. Testing requirements

The agent must create automated unit tests before claiming completion.

### SHA-256

Use published known-answer vectors.

Test:

- empty input
- `abc`
- long known input
- binary data

### AES

Use published AES-256 test vectors.

Test:

- block encryption primitive
- key schedule
- known plaintext/ciphertext

### GCM

Use published NIST GCM vectors.

Test:

- AES-256-GCM encryption
- decryption
- authentication tag
- modified ciphertext rejection
- modified tag rejection
- modified AAD rejection
- nonce handling

### RSA

Use published RSA/OAEP vectors where applicable.

Test:

- RSA-2048 key generation
- encrypt/decrypt
- OAEP-SHA256
- MGF1-SHA256
- malformed ciphertext rejection

### Integration

Test:

```text
file
 → chunk
 → AES-GCM
 → SHA-256
 → protocol
 → receive
 → SHA-256 verify
 → AES-GCM verify/decrypt
 → reconstructed file
```

Compare original and reconstructed files byte-for-byte.

Test:

- empty file
- tiny file
- exactly 64 KB
- 64 KB + 1 byte
- multiple chunks
- large file
- binary files
- image
- PDF
- MP3/MP4
- corrupted ciphertext
- corrupted SHA
- corrupted GCM tag
- wrong RSA private key
- wrong AES key
- dropped/retransmitted chunk
- reordered/duplicate chunk if the protocol can encounter it
- interrupted TCP connection
- multiple transfers
- two sequential transfers proving keys are not reused.

---

## 17. Security tests

The critic agent must specifically attempt to break:

### Replay

Attempt to reuse a chunk from another transfer.

Expected:

```text
reject
```

### Chunk swapping

Move chunk N to chunk M.

Expected:

```text
GCM/AAD or protocol validation rejects it.
```

### Cross-file substitution

Use a valid encrypted chunk from another file.

Expected:

```text
reject
```

### Ciphertext modification

Modify one byte.

Expected:

```text
SHA mismatch and/or GCM authentication failure.
```

### Tag modification

Modify the GCM tag.

Expected:

```text
decrypt fails.
```

### SHA modification

Modify only the transmitted SHA value.

Expected:

```text
digest mismatch.
```

### RSA ciphertext modification

Modify wrapped AES key.

Expected:

```text
RSA-OAEP decryption fails.
```

### Wrong receiver private key

Expected:

```text
AES key recovery fails.
```

### Nonce reuse

Instrument/test the encryption service to prove it does not reuse a nonce under the same AES session key.

---

## 18. Agent implementation phases

### Phase 0 — Repository review

DO NOT modify production code.

Tasks:

- Inspect complete codebase.
- Identify all transfer entry points.
- Trace sender path.
- Trace receiver path.
- Trace protocol serialization.
- Trace file chunking/reassembly.
- Trace ACK/retransmission.
- Trace discovery/handshake.
- Inspect current security folder.
- Identify existing tests.
- Identify current compile/runtime problems.

Update `plan.md` with:

```text
REVIEW START
timestamp
files reviewed
architecture findings
existing bugs
integration points
open risks
```

Only after this review may implementation begin.

---

### Phase 1 — Cryptographic primitives

Implement and test:

```text
secure_random
SHA-256
AES-256
GCM
RSA-2048
OAEP-SHA256
MGF1-SHA256
```

No network/UI changes yet.

All known-answer tests must pass.

---

### Phase 2 — Security abstractions

Implement:

```text
Aes256GcmService
Rsa2048KeyGenerator
RsaOaepSha256
Sha256Service
SecureChunk
KeyExchangeService
```

Keep cryptographic primitives separated from transfer/protocol code.

---

### Phase 3 — Key exchange integration

Implement the per-transfer RSA key lifecycle and ensure the receiver's public key is available before the sender constructs the transfer request containing the wrapped AES key.

Document the exact handshake.

---

### Phase 4 — Protocol integration

Modify:

```text
TransferRequest
ChunkMetadata
ProtocolMessage
ProtocolEncoder/Decoder
```

only where required.

Preserve protocol framing and compatibility.

Update protocol version if the wire format changes incompatibly.

---

### Phase 5 — Sender integration

Implement:

```text
file chunk
 ↓
AES-256-GCM
 ↓
SHA-256
 ↓
secure chunk
 ↓
ProtocolMessage
 ↓
TCP
```

Ensure no plaintext file chunk is sent.

---

### Phase 6 — Receiver integration

Implement:

```text
ProtocolMessage
 ↓
secure chunk
 ↓
SHA-256 verify
 ↓
GCM verify/decrypt
 ↓
file reconstruction
```

Reject invalid chunks before writing them.

---

### Phase 7 — Retransmission integration

Preserve existing ACK/retransmission behavior.

Test corrupted and missing chunks.

---

### Phase 8 — End-to-end testing

Run unit + integration + security tests.

Test on:

```text
Android device A
       ↓ Wi-Fi
Android device B
```

and confirm the actual saved file is byte-for-byte identical.

---

## 19. Critic-agent workflow

A separate critic agent must review the implementation after the implementation agent finishes each major phase.

### Critic responsibilities

The critic must:

1. Read the current `plan.md`.
2. Inspect all changed files.
3. Inspect relevant unchanged protocol/networking code.
4. Run tests/static analysis where available.
5. Look specifically for:
   - incorrect cryptographic algorithms
   - incorrect AES-GCM usage
   - nonce reuse
   - incorrect RSA-OAEP implementation
   - weak randomness
   - RSA key lifecycle errors
   - SHA-256 misuse
   - plaintext leakage
   - key leakage
   - protocol framing errors
   - chunk ordering errors
   - retransmission bugs
   - memory problems
   - malformed packet handling
   - integer/length overflow issues
   - file corruption
   - compatibility problems
   - missing test vectors
   - logging of sensitive data

### Critic result

The critic must append:

```text
CRITIC REVIEW
timestamp

Findings:
- [CRITICAL] ...
- [HIGH] ...
- [MEDIUM] ...
- [LOW] ...

Required fixes:
1. ...
2. ...

Tests performed:
- ...

Verdict:
PASS / FAIL
```

The critic must not directly modify production code unless explicitly instructed.

---

## 20. Fix-and-review loop

If critic verdict is FAIL:

```text
critic
 ↓
findings
 ↓
implementation agent
 ↓
fixes
 ↓
tests
 ↓
critic again
```

Repeat until:

```text
CRITIC VERDICT: PASS
```

The implementation agent must not mark the feature complete while critical/high unresolved findings remain.

---

## 21. `plan.md` logging format

Every agent run must append to the appropriate section.

Use:

```markdown
## Agent Log

### [timestamp] Implementation Agent

Action:
Files changed:
Reason:
Tests:
Result:
Next step:
```

For critic:

```markdown
### [timestamp] Critic Agent

Scope:
Files reviewed:
Tests run:
Findings:
Severity:
Required fixes:
Verdict:
```

Do not overwrite historical logs.

---

## 22. Definition of done

The feature is complete only when all are true:

- [ ] Repository review completed.
- [ ] Existing transfer flow documented.
- [ ] SHA-256 implementation passes known-answer tests.
- [ ] AES-256 implementation passes known-answer tests.
- [ ] AES-256-GCM passes published test vectors.
- [ ] RSA-2048 key generation works.
- [ ] RSA-OAEP-SHA256 passes test vectors.
- [ ] Fresh RSA key pair is used per transfer.
- [ ] Fresh AES-256 key is used per transfer.
- [ ] Fresh GCM nonce is used per encrypted chunk.
- [ ] AES key is RSA-OAEP-SHA256 wrapped.
- [ ] Wrapped AES key is included in the transfer request.
- [ ] SHA-256 is included for every encrypted chunk.
- [ ] Receiver verifies SHA before accepting/decrypting.
- [ ] Receiver verifies GCM authentication tag.
- [ ] Failed chunks are retransmitted.
- [ ] No plaintext file data travels over TCP.
- [ ] Session keys are not persisted.
- [ ] Private RSA keys are not transmitted.
- [ ] Sensitive material is not logged.
- [ ] Original/reconstructed files are byte-for-byte identical.
- [ ] Corruption tests pass.
- [ ] Wrong-key tests pass.
- [ ] Replay/cross-transfer tests pass.
- [ ] Android-to-Android end-to-end test passes.
- [ ] Critic agent gives PASS.
- [ ] `plan.md` contains complete implementation and critic history.

---

## 23. Important architectural/security notes

1. AES-GCM already provides authenticated encryption. SHA-256 is retained because it is an explicit project requirement for per-chunk verification and retransmission diagnostics.
2. SHA-256 by itself is not a sender-authentication mechanism.
3. RSA-OAEP is for protecting the AES session key; it is not a signature scheme.
4. A fresh RSA key pair per transfer requires an explicit handshake/public-key-delivery design. Do not silently reuse a long-lived receiver RSA key.
5. If the project needs persistent device identity authentication, that is a separate trust-model feature and must not be falsely implied by an ephemeral RSA key.
6. Never invent cryptographic shortcuts to make the implementation easier.
7. Never substitute AES-CBC, ECB, RSA-PKCS#1 v1.5, or a non-cryptographic PRNG.
8. Do not send cryptographic secrets through logs, analytics, URLs, cloud services, or external APIs.

---

## 24. Final expected flow

### Sender

```text
Select file
    ↓
Receiver public RSA-2048 key available through handshake
    ↓
Generate fresh AES-256 session key
    ↓
RSA-OAEP-SHA256 encrypt AES key
    ↓
Put wrapped AES key into transfer request
    ↓
Receiver accepts
    ↓
Read next file chunk
    ↓
Generate fresh GCM nonce
    ↓
AES-256-GCM encrypt
    ↓
Compute SHA-256 of canonical encrypted chunk representation
    ↓
Send secure chunk
    ↓
Wait for ACK
    ↓
Retransmit if required
    ↓
Next chunk
    ↓
Discard AES/RSA private material after transfer
```

### Receiver

```text
Receive transfer request
    ↓
Recover AES key using fresh RSA-2048 private key
    ↓
Receive encrypted chunk
    ↓
Validate chunk metadata
    ↓
Recompute SHA-256
    ↓
Compare SHA-256
    ↓
If mismatch → reject/retransmit
    ↓
If match → AES-256-GCM decrypt + verify tag
    ↓
Write/reassemble plaintext chunk
    ↓
ACK
    ↓
Next chunk
    ↓
Verify final file
    ↓
Discard session cryptographic material
```

---

## 25. First instruction to the implementation agent

DO NOT START CODING IMMEDIATELY.

First:

1. Read this entire `plan.md`.
2. Read the complete AirCrypt repository.
3. Trace the actual sender and receiver transfer pipeline.
4. Compare the implementation against the SRS and methodology.
5. Identify where the existing implementation differs from the desired security workflow.
6. Record the findings in `plan.md`.
7. Identify any blocking ambiguity or architectural conflict.
8. Only then begin implementation.

If a requirement cannot be implemented safely without making an unstated cryptographic decision, STOP and record the issue in `plan.md` rather than guessing.

## REVIEW START

- Timestamp: 2026-10-02T00:00:00Z
- Files reviewed: `pubspec.yaml`, `README.md`, `lib/main.dart`, `lib/core/database/*`, `lib/core/models/*`, `lib/core/services/*`, `lib/features/transfer/*`, `lib/features/transfer/finder/*`, `lib/features/transfer/manager/*`, `lib/features/transfer/protocol/*`, `lib/features/transfer/io/*`, and the existing tests under `test/`.
- Architecture findings:
  - The real file-transfer pipeline is `DeviceScreen._startTransfer()` → `TransferSender.sendTransfer()` → `ProtocolMessage` payloads → `TcpClient.sendMessage()` → receiver-side `TransferReceiver.handleMessage()` → `ChunkWriter` finalization.
  - The current protocol uses a custom binary header (`ProtocolEncoder` / `ProtocolDecoder`) with `MessageType` values for HELLO, transfer request, metadata, file start, chunk, transfer accept/reject, complete, and failure.
  - The wire format is plain JSON for metadata and request payloads, and the chunk payload is a JSON wrapper with a 4-byte metadata-length prefix plus raw segment bytes. There is no encrypted payload boundary, no nonce, no GCM tag, and no per-chunk SHA-256 or RSA-wrapped AES key.
  - Discovery broadcasts only `magic`, `id`, `name`, and `port` via `UdpDiscoveryService`; no receiver RSA public key is announced or negotiated.
  - The app has no `lib/core/security` implementation at present, and no secure-randomness, SHA-256, AES-GCM, or RSA/OAEP code exists in the project.
  - The transfer request currently contains only transfer metadata, not a wrapped session key, so the current design violates the requirement for a fresh AES session key protected by a fresh receiver RSA key per transfer.
- Existing bugs observed:
  - `flutter test --reporter compact` currently fails in `test/file_transfer_end_to_end_test.dart` with a truncated output at the 196608-byte boundary, indicating a file reconstruction/counting mismatch in the chunk transfer path.
  - The same test suite triggers a `DatabaseException(error database_closed)` after the end-to-end transfer completes because the repository/database lifecycle is being closed while async transfer completion logic still updates repository status.
  - `TransferReceiver.handleMessage()` updates transfer state and finalizes files without explicit integrity checking for chunk corruption; it trusts raw `ChunkPayload` data as valid before writing to disk.
  - `TransferSender.sendTransfer()` sends raw plaintext file chunks directly as `ChunkPayload.data` without any encryption or checksum step.
- Integration points and required security insertion points:
  - `TransferRequest` is the correct place to include an RSA-wrapped AES session key and key-exchange metadata before the sender begins sending file chunks.
  - `ChunkMetadata` and `ChunkPayload` are the correct boundary to attach nonce, GCM tag, and SHA-256 digest for each encrypted chunk.
  - `TransferSender.sendTransfer()` is the sender-side security boundary. Encryption must happen there per-file-chunk just before the `ProtocolMessage(type: MessageType.chunk, payload: ...)` is emitted.
  - `TransferReceiver.handleMessage()` is the receiver-side verification boundary. It must verify the digest before any decryption, then validate the GCM tag before writing the plaintext chunk to disk.
  - The current discovery/handshake sequence must be extended so the receiver generates a fresh per-transfer RSA key pair and exposes the public key before the sender sends a transfer request carrying the wrapped AES session key.
- Open risks:
  - The project currently has no cryptographic primitive implementation or tests, so the implementation will need a new security layer and standard test vectors before network/UI integration.
  - Any new key exchange must avoid reusing a long-lived RSA key pair, because that would violate the one-transfer-one-key requirement.
  - A safe and reversible protocol extension is needed to preserve the existing `MessageType` flow while adding key metadata and secure chunk metadata without breaking the current framing rules.

## Agent Log

### 2026-10-02T00:00:00Z Implementation Agent

Action:

- Performed the required repository review before any production code changes.
- Traced the sender and receiver flow from UI selection through `TransferSender`, `TransferReceiver`, protocol framing, TCP transport, and chunk assembly.
- Confirmed that no existing cryptographic security layer, key exchange, or integrity checks are implemented.

Files changed:

- `plan.md`

Reason:

- Required by Phase 0 in the implementation plan before any security implementation starts.

Tests:

- `flutter test --reporter compact`

Result:

- Baseline suite currently fails in `test/file_transfer_end_to_end_test.dart` with a truncated transmitted file and a subsequent `DatabaseException(error database_closed)` after transfer completion.
- The failure confirms the current transfer path is not yet robust enough to satisfy the security and integrity requirements laid out in the plan.

Next step:

- Stop here and proceed only with the cryptographic implementation and protocol redesign required by the plan, using the review findings above as the design baseline.
