# Exact C restoration progress

The current saved attribution audit covers all 414,639 CODE bytes and includes 560 compiler units. Saved full validation passed 398 tests and 138 fixtures; the 741,347-byte executable is byte-identical to the pinned reference.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 156,451 | 37.732% |
| Inline assembly instructions in C objects | 24,311 | 5.863% |
| Standalone assembly | 232,470 | 56.066% |
| Unattributed instructions and non-routine tables | 1,407 | 0.339% |

The unattributed category contains 1,038 instruction bytes in 22 unknown routines and 369 non-routine table bytes. The audit does not credit these bytes to C or assembly. Combined remaining assembly, including inline assembly: 256,781 bytes (61.93%). C-object inventory covers 182,169 bytes (43.93%) and 1,361 C routine spans; the assembly inventory has 486 spans.

The accepted executable is 741,347 bytes, SHA-256 `61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.

Ripple animation is entirely compiler-generated C: all 855 image bytes
(100% of the routine), including count clamp 22, masked row 32, top/bottom border
40, corner stores 45, X-slot update 17, Y-slot update 33, pixel floor 14,
radius advance/removal 73, and four
stencil sums totaling 152. The sums reuse one 38-byte compiler body;
distinct selected compiler instructions total 712 bytes. Forty compiler
RETs remain unlinked and guarded. The border context also excludes its
private ESI save/copy/restore and identity EDX copy. The C phases have
37 LE sites, no inline instructions and no remaining assembly bytes.
The assembly source and its production registration have been removed.
Radial setup/sample contribute 107 bytes and seven LE sites; packing
adds 44 bytes without relocations. The radial fixtures check 9,600 setup and
7,680 sample cases, including raw unsigned arithmetic and the original frame
fields. Packing checks 18,432 bounded ABI cases with exhaustive low bytes
and sampled partial lanes. Compiler-generated EBP handoffs satisfy both getter
contracts; matching word-array declarations keep scalar table loads defined.
Vertical border bodies add 46 bytes around a shared C INC EBP; output row setup
and word storage add 39 bytes. Signed output guards and frame advance add
28 bytes, three row increments add three, and the masked-row handoff adds
seven. A public EBP output contract matches the increments without an EBP
input or modify declaration. The word guard starts a separate translation
unit to prevent a shared-RET optimization from changing its branch.
Bookkeeping now adds 41 image bytes: countdown 4, radial slot/Y handoffs
9, three row resets 6, and tile/step/stencil register handoffs 22. These
reuse one two-byte reset body and preserve raw first-sum upper bits.
Frame/control restoration adds 69 bytes: seven stack-index sites 21,
frame allocation/release/return 7, guard predicates/sample step 25,
last-slot initialization 6 and two RNG calls 10. Complete context-byte
and zero-fixup guards preserve the local frame and private shared tails.
The new stack fixture passes 248 register/frame/flag/continuation cases
and rejects six valid-checksum OMF mutations to private compiler context.
The final 43 bytes cover twelve register saves/restores and eleven
transfers from a complete, readable C algorithm context. Its 865-byte
public supplies only those selected bytes; exact phase contexts supply
the other 812 production bytes. The private 822 context bytes receive no
coverage credit. A raw CODE digest and all 39 fixup targets/addends guard
the context; the verifier pins compiler branch targets and places their
displacements without changing opcode widths. This is a restoration via
selected C contexts, not a standalone 855-byte compiler public.
The final control fixture checks 399 edge cases and two save/restore
cases, and executes 32 private-model plus 32 production cases against
the same independent toroidal oracle. Six mutation controls cover private
code, symbolic references, addends and compiler/production destinations.
The vertical fixture passes 516 mixed-context
cases. Output checks all 128 row/end-pointer states, 64 aligned/unaligned
word stores, 32 branch/increment/handoff cases, and two handoff mutations. Both output modes compare the entire
plane; store cases also compare the full tile. The +16 scratch access changes
one byte, while output setup writes the original +4 pointer field.
The independent toroidal oracle passes 32 synthetic full-routine cases,
including creation/removal, the entire bordered buffer and padding guards,
counter wraparound, and preserved general-purpose registers. Isolated
fixtures cover 33 count cases, 16 masked rows, 16 border cases, 68 sums,
192 Y-slot cases, all 256 pixel values, and 1,584 radius cases (all active
count/slot pairs at radii 1/9/10). Self-removal copies the incremented
radius as in the reference. The radius oracle records the ordered count,
X, radius and Y writes; swapping count/X stores must fail that exact
assertion even though final state agrees. Sixteen machine controls and two
valid-checksum OMF guard controls are rejected. Another 192 natural X-slot
cases and 96 interleaved countdown cases check the retained EBP bookkeeping.
Sixteen natural and 16 interleaved corner cases check ESI/EBP handoffs
and the final padding-byte destination. Flags are covered by exact production
bytes rather than equality between standalone and interleaved forms. Source, whole-array/plane,
padding, stack, pointer handoffs, and live general-purpose register outputs
are checked by the relevant cases.

`update_level_sector_puzzle_` is restored in readable C: 932 bytes and 59 LE sites, with no inline instructions. One C translation unit compiles twice into three selected phases (410/64/458 bytes); five existing branch edges change displacement only. Neither full compiler public matches by itself. Its differential fixture passes 128 cases and rejects both activation-tag and exit-destination code mutations.

The encounter links 1,078 compiler-generated body bytes and 57 LE sites from five private contexts of `encounter_exit.c` and a standalone reset, with no inline assembly. The exit phase contributes 261 bytes, the latch phases 138, frame operations 56, the second actor update 114, actor decisions 73, and the reset 22. The new trigger/sector/clock phase contributes 277 bytes and 15 LE sites. Four selected slices retain both sound calls and the original placement of the EDI clear; the pinned sound callee preserves ESI/EDI/EBP. Its oracle passes 432 model cases, compares natural compiler order with linked order for all cases, and rejects tag, sound-ID, and sector-tag mutations. Two branch edges into the tile latch change displacement only. The new loop context adds 137 bytes and one LE site for setup, position selection, coordinate/sector handoff, sprite indexing, and the loop guard. Its oracle passes 259 model and natural-position-order cases, three code mutation controls, and a control for the omitted redundant MOVSX. The retained setup initializes EBP to the Z invariant before the getter reads it; the private duplicate index extension is guarded and excluded. Two further branch edges retain their widths after placement.

The latch oracle passes 360 cases and two mutation controls, the actor oracle 320 cases and three controls, and the frame oracle four cases with typed-CODE-pointer and POP-register controls. The original 184-byte frame and six saves remain. PUSH/POP EBP retain two assembly instructions; C supplies the surrounding frame setup, release, and register restoration. Remaining encounter assembly is 178 sprite-attribute bytes, the five-byte EBP height initializer, those two EBP save/restore bytes, and 160 table bytes. Private C publics are 1,225, 1,249, 1,249, 1,260, and 1,266 bytes, each preceded by a guarded 160-byte literal prefix. Only selected slices link, and the private prefixes receive no C credit.

Video-mode setup links 671 bytes and 56 LE sites from C contexts. The 129-byte display reset contains 121 compiler-generated bytes and eight bytes from four inline bulk clears. The palette lookup loop adds 19 compiler-generated bytes and one LE site, with EBX preserved by empty ABI identities. Its three guarded slot-range cases and two mutation controls pass. The planar backend geometry adds 63 compiler-generated bytes and five LE sites, with eight cases checking page counts, chain flags, output registers, and the zero flag consumed by the retained branch. Two geometry mutation controls pass. Six framebuffer allocation phases add 208 compiler-generated bytes and 15 LE sites, including shared error handling and the direct VGA framebuffer assignment. Fourteen allocation cases and two mutation controls check all backend modes and allocation failures. Ten checked compiler branch edges retain their original opcode widths after placement. The padded-width entry and shared finish/return add 15 compiler-generated bytes and one LE site. Two return cases and a POP-register mutation control check the saved registers and stack cleanup. The original switch table, stereo state stores, and EDI/EBP saves stay in assembly. The thirty-five-case fixture checks both horizon allocation failures, the palette handoff, reset buffer guards, and backend selection state.

The screenshot encoder uses 445 compiler-generated bytes and 44 LE sites for PCX geometry, filename and file operations, and the planar palette byte calculation and stores. The 27-case fixture checks header guards, filename digits, file-call arguments and return values, sequence wraparound, and the palette handoff. The 874-byte assembly remainder includes the pixel loop, palette control flow and flushing, and the shared return.

The masked renderer projection links 359 exact bytes with 25 LE sites from the historical Build C context. Marker verification attributes 309 bytes to the compiler and 50 to five inline helper invocations. The next instruction remains the original assembly jump into the 930-byte sort and draw continuation.

The receiver has 916 native C bytes, 0 retained ASM bytes, and 65 LE sites, with no inline assembly. Its behavior oracle passes 104 cases and two controls. Private RETs remain unlinked and guarded.

`getpacket_` has 1,429 native C bytes, 0 retained ASM bytes, and 80 LE sites. Its behavior oracle passes 110 cases and three controls. Both routines use selected compiler contexts; neither full main public is byte-identical by itself.

`dispatch_main_menu` has 507 C-linked image bytes and 2 retained ASM body bytes, with 30 C LE sites. Four instruction-aligned C phases cover source bytes 0–41 once. The original 32-byte jump table and alignment byte remain assembly; the checked compiler table is unlinked. Watcom emits the shared guard once, linked at two disjoint original addresses: this adds 13 linked image bytes and zero new unique compiler bytes. The only body blocker is the final 2-byte false-path JMP: Watcom merges the source flow, so keep its original opcode width. The behavior oracle passes 1,442 cases and two controls.

## Reproducible evidence

The saved full validation and audit artifacts verify the pinned image:

- Full validation and 138 fixtures: `work/palette-loop-check/validation.json`.
- Encounter frame behavior: `work/encounter-frame-build/encounter-frame-behavior.json`.
- Video initialization handoff: `work/setmode-display-handoff.json`.
- Ripple parent and C sum behavior: `work/palette-loop-check/ripple-texture-behavior.json`.
- Ripple stack/control ABI: `work/palette-loop-check/ripple-stack.json`.
- Complete ripple control/model: `work/palette-loop-check/ripple-control.json`.
- Attribution audit: `work/ripple-complete-audit.json`.
- Unit test log: `work/palette-loop-check/logs/unit-tests.log`.
- Encounter loop setup and position phase: `work/encounter-loop-build/behavior.json`.
- Encounter trigger/sector/clock phase: `work/encounter-spawn-build/behavior.json`.
- Encounter actor decisions: `work/encounter-reset-probe/behavior.json`.
- Encounter latch behavior: `work/encounter-latch-build/encounter-latch-behavior.json`.
- Puzzle exact slices, relocations, and behavior: `work/sector-puzzle-build/sector-puzzle-behavior.json`.

Earlier routine-specific artifacts remain available:

- Receiver behavior: `work/menu-guard-build/game-receive-behavior.json`.
- Getpacket behavior: `work/menu-guard-build/receivepacket-behavior.json`.
- Main-menu behavior: `work/menu-guard-build/main-menu-behavior.json`.
