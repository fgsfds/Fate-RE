# Exact C restoration progress

The frozen report covers all 414,639 CODE bytes and includes 530 compiler units. The frozen validation reports 349 tests and 120 fixtures.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 151,662 | 36.58% |
| Inline assembly instructions in C objects | 24,253 | 5.85% |
| Standalone assembly | 237,317 | 57.23% |
| Unattributed instructions and non-routine tables | 1,407 | 0.34% |

The unattributed category contains 1,038 instruction bytes in 22 unknown routines and 369 non-routine table bytes. The audit does not credit these bytes to C or assembly. Combined remaining assembly, including inline assembly: 261,570 bytes (63.08%). C-object inventory covers 177,322 bytes (42.77%) and 1,222 C routine spans; the assembly inventory has 483 spans.

The accepted executable remains 741,347 bytes, SHA-256 `61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.

The receiver has 916 native C bytes, 0 retained ASM bytes, and 65 LE sites, with no inline assembly. Its behavior oracle passes 104 cases and two controls. Private RETs remain unlinked and guarded.

`getpacket_` now has 1,429 native C bytes, 0 retained ASM bytes, and 80 LE sites. Its behavior oracle passes 110 cases and three controls. Both routines use selected compiler contexts; neither full main public is byte-identical by itself.

## Reproducible evidence

Evidence is the saved artifact set; no live build is implied:

- Exact validation: `work/getpacket-native-build/validation.json`.
- Receiver behavior: `work/getpacket-native-build/game-receive-behavior.json`.
- Getpacket behavior: `work/getpacket-native-build/receivepacket-behavior.json`.
- Attribution audit: `work/getpacket-native-audit.json`.
- Restoration handoff: `work/getpacket-native-handoff.json`.
- Unit test log: `work/getpacket-native-build/logs/unit-tests.log`.
