# OpenSID Integration Contract

## Source of truth
OpenSID-compatible MySQL remains the operational source for legacy village administration data. RT/RW CONNECT remains the governed cross-system identity, territory, access-control, and exchange layer.

## Synchronization lifecycle
1. RECEIVE — accept a signed/authenticated batch.
2. VALIDATE — verify schema, identifiers, ownership, and referential integrity.
3. APPLY — write only approved canonical records.
4. PARTIAL — record rejected records while preserving accepted records.
5. REJECTED — reject the batch without mutating canonical data.

## Required controls
- idempotency key per batch
- source system identifier
- schema/version identifier
- row counts: received, validated, applied, rejected
- checksum or content digest
- actor/service identity
- timestamps
- immutable audit evidence

## Mapping rule
No field is promoted into a canonical RT/RW CONNECT domain until its OpenSID source table and column have been verified from the actual supplied OpenSID release. Never infer a column merely because a similarly named field exists.
