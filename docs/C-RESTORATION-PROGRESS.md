# Exact C restoration progress

The current saved attribution audit covers all 414,639 CODE bytes and includes 537 compiler units. Saved full validation passed 398 tests and 125 fixtures; the 741,347-byte executable is byte-identical to the pinned reference.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 153,979 | 37.14% |
| Inline assembly instructions in C objects | 24,303 | 5.86% |
| Standalone assembly | 234,950 | 56.66% |
| Unattributed instructions and non-routine tables | 1,407 | 0.34% |

The unattributed category contains 1,038 instruction bytes in 22 unknown routines and 369 non-routine table bytes. The audit does not credit these bytes to C or assembly. Combined remaining assembly, including inline assembly: 259,253 bytes (62.52%). C-object inventory covers 179,689 bytes (43.34%) and 1,246 C routine spans; the assembly inventory has 483 spans.

The accepted executable is 741,347 bytes, SHA-256 `61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.

`update_level_sector_puzzle_` is restored in readable C: 932 bytes and 59 LE sites, with no inline instructions. One C translation unit compiles twice into three selected phases (410/64/458 bytes); five existing branch edges change displacement only. Neither full compiler public matches by itself. Its differential fixture passes 128 cases and rejects both activation-tag and exit-destination code mutations.

`level_encounter_exit_`, its tile latch, frame operations, and second actor update contribute 569 exact native C body bytes and 37 LE sites from one C source compiled in two private contexts, with no inline assembly. The exit phase is 261 bytes; the latch phases total 138 bytes. The latch fixture passes 360 cases and rejects the state and sound machine-code mutations. It compares natural compiler order with linked order; the index and zero phases commute. The frame fixture covers four cases and rejects a typed CODE pointer mutation and a POP EDI mutation. Its 56 bytes span four aliases of 5/39/6/6 bytes with two typed CODE fields. The original 184-byte frame and six saves remain; PUSH/POP EBP are two retained ASM instructions, and the 13-byte return path is stitched from a C release, ASM POP EBP, and C register restore. The second actor update adds 114 bytes and seven LE sites from the existing latch context. The encounter retains 694 assembly body bytes and 160 assembly table bytes. The private publics are 1,225 and 1,249 bytes, each preceded by a separate 160-byte literal prefix; only selected exact slices are linked, with no C credit for those prefixes or tables.

The masked renderer projection links 359 exact bytes with 25 LE sites from the historical Build C context. Marker verification attributes 309 bytes to the compiler and 50 to five inline helper invocations. The next instruction remains the original assembly jump into the 930-byte sort and draw continuation.

The receiver has 916 native C bytes, 0 retained ASM bytes, and 65 LE sites, with no inline assembly. Its behavior oracle passes 104 cases and two controls. Private RETs remain unlinked and guarded.

`getpacket_` has 1,429 native C bytes, 0 retained ASM bytes, and 80 LE sites. Its behavior oracle passes 110 cases and three controls. Both routines use selected compiler contexts; neither full main public is byte-identical by itself.

`dispatch_main_menu` has 507 C-linked image bytes and 2 retained ASM body bytes, with 30 C LE sites. Four instruction-aligned C phases cover source bytes 0–41 once. The original 32-byte jump table and alignment byte remain assembly; the checked compiler table is unlinked. Watcom emits the shared guard once, linked at two disjoint original addresses: this adds 13 linked image bytes and zero new unique compiler bytes. The only body blocker is the final 2-byte false-path JMP: Watcom merges the source flow, so keep its original opcode width. The behavior oracle passes 1,442 cases and two controls.

## Reproducible evidence

The saved full validation and audit artifacts verify the pinned image:

- Full validation and 125 fixtures: `work/drawmasks-projection-build/validation.json`.
- Encounter frame behavior: `work/encounter-frame-build/encounter-frame-behavior.json`.
- Projection handoff: `work/drawmasks-projection-handoff.json`.
- Attribution audit: `work/drawmasks-projection-audit.json`.
- Unit test log: `work/drawmasks-projection-build/logs/unit-tests.log`.
- Encounter latch behavior: `work/encounter-latch-build/encounter-latch-behavior.json`.
- Puzzle exact slices, relocations, and behavior: `work/sector-puzzle-build/sector-puzzle-behavior.json`.

Earlier routine-specific artifacts remain available:

- Receiver behavior: `work/menu-guard-build/game-receive-behavior.json`.
- Getpacket behavior: `work/menu-guard-build/receivepacket-behavior.json`.
- Main-menu behavior: `work/menu-guard-build/main-menu-behavior.json`.
