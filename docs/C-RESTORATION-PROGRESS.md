# Exact C restoration progress

The current saved attribution audit covers all 414,639 CODE bytes and includes 575 compiler units. Saved full validation passed 406 tests and 145 fixtures; the 741,347-byte executable is byte-identical to the pinned reference.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 167,514 | 40.400% |
| Inline assembly instructions in C objects | 24,311 | 5.863% |
| Standalone assembly | 221,531 | 53.427% |
| Unattributed instructions and non-routine tables | 1,283 | 0.309% |

The unattributed category contains 882 instruction bytes in 16 unknown routines and 401 non-routine table bytes. Tables are recorded as data, and the unknown instruction bytes remain uncredited. Combined remaining assembly, including inline assembly: 245,842 bytes (59.291%). C-object inventory covers 193,108 bytes (46.57%) and 1,439 C routine spans; the assembly inventory has 479 spans.

The accepted executable is 741,347 bytes, SHA-256 `61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.

The encounter actor-state decisions add 95 native C bytes and four DATA LE sites, with no inline instructions. Five slices from the existing latch context provide 86 bytes; a new C reset helper provides the nine-byte immediate word store. Dead private EAX/ECX copies and a redundant TEST are excluded after successor/register/defined-flag proofs. The complete 1,249-byte public and 160-byte literal prefix are guarded; all 85 OMF fixups are pinned, including internal targets, frames, displacements and excluded external names. Five existing branches are placed with checked displacements. The 180-case fixture compares both handoffs, full DATA/frame/register state and defined flags with stubbed near-condition calls, including synthetic signed and poisoned high-word returns. Two code controls and nine context mutations are rejected with diagnostic checks and an unchanged OMF re-encoding control.

Sound playback now has 215 native C bytes and seven LE sites, with no inline instructions: callback/flags setup contributes 80 bytes and five sites, descriptor initialization contributes 69 bytes and two DATA sites, and positioning contributes 66 bytes with two relative calls and no selected LE sites. Complete 81-, 72- and 76-byte private contexts are guarded, including excluded callback code and private returns. The positioning context reads Y with a truthful EBP getter, reloads the original stack X slot, and uses a shared real callback store to preserve branch layout. Its audio-volume declaration matches the production unsigned-long return type. The two remaining assembly spans total 540 bytes. Production archive IDs are 0..163; the negative-ID predecessor is explicitly fixture-backed. The 60-case mixed-body fixture rejects five private-context mutations using fresh binding outputs and specific error checks, plus the existing volume and return-cleanup controls. CRT, archive I/O, positional audio and queue operations are stubbed; callback addresses are checked without invocation. This is not live audio-driver or asset verification.

The bounded agent trial completes the remaining gameplay row setup (18 bytes, one LE site) and status-panel entry (84 bytes, five LE sites). Both routines now link entirely from compiler-generated C, with no inline instructions; their assembly sources are removed. Full private-context hashes and fixup identities guard all selected and excluded code. Empty register identities and independent setup slices preserve the original handoffs without emitting handwritten instructions. These are preserved C candidates requalified against current tools, not a measurement of fresh rewrite speed. The gameplay fixture covers the complete controller and 256 placed/private row handoffs; the panel fixture covers 40 placed and 80 private-context cases. Drawing, formatting and controller callees are modeled by fixture callbacks.

The first revised-agent trial used a bounded Luna probe and an independent Sol review. The probe freshly compiled both candidates with zero cache hits and passed exact checks in 3.70 seconds (2.59 seconds compiling), after one parent correction for a premature script-path blocker. Review accepted without corrective intervention. CI discovery also needed one correction from a PR-only wrapper to the generic paginated push-run API. Both corrections were added to those profiles. The full parent gate passed 406 tests and 145 fixtures. That trial removed three overlapping helper roles; the subsequent [controlled comparison](WORKFLOW-COMPARISON.md) retires probe and CI-monitor roles as well. Research and review remain, with ready commands and CI observation handled directly. Per-agent token counters are unavailable, so this trial establishes no token-saving percentage or fresh-rewrite speedup. The broader restoration goal remains paused.

`update_level_sector_puzzle_` is restored in readable C: 932 bytes and 59 LE sites, with no inline instructions. One C translation unit compiles twice into three selected phases (410/64/458 bytes); five existing branch edges change displacement only. Neither full compiler public matches by itself. Its differential fixture passes 128 cases and rejects both activation-tag and exit-destination code mutations.

`level_encounter_exit_`, its tile latch, frame operations, and second actor update contribute 569 exact native C body bytes and 37 LE sites from one C source compiled in two private contexts, with no inline assembly. The exit phase is 261 bytes; the latch phases total 138 bytes. The latch fixture passes 360 cases and rejects the state and sound machine-code mutations. It compares natural compiler order with linked order; the index and zero phases commute. The frame fixture covers four cases and rejects a typed CODE pointer mutation and a POP EDI mutation. Its 56 bytes span four aliases of 5/39/6/6 bytes with two typed CODE fields. The original 184-byte frame and six saves remain; PUSH/POP EBP are two retained ASM instructions, and the 13-byte return path is stitched from a C release, ASM POP EBP, and C register restore. The second actor update adds 114 bytes and seven LE sites from the existing latch context. The encounter retains 599 assembly body bytes and 160 assembly table bytes. The private publics are 1,225 and 1,249 bytes, each preceded by a separate 160-byte literal prefix; only selected exact slices are linked, with no C credit for those prefixes or tables.

Save and load are fully compiler-generated C: 5,432 load bytes with 254 LE sites and 5,409 save bytes with 253 LE sites. All 10,841 original instruction bytes link from 55 checked C spans, with no inline instructions. Both assembly sources are removed. A bounded character view of the complete DATA object preserves the serialized field order and widths; pointer-table conversions use unsigned 32-bit address arithmetic. Complete private-context hashes, fixup forms/addends and branch destinations are guarded. The attribution checker also verifies 156 pre-existing native C bytes that were previously unmeasured; those are separate from the 10,841 assembly bytes replaced here.

The seven save/load fixtures cover 465 literal field records, dynamic lengths, all 512 pointer-table indices, status fields/messages, slot opening, player chains and frame returns. They test partial/empty transfers, caller-clobber poison, complete DATA/frame guards, native forward-overlapping append and native string lengths. Primitive stream operations and player initialization are modeled where hooked. The four round trips concern pointer-word conversion only; these fixtures do not establish end-to-end DOS save/load or malformed-file handling. Shared-tail marker classification requires matching relocated E8 callees, operands, FLAT frames/addends and a terminal near RET; regression tests reject indirect and unverified LOOP-family transfers.

`animate_ripple_texture` is entirely compiler-generated C: 855 bytes, 37 LE sites and no inline instructions. Its 81 linked C spans cover the complete routine. A readable 865-byte full-algorithm context supplies the final 43 save/restore and control-transfer bytes; raw context bytes, all 39 fixup forms/targets/addends, compiler branch targets and placed destinations are guarded. Packed row and tile types preserve the original unaligned four-pixel operations. The initializer's offset-array declarations now agree with the unsigned dword readers while retaining its existing store code.

Eight ripple fixtures cover toroidal borders, seven-neighbor filtering, radial setup/sampling, particle updates, output packing, borrowed frame slots and register restoration. The control fixture verifies 399 edges, two save/restore cases, 32 private-model cases, 32 production cases and six mutations. Whole-routine behavior uses a stubbed RNG and three synthetic samples per radius; separate radial fixtures cover 9,600 setup cases and 7,680 sample cases. The actual RNG ABI was checked against the pinned executable. The standalone ripple assembly source and registration are removed.

Video-mode setup links all 834 body bytes and 75 LE sites from C contexts: 826 compiler-generated bytes and eight inline bulk-clear bytes. Its generated dispatch table supplies another 32 data bytes and eight CODE relocations. Both standalone assembly source units have been removed. Twelve compiler branch operands retain their opcodes and widths while targeting the original shared paths. The 37-case initialization fixture covers allocator failures, zero/one/multiple planar pages, state fields and the full register frame. Its three checksum-valid object mutations guard the complete 883-byte display context, including unlinked instructions.

The final dispatch fixture installs the compiler-generated table and compares 1,280 placed dispatch cases and 40 private-table cases. It checks all 256 mode bytes, signed multiplication overflow, poisoned high register bits, ordered reads and all eight entry consumers. Six controls reject private context mutations, a wrong table target and incorrect CODE/DATA typing. The complete 490-byte context and all 60 fixup forms and identities are pinned.

Both stereo state blocks contribute 125 native bytes and 16 LE sites from two ordinary-memory C contexts. Independent register assignments and disjoint stores link in original order; all 13 reordered instruction pairs commute. The 129-byte raw group, both public layouts and all fixup identities/forms are pinned. The dedicated fixture passes 20 cases (60 original/placed/natural executions), four state-code mutations and four checksum-valid mutations of excluded private stack/return instructions. It checks high-bit backend bytes, poisoned live registers, CH preservation, ordered state writes, flags and shared return restoration.

The screenshot encoder uses 445 compiler-generated bytes and 44 LE sites for PCX geometry, filename and file operations, and the planar palette byte calculation and stores. The 27-case fixture checks header guards, filename digits, file-call arguments and return values, sequence wraparound, and the palette handoff. The 874-byte assembly remainder includes the pixel loop, palette control flow and flushing, and the shared return.

The masked renderer projection links 359 exact bytes with 25 LE sites from the historical Build C context. Marker verification attributes 309 bytes to the compiler and 50 to five inline helper invocations. The next instruction remains the original assembly jump into the 930-byte sort and draw continuation.

The receiver has 916 native C bytes, 0 retained ASM bytes, and 65 LE sites, with no inline assembly. Its behavior oracle passes 104 cases and two controls. Private RETs remain unlinked and guarded.

`getpacket_` has 1,429 native C bytes, 0 retained ASM bytes, and 80 LE sites. Its behavior oracle passes 110 cases and three controls. Both routines use selected compiler contexts; neither full main public is byte-identical by itself.

`dispatch_main_menu` has 507 C-linked image bytes and 2 retained ASM body bytes, with 30 C LE sites. Four instruction-aligned C phases cover source bytes 0–41 once. The original 32-byte jump table and alignment byte remain assembly; the checked compiler table is unlinked. Watcom emits the shared guard once, linked at two disjoint original addresses: this adds 13 linked image bytes and zero new unique compiler bytes. The only body blocker is the final 2-byte false-path JMP: Watcom merges the source flow, so keep its original opcode width. The behavior oracle passes 1,442 cases and two controls.

The palette lookup clearing loop contributes 19 compiler-generated bytes and one LE site. Empty register identities preserve EBX without emitted inline instructions; the private compiler RET remains unlinked. Three guarded cases check empty, one-slot and full-table clears, EIP at the handoff, and EAX/EBX/ECX/EDX/ESP. Two code and pointer mutation controls are rejected.

## Reproducible evidence

The saved full validation and audit artifacts verify the pinned image:

- Full validation and 145 fixtures: `work/reset-82ae95d/validation.json`.
- Encounter frame behavior: `work/encounter-frame-build/encounter-frame-behavior.json`.
- Video initialization handoff: `work/setmode-display-handoff.json`.
- Video setup and allocation behavior: `work/reset-82ae95d/setgamemode-init-behavior.json`.
- Stereo original/placed/natural behavior: `work/reset-82ae95d/setgamemode-stereo-behavior.json`.
- Dispatch and generated table: `work/reset-82ae95d/setgamemode-dispatch-behavior.json`.
- Ripple control and full-routine replay: `work/reset-82ae95d/ripple-control.json`.
- Ripple texture oracle: `work/reset-82ae95d/ripple-texture-behavior.json`.
- Save field transfers: `work/reset-82ae95d/save-field-io.json`.
- Save pointer conversions: `work/reset-82ae95d/save-restore-steps.json`.
- Save slot opening and frames: `work/reset-82ae95d/save-slot-open.json`.
- Save player and finish paths: `work/reset-82ae95d/save-players-finish.json`.
- Trial agent outcomes: `work/agent-role-trial/outcomes.json`.
- Gameplay row and controller: `work/reset-82ae95d/gameplay-update-behavior.json`.
- Status-panel placed and private contexts: `work/reset-82ae95d/status-panel-behavior.json`.
- Attribution audit: `work/sound-position-integrate-nov26/audit.json`.
- Unit test log: `work/reset-82ae95d/logs/unit-tests.log`.
- Encounter latch behavior: `work/encounter-latch-build/encounter-latch-behavior.json`.
- Puzzle exact slices, relocations, and behavior: `work/sector-puzzle-build/sector-puzzle-behavior.json`.

Earlier routine-specific artifacts remain available:

- Receiver behavior: `work/menu-guard-build/game-receive-behavior.json`.
- Getpacket behavior: `work/menu-guard-build/receivepacket-behavior.json`.
- Main-menu behavior: `work/menu-guard-build/main-menu-behavior.json`.
