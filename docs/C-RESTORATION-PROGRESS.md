# Exact C restoration progress

The frozen full report covers the complete **414,639-byte CODE segment**.
Attribution retains all four categories:

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 151,568 | 36.55% |
| Inline assembly instructions in C objects | 24,253 | 5.85% |
| Standalone assembly | 237,411 | 57.26% |
| Unattributed instructions and non-routine tables | 1,407 | 0.34% |

The unattributed category contains **1,038 instruction bytes in 22 unknown
routines** and **369 non-routine bytes**. The audit does not credit these bytes
to C or assembly. Remaining assembly, including inline: **261,664 bytes (63.11%)**.

C-object inventory covers **177,228 bytes (42.74%)**, including **24,253
inline-assembly bytes**. The inventories contain **1,214 C routine spans** and
**490 assembly routine spans**; attribution remains unresolved in 22 C spans.

The packet receiver is exact across **826 native C bytes and 90 retained
assembly bytes**, with **56 C and 9 assembly LE sites**. Its checksum and
parity C contexts contain no inline assembly instructions and use a RET-suffix
guard. The behavior oracle passes **104 cases and two controls**. All **55
focused tests** pass locally. The Codex-only configuration passes the local
full unit suite. Full build and fixture validation runs on the clean committed
tree in CI. The report includes 525 compiler units.

## Reproducible evidence

The accepted executable remains **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
The report scope is verified saved artifacts; `restore.py doctor` reports
current source freshness.

- Local exact validation: `work/receiver-finish-build/validation.json`.
- Packet receiver behavior oracle: `work/receiver-finish-build/game-receive-behavior.json`.
- Attribution audit: `work/receiver-finish-audit.json`.
- Saved C restoration handoff: `work/receiver-finish-handoff.json` (exact
  mode, zero fixture count).
- Focused test result: 55 tests passed locally.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
