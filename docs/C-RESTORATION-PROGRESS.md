# Exact C restoration progress

The frozen report covers all 414,639 CODE bytes and includes 532 compiler units. The menu-prep validation reports 362 tests and 121 fixtures.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 152,115 | 36.69% |
| Inline assembly instructions in C objects | 24,253 | 5.85% |
| Standalone assembly | 236,864 | 57.13% |
| Unattributed instructions and non-routine tables | 1,407 | 0.34% |

The unattributed category contains 1,038 instruction bytes in 22 unknown routines and 369 non-routine table bytes. The audit does not credit these bytes to C or assembly. Combined remaining assembly, including inline assembly: 261,117 bytes (62.97%). C-object inventory covers 177,775 bytes (42.87%) and 1,227 C routine spans; the assembly inventory has 484 spans.

The accepted executable remains 741,347 bytes, SHA-256 `61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.

The receiver has 916 native C bytes, 0 retained ASM bytes, and 65 LE sites, with no inline assembly. Its behavior oracle passes 104 cases and two controls. Private RETs remain unlinked and guarded.

`getpacket_` now has 1,429 native C bytes, 0 retained ASM bytes, and 80 LE sites. Its behavior oracle passes 110 cases and three controls. Both routines use selected compiler contexts; neither full main public is byte-identical by itself.

`dispatch_main_menu` now has 453 native C bytes, 56 retained ASM body bytes, and 26 C LE sites. The original 32-byte jump table and alignment byte remain assembly; the compiler table is checked but unlinked. The remaining ASM is the 41-byte entry and 15-byte resume path. The behavior oracle passes 1,442 cases and two controls.

## Reproducible evidence

Evidence is the saved artifact set; no live build is implied:

- Exact validation: `work/menu-prep-build/validation.json`.
- Receiver behavior: `work/menu-prep-build/game-receive-behavior.json`.
- Getpacket behavior: `work/menu-prep-build/receivepacket-behavior.json`.
- Attribution audit: `work/menu-prep-audit.json`.
- Restoration handoff: `work/menu-prep-handoff.json`.
- Unit test log: `work/menu-prep-build/logs/unit-tests.log`.
- Main-menu behavior: `work/menu-prep-build/main-menu-behavior.json`.
