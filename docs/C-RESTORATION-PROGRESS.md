# Exact C restoration progress

The latest marker audit covers the full **414,639-byte CODE segment**.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 139,939 | 33.75% |
| Inline assembly instructions in C objects | 24,436 | 5.89% |
| Standalone assembly | 248,926 | 60.03% |
| Unattributed instructions and non-routine tables | 1,338 | 0.32% |

Known remaining assembly, including inline: **273,362 bytes (65.93%)**.
The unattributed category contains 810 instruction bytes in eleven routines
whose marker comparison is unsupported or changes output, plus 352 jump-table
bytes and one alignment byte. It must not be silently counted as either
C-generated instructions or assembly. In particular, the 26-byte
`clearallviews_vga_planes_` span remains unknown; its old 22/4 C/inline split
cannot be reused after the changed translation unit.

At the object/inventory level, C objects cover 165,713 bytes (**39.97%**), including
the inline instructions above. Standalone assembly covers the other **60.03%**.
The inventory has 1,179 C routine spans and 504 remaining assembly routine spans.

`bios_print_screen` now builds as one C function. All 3 bytes match: the routine
issues the original `int 5`, and the enclosing wrapper supplies the `ret`. The
span has no LE relocation sites or targets.

`get_audio_data_selector` now builds as one C function. All 4 bytes match: the
routine issues the original `mov ax,ds` (operand-size prefix included), and the
enclosing wrapper supplies the final `ret`. The span has no LE relocation
sites or targets.

`get_audio_code_selector` now builds as one C function. All 4 bytes match: the
routine issues the original `mov ax,cs` (operand-size prefix included), and the
enclosing wrapper supplies the final `ret`. The span has no LE relocation
sites or targets.

`truncate_float_zero` now builds as one C function. All 3 bytes match: the
routine emits the original `sub eax,eax`, and the enclosing wrapper supplies
the `ret`. The span has no LE relocation sites or targets.

`_enable_` now builds as one C function. All 2 bytes match: the routine emits
the original `sti` and the enclosing wrapper supplies the `ret`. The span has
no LE relocation sites or targets.

`wait_vertical_retrace` now builds as one 23-byte C function. All 23 bytes match:
the routine emits the original `xor edx,edx; xor eax,eax; xor dx,0x3da` setup,
the two `in al,dx`/`test al,8` wait loops with their short branches, the `loop`
back-edge, and `cld`; the enclosing wrapper supplies the final `ret`. The span
has no LE relocation sites or targets.

In `initialize_color_lookup_`, the red-distance multiply and neighbor-loop
arithmetic move 31 bytes from inline assembly to compiler-generated C. The
490-byte routine and all 23 LE relocation sites and targets match. In
`grouscan_wall_length_`, Watcom now emits the two-byte shift-count copy;
all 279 bytes and 21 LE relocation sites and targets in its unit still match.
The ceiling and floor wall-axis routines use the same C register copy,
moving four more bytes from inline assembly to compiler-generated C. Their
complete units match 1,741 bytes and 156 LE relocation sites and targets.
In the two `wallmost` square-root paths, volatile scratch conversion, table
reads, and register copies move another 80 bytes to compiler-generated C.
The complete `wallmost` unit matches 646 bytes and 42 LE sites and targets.
`release_empty_heaps_` now builds from a mixed C unit: 46 of its 94 bytes
are compiler-generated and 48 remain inline. The complete span and its LE
relocation match, including both interrupt paths and the shared return.
The ceiling and floor `begin_spans` paths move another 34 inline bytes to C
for texture shift loads and count copies. Their units match 1,540 bytes
and 145 LE relocation sites and targets.
The Hercules bank setup and the VGA, CGA, and Hercules color-count reloads
move another 15 inline bytes to C. The three paths match 356 bytes and 24 LE
sites and targets; the full `vgapix` unit matches 712 bytes and 51 LE sites.
`play_crusher_sound_` moves both wrapped negations (four bytes) to C while
keeping the original `TEST/JNS` encodings. All 89 bytes and three LE sites
and targets match.
`resize_dpmi_heap` now builds as nine C continuation spans sharing the
original frame. The 259-byte region and its LE site and target match;
159 bytes are compiler-generated and 100 remain inline.
`allocate_dpmi_heap` now builds as seven C continuation spans. The 211-byte
region and all three LE sites and targets match; 108 bytes are
compiler-generated and 103 remain inline, covering both DPMI and DOS paths.
`expand_separate_heap` now builds as five C continuation spans. All 175 bytes
and three LE sites and targets match, but its short backward branches exceed
the marker rel8 range, so its 175 bytes remain unattributed rather than split
into generated and inline.
`__set_binary_` now builds as six C continuation spans. All 101 bytes match;
31 bytes are compiler-generated and 70 remain inline across the handle mode
and device IOCTL paths.
`access_` now builds as two C continuation spans. All 59 bytes match; 20 bytes
are compiler-generated and 39 remain inline across the DOS 43h attribute
check and the carry-to-errno translation.
`mask_timer_irq` and `unmask_timer_irq` now build as one C function each. All
88 bytes match; 18 bytes are compiler-generated (the guard test) and 70 remain
inline (the shared prologue/epilogue and the 8259 port I/O).
`program_pit` now builds as one C function. All 70 bytes match; 9 bytes are
compiler-generated (the guard test) and 61 remain inline (the shared
prologue/epilogue, the 8259 mask/unmask, and the PIT divisor write).
`driver_command_5` and `driver_command_0` now build as one C function each. All
70 bytes match; they are 0% compiler-generated and 100% inline (the shared
prologue/epilogue, the `mov eax`, `lfs`, and the far call).
The remaining six HMI command wrappers (`driver_command_3`,
`driver_secondary_command_1`–`4`, and `driver_configure_secondary`) now build
as one C function each; all 254 bytes match, 0% generated and 100% inline.
`read_driver_parameters` now builds as one C function; all 68 bytes match, 0%
generated and 100% inline (the four parameter stores, `mov al,ch/cl`, `cbw`,
and the far call).
`windows_driver_interrupt` now builds as one C function; all 53 bytes match,
4 bytes generated (the `cmp al,3; jne` dispatch) and 49 inline.
`windows_driver_interrupt_stop` is the same dispatch with `mov al,0ch`; all 53
bytes match, 4 generated and 49 inline.
`get_driver_tables` now builds as one C function; all 63 bytes match, 0%
generated and 100% inline (the record/callback and selector stores plus the
far call).
`query_dpmi_memory` and `query_windows_version` now build as one C function
each; all 72 bytes match, 0% generated and 100% inline (the `int 2Fh`/`int 31h`
calls and the memory-info load).
`set_driver_callback` now builds as one C function; all 54 bytes match, 0%
generated and 100% inline (the callback table `shl`/`add` indexing and the two
far stores).
`release_dos_selector` now builds as one C function; all 46 bytes match, 0%
generated and 100% inline (the segment setup before the prologue plus the DPMI
0x101 release).
`configure_fpu` now builds as one C function; all 39 bytes match, 0% generated
and 100% inline (the pushed control word, the x87 infinity comparison, and the
requested control-word load).

The measured build and marker report are under `work/restoration-build/` and
`work/dsh-r27-fpu-audit.json`. The audit reuses the checked distinct-end
marker retry for unchanged `flttrunc.obj`.
The accepted executable is 741,347 bytes with SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) to reproduce the
audit and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
