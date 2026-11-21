# Exact C restoration progress

The frozen full report covers the complete **414,639-byte CODE segment**.
Attribution retains all four categories:

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 142,081 | 34.27% |
| Inline assembly instructions in C objects | 24,259 | 5.85% |
| Standalone assembly | 246,908 | 59.55% |
| Unattributed instructions and non-routine tables | 1,391 | 0.34% |

The unattributed category contains **1,038 instruction bytes in 22 unknown
routines** and **353 non-routine bytes**. The audit does not credit these bytes
to C or assembly. Remaining assembly, including inline: **271,167 bytes
(65.40%)**.

C-object inventory, including inline assembly, covers **167,731 bytes
(40.45%)**. The inventories contain **1,192 C routine spans** and **491
assembly routine spans**; attribution remains unresolved in 22 C spans.

The latest accepted zero-stage work removes **22 inline bytes across five
existing functions**: `draw_menu_text_` (2), `shutdown_video_engine_` (2),
`system_` (2), `format_engine_` (14), and `split_path_` (2). `system_` is now
**105 native bytes and 0 inline bytes**; the other four functions remain mixed.
Full validation records **316 unit tests and 109 fixtures**. Game smoke was
skipped.

## Reproducible evidence

The accepted executable is **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
The report scope is verified saved artifacts; check current source freshness
with `restore.py doctor`.

- Full validation: `work/zero-stage-build/validation.json`.
- Attribution audit: `work/zero-stage-audit.json`.
- Verified change packet: `work/zero-stage-writer.json`.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
