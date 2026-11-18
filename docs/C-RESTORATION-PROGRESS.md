# Exact C restoration progress

The latest marker audit covers the full **414,639-byte CODE segment**.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 139,543 | 33.65% |
| Inline assembly instructions in C objects | 23,233 | 5.60% |
| Standalone assembly | 250,700 | 60.46% |
| Unattributed instructions and non-routine tables | 1,163 | 0.28% |

Known remaining assembly, including inline: **273,933 bytes (66.07%)**.
The unattributed category contains 810 instruction bytes in eleven routines
whose marker comparison is unsupported or changes output, plus 352 jump-table
bytes and one alignment byte. It must not be silently counted as either
C-generated instructions or assembly. In particular, the 26-byte
`clearallviews_vga_planes_` span remains unknown; its old 22/4 C/inline split
cannot be reused after the changed translation unit.

At the object/inventory level, C objects cover 163,939 bytes (**39.54%**), including
the inline instructions above. Standalone assembly covers the other **60.46%**.
The inventory has 1,124 C routines and 535 remaining assembly routine spans.

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

The measured build and marker report are under `work/restoration-build/` and
`work/dsh-r5-pixel-audit.json`. The audit reuses the checked distinct-end
marker retry for unchanged `flttrunc.obj`.
The accepted executable is 741,347 bytes with SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) to reproduce the
audit and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
