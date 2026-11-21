# Exact C restoration progress

The frozen full report covers the complete **414,639-byte CODE segment**.
Attribution retains all four categories:

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 151,456 | 36.53% |
| Inline assembly instructions in C objects | 24,253 | 5.85% |
| Standalone assembly | 237,523 | 57.28% |
| Unattributed instructions and non-routine tables | 1,407 | 0.34% |

The unattributed category contains **1,038 instruction bytes in 22 unknown
routines** and **369 non-routine bytes**. The audit does not credit these bytes
to C or assembly. Remaining assembly, including inline: **261,776 bytes (63.13%)**.

C-object inventory covers **177,116 bytes (42.72%)**, including **24,253
inline-assembly bytes**. The inventories contain **1,212 C routine spans** and
**492 assembly routine spans**; attribution remains unresolved in 22 C spans.

The packet receiver covers **714 native C bytes and zero inline bytes**, with
**202 bytes retained in assembly**, across a 916-byte routine. Its 43 C and 22
assembly LE sites total 65; the binder validates 35 selected branch
displacements. The 910-byte full C compiler context is not exact. The behavior
oracle passes **104 cases and two controls**. Full validation passes **348 unit
tests and 120 fixtures** across **523 compiler units**.

## Reproducible evidence

The accepted executable remains **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
The report scope is verified saved artifacts; `restore.py doctor` reports
current source freshness.

- Latest full validation: `work/receiver-build/validation.json` and
  `work/receiver-build/logs/unit-tests.log`.
- Packet receiver behavior oracle: `work/receiver-build/game-receive-behavior.json`.
- C attribution audit: `work/receiver-audit.json`.
- C restoration handoff: `work/receiver-handoff.json`.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
