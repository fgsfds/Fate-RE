# Exact C restoration progress

The frozen full report covers the complete **414,639-byte CODE segment**.
Attribution retains all four categories:

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 142,059 | 34.26% |
| Inline assembly instructions in C objects | 24,281 | 5.86% |
| Standalone assembly | 246,908 | 59.55% |
| Unattributed instructions and non-routine tables | 1,391 | 0.34% |

The unattributed category contains **1,038 instruction bytes in 22 unknown
routines** and **353 non-routine bytes**. The audit does not credit these bytes
to C or assembly. Remaining assembly, including inline: **271,189 bytes
(65.40%)**.

C-object inventory, including inline assembly, covers **167,731 bytes
(40.45%)**. The inventories contain **1,192 C routine spans** and **491
assembly routine spans**; attribution remains unresolved in 22 C spans.

The accepted `update_menu_selection` source (`src/fate/update_menu_selection.c`)
produces **595 native bytes, 0 inline bytes, and 35 LE sites**. It passes
full validation with **316 unit tests and 109
fixtures**, including **470 menu-selection behavior cases**. Game smoke was
skipped.

## Reproducible evidence

The accepted executable is **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
The report scope is verified saved artifacts; check current source freshness
with `restore.py doctor`.

- Full validation: `work/menu-selection-build/validation.json`.
- Attribution audit: `work/menu-selection-audit.json`.
- Menu-selection fixture: `tools/check_menu_selection.py`.
- Accepted source: `src/fate/update_menu_selection.c`.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.