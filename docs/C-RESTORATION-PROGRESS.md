# Exact C restoration progress

The frozen report covers all 414,639 CODE bytes and includes 528 compiler units. The frozen validation reports 349 tests and 120 fixtures.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 151,608 | 36.56% |
| Inline assembly instructions in C objects | 24,253 | 5.85% |
| Standalone assembly | 237,371 | 57.25% |
| Unattributed instructions and non-routine tables | 1,407 | 0.34% |

The unattributed category contains 1,038 instruction bytes in 22 unknown routines and 369 non-routine table bytes. The audit does not credit these bytes to C or assembly. Combined remaining assembly, including inline assembly: 261,624 bytes (63.10%). C-object inventory covers 177,268 bytes (42.75%) and 1,217 C routine spans; the assembly inventory has 487 spans.

The accepted executable remains 741,347 bytes, SHA-256 `61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.

The packet receiver now matches across 866 native C bytes and 50 retained assembly bytes, with 60 C and 5 assembly LE sites. Its checksum and parity contexts are standalone C with a RET-suffix guard; no inline instructions are used. The new high-byte, head, and send prefixes are exact: 9, 18, and 13 bytes respectively. The behavior oracle passes 104 cases and two controls. The excluded high-byte, head, and send contexts are documented in `receive_button_high.c`, `receive_ready_head.c`, and `receive_ready_send.c`.

## Reproducible evidence

Evidence is the saved artifact set; no live build is implied:

- Exact validation: `work/receiver-ready-build/validation.json`.
- Receiver behavior: `work/receiver-ready-build/game-receive-behavior.json`.
- Attribution audit: `work/receiver-ready-audit.json`.
- Restoration handoff: `work/receiver-ready-handoff.json`.
- Unit test log: `work/receiver-ready-build/logs/unit-tests.log`.

The remaining receiver gaps are checksum ordering (3 bytes), low-button merge (17 bytes), and deadline arithmetic (30 bytes). See [open probes](C-RESTORATION-ATTEMPTS.md).
