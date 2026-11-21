# Exact C restoration progress

The saved attribution audit covers all 414,639 CODE bytes and includes 532 compiler units. The menu-entry validation reports 364 tests and 121 fixtures.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 152,156 | 36.70% |
| Inline assembly instructions in C objects | 24,253 | 5.85% |
| Standalone assembly | 236,823 | 57.12% |
| Unattributed instructions and non-routine tables | 1,407 | 0.34% |

The unattributed category contains 1,038 instruction bytes in 22 unknown routines and 369 non-routine table bytes. The audit does not credit these bytes to C or assembly. Combined remaining assembly, including inline assembly: 261,076 bytes (62.96%). C-object inventory covers 177,816 bytes (42.88%) and 1,231 C routine spans; the assembly inventory has 483 spans.

The accepted executable remains 741,347 bytes, SHA-256 `61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.

The receiver has 916 native C bytes, 0 retained ASM bytes, and 65 LE sites, with no inline assembly. Its behavior oracle passes 104 cases and two controls. Private RETs remain unlinked and guarded.

`getpacket_` now has 1,429 native C bytes, 0 retained ASM bytes, and 80 LE sites. Its behavior oracle passes 110 cases and three controls. Both routines use selected compiler contexts; neither full main public is byte-identical by itself.

`dispatch_main_menu` now has 494 native C bytes, 15 retained ASM body bytes, and 29 C LE sites. Four instruction-aligned C phases cover source bytes 0–41 once. The original 32-byte jump table and alignment byte remain assembly; the compiler table is checked but unlinked. Only the 15-byte resume path remains in the body. The behavior oracle passes 1,442 cases and two controls.

## Reproducible evidence

Evidence is the saved artifact set; no live build is implied:

- Exact validation: `work/menu-entry-build/validation.json`.
- Receiver behavior: `work/menu-entry-build/game-receive-behavior.json`.
- Getpacket behavior: `work/menu-entry-build/receivepacket-behavior.json`.
- Attribution audit: `work/menu-entry-audit.json`.
- Restoration handoff: `work/menu-entry-handoff.json`.
- Unit test log: `work/menu-entry-build/logs/unit-tests.log`.
- Main-menu behavior: `work/menu-entry-build/main-menu-behavior.json`.
