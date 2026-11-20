# Exact C restoration progress

The checked attribution covers the full **414,639-byte CODE segment**.

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 140,120 | 33.79% |
| Inline assembly instructions in C objects | 24,281 | 5.86% |
| Standalone assembly | 248,847 | 60.02% |
| Unattributed instructions and non-routine tables | 1,391 | 0.34% |

Known remaining assembly, including inline: **273,128 bytes (65.87%)**.
The unattributed category contains **1,038 instruction bytes in 22 routines**,
plus 352 jump-table bytes and one alignment byte. These bytes are not credited
to C or assembly; the audit lists the affected spans.

C objects cover **165,792 bytes (39.98%)**, including their inline assembly.
The inventory has **1,189 C routine spans** and **494 assembly routine spans**.
A C object does not imply compiler-generated instructions throughout.

The latest batch replaces **58 inline bytes** in `initialize_color_lookup_` with
C small-count, bulk and tail control. The complete routine matches **490 bytes
and 23 LE sites/targets**, with **263 generated / 227 inline bytes**.
Original alignment guards and string stores remain inline: compiler lowering
of the full address tests otherwise overwrote the zero fill value.

## Reproducible evidence

The latest source-only batch passed the exact whole-executable build gate,
both complete C/assembly span inventories, and the palette fixture's four
original and four restored cases. The prior broad checkpoint, commit `2b24784`,
passed **301 unit tests and 106 fixtures**. No game smoke was run.

- Build and current exact validation: `work/palette-clear-build/`.
- C/assembly inventories: `work/palette-clear-build/c.json` and `work/palette-clear-build/assembly.json`.
- Attribution: `work/palette-clear-audit.json`.
- Marker objects: `work/palette-clear-markers/` and fresh distinct-end retries in `work/palette-clear-retry/`.

Actor-common research remains excluded from coverage. A pure C draft passes
274 original/candidate behavioral cases, but its code is still nonmatching:
679 bytes for the death-phase draft and 709 for combined vector/attack edits,
versus 697. See the attempts and ignored scratch handoff before resuming.

The accepted executable is **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
