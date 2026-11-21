# Exact C restoration progress

The frozen full report covers the complete **414,639-byte CODE segment**.
Attribution retains all four categories:

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 146,163 | 35.25% |
| Inline assembly instructions in C objects | 24,234 | 5.84% |
| Standalone assembly | 242,851 | 58.57% |
| Unattributed instructions and non-routine tables | 1,391 | 0.34% |

The unattributed category contains **1,038 instruction bytes in 22 unknown
routines** and **353 non-routine bytes**. The audit does not credit these bytes
to C or assembly. Remaining assembly, including inline: **267,085 bytes
(64.41%)**.

C-object inventory covers **171,788 bytes (41.43%)**, including **24,234
inline-assembly bytes**. The inventories contain **1,197 C routine spans** and
**489 assembly routine spans**; attribution remains unresolved in 22 C spans.

The gameplay-controller update adds **1,227 native C bytes and 112 C LE sites**;
an 18-byte row-address sequence remains in assembly, with one LE site. Full validation
passes **330 unit tests and 113 fixtures** across **519 compiler units**.

## Reproducible evidence

The accepted executable remains **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
The report scope is verified saved artifacts; check current source freshness
with `restore.py doctor`.

- Full validation: `work/gameplay-controller-build/validation.json`.
- Attribution audit: `work/gameplay-controller-audit.json`.
- Verified change packet: `work/gameplay-controller-handoff.json`.
- Controller regression: `work/gameplay-controller-build/gameplay-update-behavior.json`.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
