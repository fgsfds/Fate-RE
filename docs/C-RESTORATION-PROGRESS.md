# Exact C restoration progress

The current saved attribution audit covers all 414,639 CODE bytes and includes 535 compiler units. Saved full validation passed 382 tests and 123 fixtures; the 741,347-byte executable is byte-identical to the pinned reference.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 153,362 | 36.99% |
| Inline assembly instructions in C objects | 24,253 | 5.85% |
| Standalone assembly | 235,617 | 56.82% |
| Unattributed instructions and non-routine tables | 1,407 | 0.34% |

The unattributed category contains 1,038 instruction bytes in 22 unknown routines and 369 non-routine table bytes. The audit does not credit these bytes to C or assembly. Combined remaining assembly, including inline assembly: 259,870 bytes (62.67%). C-object inventory covers 179,022 bytes (43.18%) and 1,236 C routine spans; the assembly inventory has 482 spans.

The accepted executable is 741,347 bytes, SHA-256 `61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.

`update_level_sector_puzzle_` is restored in readable C: 932 bytes and 59 LE sites, with no inline instructions. One C translation unit compiles twice into three selected phases (410/64/458 bytes); five existing branch edges change displacement only. Neither full compiler public matches by itself. Its differential fixture passes 128 cases and rejects both activation-tag and exit-destination code mutations.

`level_encounter_exit_` now has a verified native C phase of 261 bytes and 20 LE sites. Its differential fixture passes 145 cases across the full DATA region and rejects scan-match-1 and deletion mutations. The shared original frame is 184 bytes with six saved registers and the original 13-byte epilogue. The remaining 1,002-byte body and 160-byte literal tables stay assembly. Only slice `[0x3b8,0x4bd)` from the 1,225-byte private compiler public is linked. Its separate 160-byte leading literal prefix is excluded, and neither omitted code nor literals receive C credit.

The receiver has 916 native C bytes, 0 retained ASM bytes, and 65 LE sites, with no inline assembly. Its behavior oracle passes 104 cases and two controls. Private RETs remain unlinked and guarded.

`getpacket_` has 1,429 native C bytes, 0 retained ASM bytes, and 80 LE sites. Its behavior oracle passes 110 cases and three controls. Both routines use selected compiler contexts; neither full main public is byte-identical by itself.

`dispatch_main_menu` has 507 C-linked image bytes and 2 retained ASM body bytes, with 30 C LE sites. Four instruction-aligned C phases cover source bytes 0–41 once. The original 32-byte jump table and alignment byte remain assembly; the checked compiler table is unlinked. Watcom emits the shared guard once, linked at two disjoint original addresses: this adds 13 linked image bytes and zero new unique compiler bytes. The only body blocker is the final 2-byte false-path JMP: Watcom merges the source flow, so keep its original opcode width. The behavior oracle passes 1,442 cases and two controls.

## Reproducible evidence

The saved full validation and audit artifacts verify the pinned image:

- Full validation and 123 fixtures: `work/encounter-exit-build/validation.json`.
- Encounter exact slice, relocations, and differential fixture: `work/encounter-exit-build/encounter-exit-behavior.json`.
- Encounter phase handoff: `work/encounter-exit-handoff.json`.
- Attribution audit: `work/encounter-exit-audit.json`.
- Unit test log: `work/encounter-exit-build/logs/unit-tests.log`.
- Puzzle exact slices, relocations, and behavior: `work/sector-puzzle-build/sector-puzzle-behavior.json`.

Earlier routine-specific artifacts remain available:

- Receiver behavior: `work/menu-guard-build/game-receive-behavior.json`.
- Getpacket behavior: `work/menu-guard-build/receivepacket-behavior.json`.
- Main-menu behavior: `work/menu-guard-build/main-menu-behavior.json`.
