# Exact C restoration progress

The frozen full report covers the complete **414,639-byte CODE segment**.
Attribution retains all four categories:

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 146,792 | 35.40% |
| Inline assembly instructions in C objects | 24,234 | 5.84% |
| Standalone assembly | 242,222 | 58.42% |
| Unattributed instructions and non-routine tables | 1,391 | 0.34% |

The unattributed category contains **1,038 instruction bytes in 22 unknown
routines** and **353 non-routine bytes**. The audit does not credit these bytes
to C or assembly. Remaining assembly, including inline: **266,456 bytes
(64.26%)**.

C-object inventory covers **172,417 bytes (41.58%)**, including **24,234
inline-assembly bytes**. The inventories contain **1,198 C routine spans** and
**488 assembly routine spans**; attribution remains unresolved in 22 C spans.

The netsend update adds **629 native C bytes, zero inline bytes, and 57 LE
sites**. Full validation passes **330 unit tests and 115 fixtures** across
**520 compiler units**. Its behavior fixture passes **55 cases and two negative
controls**.

## Reproducible evidence

The accepted executable remains **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
The report scope is verified saved artifacts; check current source freshness
with `restore.py doctor`.

- Latest full validation: `work/netsend-build/validation.json`; executable SHA unchanged.
- Netsend behavior fixture: `work/netsend-build/netsend-behavior.json`.
- Attribution audit: `work/netsend-audit.json`.
- Verified change packet: `work/netsend-handoff.json`.
- Pinned source provenance: `work/send-ipx-next/source-provenance.json`.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
