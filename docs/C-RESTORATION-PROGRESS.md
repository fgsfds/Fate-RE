# Exact C restoration progress

The frozen full report covers the complete **414,639-byte CODE segment**.
Attribution retains all four categories:

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 149,394 | 36.03% |
| Inline assembly instructions in C objects | 24,234 | 5.84% |
| Standalone assembly | 239,620 | 57.79% |
| Unattributed instructions and non-routine tables | 1,391 | 0.34% |

The unattributed category contains **1,038 instruction bytes in 22 unknown
routines** and **353 non-routine bytes**. The audit does not credit these bytes
to C or assembly. Remaining assembly, including inline: **263,854 bytes (63.63%)**.

C-object inventory covers **175,019 bytes (42.21%)**, including **24,234
inline-assembly bytes**. The inventories contain **1,201 C routine spans** and
**487 assembly routine spans**; attribution remains unresolved in 22 C spans.

The getpacket update adds **1,425 native C bytes, retains four assembly bytes,
and matches 80 LE sites**. Full validation passes **330 unit tests and 117
fixtures** across **521 compiler units**. Its behavior fixture passes **110
cases and three negative controls**.

## Reproducible evidence

The accepted executable remains **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
The report scope is verified saved artifacts; check current source freshness
with `restore.py doctor`.

- Latest full validation: `work/getpacket-build/validation.json`; executable SHA unchanged.
- Getpacket behavior fixture: `work/getpacket-build/receivepacket-behavior.json`.
- Attribution audit: `work/getpacket-audit.json`.
- Verified change packet: `work/getpacket-handoff.json`.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
