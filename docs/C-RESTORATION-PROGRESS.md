# Exact C restoration progress

The frozen full report covers the complete **414,639-byte CODE segment**.
Attribution retains all four categories:

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 144,936 | 34.95% |
| Inline assembly instructions in C objects | 24,234 | 5.84% |
| Standalone assembly | 244,078 | 58.87% |
| Unattributed instructions and non-routine tables | 1,391 | 0.34% |

The unattributed category contains **1,038 instruction bytes in 22 unknown
routines** and **353 non-routine bytes**. The audit does not credit these bytes
to C or assembly. Remaining assembly, including inline: **268,312 bytes
(64.71%)**.

C-object inventory covers **170,561 bytes (41.13%)**, including **24,234
inline-assembly bytes**. The inventories contain **1,195 C routine spans** and
**489 assembly routine spans**; attribution remains unresolved in 22 C spans.

The status-panel update adds **608 exact native C bytes and 36 LE sites** while
retaining an **84-byte assembly entry prefix with 5 LE sites**. The complete
692-byte routine is therefore not all C; its C body contains no inline
assembly. Full validation passes **321 unit tests and 112 fixtures**.

## Reproducible evidence

The accepted executable remains **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
The report scope is verified saved artifacts; check current source freshness
with `restore.py doctor`.

- Full validation: `work/status-panel-build/validation.json`.
- Attribution audit: `work/status-panel-audit.json`.
- Verified change packet: `work/status-panel-handoff.json`.
- Status-panel regression: `work/status-panel-build/status-panel-behavior.json`.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
