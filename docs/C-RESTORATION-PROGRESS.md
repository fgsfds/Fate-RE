# Exact C restoration progress

The latest marker audit covers the full **414,639-byte CODE segment**.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 139,364 | 33.61% |
| Inline assembly instructions in C objects | 23,318 | 5.62% |
| Standalone assembly | 250,794 | 60.48% |
| Unattributed instructions and non-routine tables | 1,163 | 0.28% |

Known remaining assembly, including inline: **274,112 bytes (66.11%)**.
The unattributed category contains 810 instruction bytes in eleven routines
whose marker comparison is unsupported or changes output, plus 352 jump-table
bytes and one alignment byte. It must not be silently counted as either
C-generated instructions or assembly. In particular, the 26-byte
`clearallviews_vga_planes_` span remains unknown; its old 22/4 C/inline split
cannot be reused after the changed translation unit.

At the object/inventory level, C objects cover 163,845 bytes (**39.52%**), including
the inline instructions above. Standalone assembly covers the other **60.48%**.
The inventory has 1,123 C routines and 536 remaining assembly routine spans.

In `initialize_color_lookup_`, the red-distance multiply and neighbor-loop
arithmetic move 31 bytes from inline assembly to compiler-generated C. The
490-byte routine and all 23 LE relocation sites and targets match. In
`grouscan_wall_length_`, Watcom now emits the two-byte shift-count copy;
all 279 bytes and 21 LE relocation sites and targets in its unit still match.

The measured build and marker report are under `work/restoration-build/` and
`work/dsh-next-geometry-audit.json`. The audit reuses the checked distinct-end
marker retry for unchanged `flttrunc.obj`.
The accepted executable is 741,347 bytes with SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) to reproduce the
audit and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
