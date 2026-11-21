# Exact C restoration progress

The frozen full report covers the complete **414,639-byte CODE segment**.
Attribution retains all four categories:

| Checked attribution | Bytes | CODE |
| --- | ---: | ---: |
| Compiler-generated instructions | 150,113 | 36.20% |
| Inline assembly instructions in C objects | 24,234 | 5.84% |
| Standalone assembly | 238,901 | 57.62% |
| Unattributed instructions and non-routine tables | 1,391 | 0.34% |

The unattributed category contains **1,038 instruction bytes in 22 unknown
routines** and **353 non-routine bytes**. The audit does not credit these bytes
to C or assembly. Remaining assembly, including inline: **263,135 bytes (63.46%)**.

C-object inventory covers **175,738 bytes (42.38%)**, including **24,234
inline-assembly bytes**. The inventories contain **1,202 C routine spans** and
**486 assembly routine spans**; attribution remains unresolved in 22 C spans.

The network control handler adds **719 native C bytes, zero inline bytes,
and 27 LE sites**. Full validation passes **335 unit tests and 118 fixtures**
across **521 compiler units**. Its behavior fixture passes **70 cases and
three negative controls**. The tooling follow-up leaves C/assembly attribution unchanged.

## Reproducible evidence

The accepted executable remains **741,347 bytes**, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
The report scope is verified saved artifacts; check current source freshness
with `restore.py doctor`.

- Latest full validation: `work/ci-timeout-build/validation.json`; executable SHA unchanged.
- Network control fixture: `work/ci-timeout-build/netctrl-behavior.json`.
- Unchanged C attribution audit: `work/netctrl-audit.json`.
- C restoration packet: `work/netctrl-handoff.json`.

See [reconstruction](RECONSTRUCTION.md#inline-assembly-audit) for reproduction
and [open probes](C-RESTORATION-ATTEMPTS.md) for unresolved work.
