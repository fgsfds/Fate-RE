# Exact C restoration progress

The frozen full report covers the complete **414,639-byte CODE segment**.
Attribution retains all four categories:

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 147,969 | 35.69% |
| Inline assembly instructions in C objects | 24,234 | 5.84% |
| Standalone assembly | 241,045 | 58.13% |
| Unattributed instructions and non-routine tables | 1,391 | 0.34% |

The unattributed category contains **1,038 instruction bytes in 22 unknown
routines** and **353 non-routine bytes**. The audit does not credit these bytes
to C or assembly. Remaining assembly, including inline: **265,279 bytes (63.98%)**.

C-object inventory covers **173,594 bytes (41.87%)**, including **24,234
inline-assembly bytes**. The inventories contain **1,199 C routine spans** and
**487 assembly routine spans**; attribution remains unresolved in 22 C spans.

The sendpacket update adds **1,177 native C bytes, zero inline bytes, and 62 LE
sites**. Full validation passes **330 unit tests and 116 fixtures** across
**521 compiler units**. Its behavior fixture passes **139 cases and three
negative controls**.

## Reproducible evidence

The accepted executable remains **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
The report scope is verified saved artifacts; check current source freshness
with `restore.py doctor`.

- Latest full validation: `work/sendpacket-build/validation.json`; executable SHA unchanged.
- Sendpacket behavior fixture: `work/sendpacket-build/sendpacket-behavior.json`.
- Attribution audit: `work/sendpacket-audit.json`.
- Verified change packet: `work/sendpacket-handoff.json`.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
