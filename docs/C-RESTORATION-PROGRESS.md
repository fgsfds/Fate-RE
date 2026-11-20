# Exact C restoration progress

The frozen full report covers the complete **414,639-byte CODE segment**.
Attribution retains all four categories:

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 141,464 | 34.12% |
| Inline assembly instructions in C objects | 24,281 | 5.86% |
| Standalone assembly | 247,503 | 59.69% |
| Unattributed instructions and non-routine tables | 1,391 | 0.34% |

The unattributed category contains **1,038 instruction bytes in 22 unknown
routines** and **353 non-routine bytes**. The audit does not credit these bytes
to C or assembly. Remaining assembly, including inline: **271,784 bytes
(65.55%)**.

C-object inventory, including inline assembly, covers **167,136 bytes
(40.31%)**. The inventories contain **1,191 C routine spans** and **492 assembly routine spans**; attribution remains
unresolved in 22 C routine spans.

The accepted `dispatch_actor_update` source (`src/fate/actor_dispatch.c`)
produces **647 native bytes, 0 inline bytes, and 31 LE sites**. It passes full
validation with **316 unit tests and 108 fixtures**, including the dispatcher
fixture's **368 original/candidate behavior cases**. Game smoke was skipped.

## Reproducible evidence

The accepted executable is **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
The report scope is verified saved artifacts; check current source freshness
with `restore.py doctor`.

- Full validation: `work/actor-dispatch-build/validation.json`.
- Attribution audit: `work/actor-dispatch-audit.json`.
- Dispatcher evidence: `work/actor-dispatch-evidence.json`.
- Accepted source: `src/fate/actor_dispatch.c`.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
