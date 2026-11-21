# Exact C restoration progress

The frozen report covers all 414,639 CODE bytes and includes 529 compiler units. The frozen validation reports 349 tests and 120 fixtures.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 151,658 | 36.58% |
| Inline assembly instructions in C objects | 24,253 | 5.85% |
| Standalone assembly | 237,321 | 57.24% |
| Unattributed instructions and non-routine tables | 1,407 | 0.34% |

The unattributed category contains 1,038 instruction bytes in 22 unknown routines and 369 non-routine table bytes. The audit does not credit these bytes to C or assembly. Combined remaining assembly, including inline assembly: 261,574 bytes (63.08%). C-object inventory covers 177,318 bytes (42.76%) and 1,221 C routine spans; the assembly inventory has 484 spans.

The accepted executable remains 741,347 bytes, SHA-256 `61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.

The receiver now has 916 native C bytes, 0 retained ASM bytes, and 65 native LE sites, with no inline assembly. These are selected compiler contexts; the main public is not one matching span. The final 50 bytes are low button (17), checksum (3), delta (10), and clock (20) in `src/fate/receive_fragments.c`. Private RETs remain unlinked and guarded. The behavior oracle passes 104 cases and two controls.

## Reproducible evidence

Evidence is the saved artifact set; no live build is implied:

- Exact validation: `work/receiver-native-build/validation.json`.
- Receiver behavior: `work/receiver-native-build/game-receive-behavior.json`.
- Attribution audit: `work/receiver-native-audit.json`.
- Restoration handoff: `work/receiver-native-handoff.json`.
- Unit test log: `work/receiver-native-build/logs/unit-tests.log`.
