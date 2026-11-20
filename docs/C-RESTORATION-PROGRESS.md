# Exact C restoration progress

The frozen full report covers the complete **414,639-byte CODE segment**.
Attribution retains all four categories:

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 140,817 | 33.96% |
| Inline assembly instructions in C objects | 24,281 | 5.86% |
| Standalone assembly | 248,150 | 59.85% |
| Unattributed instructions and non-routine tables | 1,391 | 0.34% |

The unattributed category contains **1,038 instruction bytes in 22 unknown
routines** and **353 non-routine bytes**. The audit does not credit these bytes
to C or assembly. Remaining assembly, including inline: **272,431 bytes
(65.70%)**.

C objects cover **166,489 bytes (40.15%)**, including inline assembly. The
inventories contain **1,190 C routine spans** and **493 assembly routine spans**;
Attribution remains unresolved in 22 C routine spans.

`update_actor_common_` (`src/fate/actor_common.c`) is now entirely compiler
generated: **697 bytes**, **0 inline bytes**, and **41 LE sites**. Its 274
original/candidate oracle cases each pass.

## Reproducible evidence

The frozen full report records **316 unit tests** and **107 fixtures**. The
accepted executable is **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
The report scope is verified saved artifacts; check current source freshness
with `restore.py doctor`. Game smoke was skipped.

- Full report: `work/actor-common-build/validation.json`.
- Attribution: `work/actor-common-audit.json`.
- Actor source and oracle: `src/fate/actor_common.c` and the actor-common
  regression fixture `tools/check_actor_common.py`.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
