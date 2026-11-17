# Exact C restoration progress

The latest marker audit covers the full **414,639-byte CODE segment**.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 138,580 | 33.42% |
| Inline assembly instructions in C objects | 23,645 | 5.70% |
| Standalone assembly | 251,251 | 60.60% |
| Unattributed instructions and non-routine tables | 1,163 | 0.28% |

Known remaining assembly, including inline: **274,896 bytes (66.30%)**.
The unattributed category contains 810 instruction bytes in eleven routines
whose marker comparison is unsupported or changes output, plus 352 jump-table
bytes and one alignment byte. It must not be silently counted as either
C-generated instructions or assembly. In particular, the 26-byte
`clearallviews_vga_planes_` span remains unknown; its old 22/4 C/inline split
cannot be reused after the changed translation unit.

At the object/inventory level, C objects cover 163,388 bytes (**39.40%**), including
the inline instructions above. Standalone assembly covers the other **60.60%**.
The inventory has 1,122 C routines and 537 remaining assembly routine spans.

The measured build and marker report are under `work/whole-net-build/` and
`work/whole-net-audit.json`. The accepted executable is 741,347 bytes with
SHA-256 `61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) to reproduce the
audit and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
