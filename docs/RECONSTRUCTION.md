# Executable layout and verification

The reconstructed target is the October 18, 1996 demo. The
[fingerprint inventory](../tools/data/reconstruction-fingerprints.json) identifies the original
inputs. [Build instructions](EXACT-BUILD.md) reproduce the complete executable.

## Measured executable layout

| Property | Measured value |
| --- | --- |
| DOS stub / LE header start | 0x2A50 (10,832-byte prefix) |
| LE module flags | 0x200 |
| CPU / OS fields | 2 / 1 |
| Module version | 0 |
| Entry | object 1 + 0x4FF08 = logical address 0x5FF08 |
| Stack top | object 2 + 2,663,168 |
| Objects | code at 0x10000; data/BSS at 0x80000 |
| Code virtual size | 414,639 bytes |
| Data/BSS virtual size | 2,663,168 bytes |
| Pages | 128 total, size 4,096; last page 2,531 bytes |
| Code/data page allocation | 102 / 26 pages |
| Physical CODE page start | 0x35600 |
| Code page padding before data | 3,153 bytes |
| Physical DATA page start | 0x9B600 |
| Stored DATA span | 104,931 bytes |
| Declared fixup section size | 206,632 bytes |
| Decoded relocation records | 23,359, from the earlier validated LE loader |
| Imported modules | 0; do not infer absence of runtime-loaded drivers |
| Resident module name | `fate`, ordinal 0 |
| Nonresident name table | absent |
| Declared debug offset/size | 0 / 0 |
| End of declared page data | 741,347, exactly EOF; no appended symbol block |
| Loader/fixup checksums | both 0 |

The 23,359 fixup records cover 23,350 distinct sites, with nine cross-page
duplicates. The [relocation inventory](../tools/data/le-relocation-order.json) records source
positions and target object numbers in page order. Target offsets are generated
from reconstructed operands.

## Build inventories and evidence

<!-- restoration-coverage:start -->
- [C CODE inventory](../tools/data/matching-routines.json) covers 1,176 routines
  and compiler-generated tables, totaling 165,702 bytes (39.96% of CODE).
  This includes mixed C/inline-assembly objects, not just assembly-free C.
- [Assembly CODE inventory](../tools/data/matching-assembly.json) covers
  248,937 bytes (60.04% of CODE).
- [Source DATA inventory](../tools/data/matching-initialized.json) covers
  95,547 stored bytes.
- [Watcom font dependency](../tools/data/matching-graphics-font-dependency.json) supplies
  9,384 stored bytes from the pinned `GRAPH.LIB`.
<!-- restoration-coverage:end -->

Source DATA includes 56,008 bytes of board navigation layouts built from C;
the font dependency comes from three pinned `GRAPH.LIB` members.

- The DOS prefix matches the first 10,832 bytes of the demo's `EDITART.EXE` and
  the June 6, 1996 archive copy. Its SHA-256 is
  `b852ae395b9ad04503fc907ad03fa28ea6a17bf5f6c2be045bf96f7177592699`.

The C, assembly, and source DATA inventories prescribe placement and pin the
hashes of generated spans. The font report records the provenance of data
read from GRAPH.LIB. The final size and SHA-256 checks cover the DOS prefix,
LE metadata, relocation encoding, page padding, and object bytes. The exact
original compiler version, translation-unit boundaries, and linker invocation
remain unidentified.

## Inline assembly audit

See [current attribution](C-RESTORATION-PROGRESS.md) for the measured split
between compiler-generated C, inline assembly, standalone assembly, and
unattributed bytes. The generated inventories above track object placement
and include mixed C and inline assembly.

Start with a successful exact build and its fresh `c.json` and `assembly.json`.
Run with Capstone on Python's import path and use the pinned DOSBox executable.

```powershell
python tools/stage_watcom_markers.py work/restoration-build work/inline-audit --dosbox <DOSBox.exe>
python tools/report_watcom_markers.py work/restoration-build work/inline-audit work/inline-audit.json
```

The first command compiles a disposable source copy with markers around
instruction-emitting Watcom auxiliaries. The report counts original bytes
after checking aligned instructions, branch targets, and relocation operands
against the marked objects. Watcom switch dispatches also require matching
table targets in their original order. Unsupported routines and non-routine CODE spans
remain unattributed. The production link uses the original objects.

The default markers can merge at shared branch joins. If the report lists
conflicting or unbalanced markers, retry those objects with distinct
end markers and add the retry directory to the report.

```powershell
python tools/stage_watcom_markers.py work/restoration-build work/inline-retry --dosbox <DOSBox.exe> --retry-report work/inline-audit.json
python tools/report_watcom_markers.py work/restoration-build work/inline-audit work/inline-final.json --retry-marker-dir work/inline-retry
```
