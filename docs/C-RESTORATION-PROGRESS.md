# Exact C restoration progress

The frozen full report covers the complete **414,639-byte CODE segment**.
Attribution retains all four categories:

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 144,328 | 34.81% |
| Inline assembly instructions in C objects | 24,234 | 5.84% |
| Standalone assembly | 244,686 | 59.01% |
| Unattributed instructions and non-routine tables | 1,391 | 0.34% |

The unattributed category contains **1,038 instruction bytes in 22 unknown
routines** and **353 non-routine bytes**. The audit does not credit these bytes
to C or assembly. Remaining assembly, including inline: **268,920 bytes
(64.86%)**.

C-object inventory, including inline assembly, covers **169,953 bytes
(40.99%)**. The inventories contain **1,194 C routine spans** and **489
assembly routine spans**; attribution remains unresolved in 22 C spans.

The latest byte-stage update removes **7 inline bytes across two functions**:
`parse_startup_arguments_` (2 bytes) and `driver_command_3_` (5 bytes). Both
remain mixed C/inline-assembly functions. Their explicit byte-input contracts
are metadata and add no C instruction bytes. Full validation passes **316 unit
tests and 111 fixtures**; game smoke is skipped.

## Reproducible evidence

The accepted executable is **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
The report scope is verified saved artifacts; check current source freshness
with `restore.py doctor`.

- Full validation: `work/byte-stage-build/validation.json`.
- Attribution audit: `work/byte-stage-audit.json`.
- Verified change packet: `work/byte-stage-handoff.json`.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
