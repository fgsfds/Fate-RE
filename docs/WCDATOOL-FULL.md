# Full wcdatool disassembly and a validated dispatch-table hint

The pinned wcdatool pipeline completed native wdump extraction, LE fixup
decoding, objdump disassembly, annotation, and deduplication for both LE
objects. The results establish the instruction and pointer boundaries of
the START dispatcher.

## Reproducible wdump build

Open Watcom source: https://github.com/open-watcom/open-watcom-v2, revision
`29a0323978834da7599500a1ed208fa4303f2ea5`. Dumper sources are in `bld/exedump`.
In a sparse checkout at that revision, include these source directories:

```powershell
git -C reference/open-watcom-v2 sparse-checkout add bld/exedump bld/dip/watcom/h bld/watcom/c
& tools/build_wdump.ps1
```

The helper checks the revision and tracked source modifications, compiles the
unmodified C sources with local MinGW GCC 16.2.0, and links upstream leb128rd.c
and clibext.c. `BOOTSTRAP`, `__NT__`, `_BLDVER=1300`, and MinGW's getopt header
provide build/platform support. No decoding code was patched. The build passed
without diagnostics; [build provenance](../tools/data/wdump-build.json) records compiler/hash,
flags, source inventory and resulting executable hash. Native build timestamps
mean different output hashes need not imply decoder source changes. The upstream
Sybase Open Watcom license remains in the ignored source checkout; no third-party
source or executable is redistributed here.

## Relocation-only check

Use the pinned wcdatool checkout and the original executable from the
[build guide](EXACT-BUILD.md). This check does not need wdump or objdump.

```powershell
python tools/check_wcdatool_fixups.py $original --output work/wcdatool/fixups.json
```

The check reproduced all 23,359 relocation records at 23,350 distinct sites.

## Verified result

The wrapper expects [upstream wcdatool](https://github.com/fonic/wcdatool) revision `69c770f477652bf43c7b1237f9a9f2b72712b289`
in `reference/wcdatool` and defaults to MinGW objdump. After building wdump,
run it with `$original` from the [build guide](EXACT-BUILD.md).

```powershell
python tools/run_wcdatool.py $original --report work/wcdatool-full/report.json
```

The independent wdump check matched 13 LE header fields, both object records,
all 128 page-map entries and every initialized page byte. The checked hint
marks object-1 offsets `0xe74c..0xe7b0` (end exclusive) as DWORD data. The
25 entries agree with the original LE pointer fixups and the bounded
dispatch instruction. [Hint file](../tools/data/wcdatool-hints.txt) · [START dispatcher](START-HOOK.md)
