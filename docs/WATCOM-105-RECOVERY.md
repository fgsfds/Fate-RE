# Intact Watcom 10.5 recovered from installer packages

## Root cause and recovery

The Watcom 10.5 installation disc contains an alternate copy of the
compiler in its floppy installation packages. DISKIMGS/DISK01/SETUP.INF maps
DISK02/PCK00017.1 plus DISK03/PCK00017.2 to wcc386.exe. Concatenated size: 357439.
Its SHA-256 is
`ee1b23125a9ab9a491df621e9d48dcadecfa82c617bf7844616ffc1bc7291463`.

The WPACK header has signature 0x2403, version 1.1, one file and a 27-byte info
record at offset 357412. That record describes a 567558-byte wcc386.exe with
compressed data beginning at offset 12. CRC-32 of the compressed payload is
0x4e91cf76, exactly its stored CRC.

Decoded compiler SHA-256:
`1b97a68f7b8a3efd89b05f64ce99836b1e533f398699305f96dc423254939d6a`.
Its first 65536 bytes exactly equal the ordinary BINW/WCC386.EXE on the disc.
Thus the earlier ordinary file really is a truncated compiler, not merely a
missing-installation hypothesis. The intact packaged file identifies itself as
Watcom C32 10.5 and compiles successfully under DOSBox.

## Reproduction and decoder provenance

Extract the two PCK files from the pinned ISO to reference/watcom105-full,
preserving their DISKIMGS/DISK02 and DISK03 paths. Obtain official decoder sources
from https://github.com/open-watcom/open-watcom-v2 at commit
`29a0323978834da7599500a1ed208fa4303f2ea5` in reference/open-watcom-v2.
Only bld/wpack is needed by the recovery utility.
The utility defaults to `C:/msys64/mingw64/bin/gcc.exe`. Use `--cc` to
specify another GCC installation.

```powershell
python tools/recover_watcom105.py
```

The recovery utility checks the package hash, record fields, compressed CRC and
official decoder source hashes. It builds the decoder core with its original
stable quicksort (equal-length code ordering matters), using GCC with bounded
file I/O. It retains the upstream license in generated scratch source and checks
the complete recovered compiler hash before writing the usable reference copy.
The exact build bundles the recovered compiler. The generated decoder
source stays in the working directory.

The original DOS loader W32RUN.EXE SHA-256 is
`f3b2864d171319728baaf95c1188e7b98d5b9ce2bb13768b5272e3ec5c94f4f4`.
It is copied from the verified disc, checked and used alongside the compiler.
The recovery utility and the DOS compiler were both executed successfully.

## Installation inputs

Extract the Watcom 10.5 CD to `reference/watcom105-full`, including its
`DISKIMGS` and `LIB386/DOS` directories. The verified distribution archive has
SHA-256 `57a0d9ef63e51c9a9ee443664f54e46589019fc43b882997a290fef1076da677`.
The recovery tool writes the checked DOS compiler and loader under
`reference/watcom105-recovered/binw`.
[Watcom 10.5 distribution](https://winworldpc.com/product/watcom-c-c/105)

Place the Windows DOSBox 0.74-3 installation under `reference/dosbox`, with
`DOSBox.exe`, `SDL.dll`, and `SDL_net.dll` together. The checked
Windows executable has SHA-256
`dcfd46fa521f5ce89dce3bf026056f3a1d15533f80321ee887403e30d7949f5e`.
The driver mounts its generated build directory and runs the compiler there.
[DOSBox 0.74-3 Windows distribution](https://sourceforge.net/projects/dosbox/files/dosbox/0.74-3/)

The [exact build](EXACT-BUILD.md) ships the recovered compiler and DOSBox.
The external inputs above reproduce the compiler recovery.

## Comparing runtime objects

With Watcom 11.0c installed under `reference/watcom110c`, use its WLIB to
extract members from both pinned runtime libraries. Set `$original` to the
demo executable as shown in the [build guide](EXACT-BUILD.md).

```powershell
$wlib = 'reference/watcom110c/binnt/wlib.exe'
New-Item -ItemType Directory -Force work/clib105, work/clib110c | Out-Null
& $wlib '-d=work/clib105' -x reference/watcom105-full/LIB386/DOS/CLIB3R.LIB
& $wlib '-d=work/clib110c' -x reference/watcom110c/LIB386/DOS/CLIB3R.LIB
python tools/research_startup.py $original --output work/startup.json
python tools/compare_runtime_core.py $original --output work/runtime-core.json
```

These reports record runtime member provenance, startup bindings, and the
matching bytes in the selected runtime routines.
