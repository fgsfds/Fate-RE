# Exact C restoration progress

The frozen full report covers the complete **414,639-byte CODE segment**.
Attribution retains all four categories:

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 150,742 | 36.35% |
| Inline assembly instructions in C objects | 24,253 | 5.85% |
| Standalone assembly | 238,237 | 57.46% |
| Unattributed instructions and non-routine tables | 1,407 | 0.34% |

The unattributed category contains **1,038 instruction bytes in 22 unknown
routines** and **369 non-routine bytes**. The audit does not credit these bytes
to C or assembly. Remaining assembly, including inline: **262,490 bytes (63.31%)**.

C-object inventory covers **176,402 bytes (42.54%)**, including **24,253
inline-assembly bytes**. The inventories contain **1,203 C routine spans** and
**485 assembly routine spans**; attribution remains unresolved in 22 C spans.

The serial network initializer restores a **648-byte body
(629 native and 19 inline-I/O bytes)** plus a **16-byte CODE table**, matching
all **46 LE sites** (42 body and 4 table sites). Its behavior fixture passes
**38 cases and two negative controls**. Full validation passes **342 unit tests
and 119 fixtures** across **522 compiler units**. The separate IPX context
routine remains assembly; its unlinked historical companion receives no coverage.

## Reproducible evidence

The accepted executable remains **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
The report scope is verified saved artifacts; `restore.py doctor` reports
current source freshness.

- Latest full validation: `work/serial-init-build/validation.json` and
  `work/serial-init-build/logs/unit-tests.log`.
- Serial behavior fixture: `work/serial-init-build/serial-init-behavior.json`.
- C attribution audit: `work/serial-init-audit.json`.
- C restoration handoff: `work/serial-init-handoff.json`.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
