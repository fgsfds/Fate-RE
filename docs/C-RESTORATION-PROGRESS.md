# Exact C restoration progress

The latest marker audit covers the full **414,639-byte CODE segment**.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 139,814 | 33.72% |
| Inline assembly instructions in C objects | 23,432 | 5.65% |
| Standalone assembly | 250,055 | 60.31% |
| Unattributed instructions and non-routine tables | 1,338 | 0.32% |

Known remaining assembly, including inline: **273,487 bytes (65.96%)**.
The unattributed category contains 810 instruction bytes in eleven routines
whose marker comparison is unsupported or changes output, plus 352 jump-table
bytes and one alignment byte. It must not be silently counted as either
C-generated instructions or assembly. In particular, the 26-byte
`clearallviews_vga_planes_` span remains unknown; its old 22/4 C/inline split
cannot be reused after the changed translation unit.

At the object/inventory level, C objects cover 164,584 bytes (**39.69%**), including
the inline instructions above. Standalone assembly covers the other **60.31%**.
The inventory has 1,145 C routine spans and 532 remaining assembly routine spans.

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

The measured build and marker report are under `work/restoration-build/` and
`work/dsh-r10-grow-audit.json`. The audit reuses the checked distinct-end
marker retry for unchanged `flttrunc.obj`.
The accepted executable is 741,347 bytes with SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) to reproduce the
audit and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
