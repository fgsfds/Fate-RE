# Build Engine source references

Use upstream source to recover algorithms, names, signedness, structures, and
loop ordering before translating more engine assembly. Source similarity is not
proof of binary identity: every production change must still match Fate's
original instruction bytes and LE relocation sites/targets.

See [additional reviewed repositories](ADDITIONAL-BUILD-SOURCES.md) for pinned
Redneck, Blood, and alternate Duke sources, duplicate-source checks, and concrete
version differences.

## Pinned vanilla_duke3D reference

- Repository: <https://github.com/fabiensanglard/vanilla_duke3D>
- Reviewed revision: `05ba48edb2da5b3256736039b03a853e1ea0ceef`
- `SRC/ENGINE.C` SHA-256:
  `73deb68fc2dc07dc668febbf70ab55441c8b9221cd541fb49792688b1de09760`
- `SRC/drawing_routines/A.C` SHA-256:
  `2feddec08525545b8e64389d95ac2bc7d783b75d8512499b801b47a9ab434c34`

The downloaded reference files and URL/hash manifest live under ignored
`work/build-source-reference/`; they are not a second build or link input.
Preserve Ken Silverman's attribution and applicable `BUILDLIC.TXT` terms when
adapting source. The repository already contains the Build license.

### Pinned networking provenance

The `netsend` implementation in `src/network/netsend.c` follows `MULTI.C`
from `BuildEngine.zip/SRC.ZIP` in `commercial-game-sources/duke_nukem_3d`
at commit `e75bb067c0d3eba8f716b7781a5c5b6ec93cc2d4`;
the archived member SHA-256 is
`1dae938eb772e05e424c0185ef6ea83745ea62ba8bb7528846f3a82a77bf467f`.
The accepted object matches **629 bytes and all 57 LE sites/targets** with no
inline assembly. Reuse hint: ordinary `char` byte stores preserve conservative
pointer-alias reloads; casting unsigned subtraction to signed before shifting
preserves defined wrapping and target arithmetic-shift behavior.

The `sendpacket` implementation in `src/network/sendpacket.c` also follows
`MULTI.C`: **1,177 bytes and all 62 LE sites/targets** match without inline
assembly. Widening its byte comparisons reproduces the target instructions.
Peer -1 history reads use explicit target-linked DS overlays, rather than
separate portable objects: `omessleng[-1]` aliases `omessnum[12..15]`.

The `getpacket_` implementation in `src/network/getpkt.c` follows the same
pinned `MULTI.C`. It is included by `netinitconnection.c` after the initializer,
letting Watcom generate the shared-return jump. Casting the CRC representation
to unsigned avoids left-shifting a negative short. Input/storage contracts are
in source: `0xff` broadcasts from local are excluded because the historical
parser leaves `j` uninitialized on that path.

`processreservedmessage` in `src/network/netctrl.c` restores the complete
**719-byte control handler and all 27 LE sites/targets** from the same source.
Accurate GS-preservation contracts retain the compiler's common-return folding.
The linker validates each original condition and in-object target before
rebasing the 14 shared-return branches; it changes displacement operands only.

The serial network initializer in `src/network/serialin.c` follows the same pinned `MULTI.C`
provenance as `netsend`: its exact body is 648 bytes, with a 16-byte CODE
table, and all 46 LE sites/targets match (42 body sites and 4 table sites).
Its 629 native bytes and 19 inline-I/O bytes are reported separately; inline
I/O remains necessary at the hardware boundary.

### Concrete correspondences and cautions

`SRC/ENGINE.C:1270-1288` and the corresponding floor block at 1436 onward
corroborate double-size texture shifts, axis transposition, and orientation
flips. Fate's continuation objects retain their original shared frame and
register conventions. The current ceiling/floor cleanup generates the transpose
load/store and double-scale increment from C, preserving access order with
volatile lvalues and an empty EDX lifetime boundary. This is not a claim that
the entire renderer continuation is ordinary C.

`SRC/ENGINE.C`, lines 2793–2828, contains `copytilepiece`. It corroborates Fate's
dimension tests, source-first lazy tile loading, column-major copy order,
transparent value 255, source wrapping, and destination clipping. Its forward
pixel accesses are important when buffers overlap: a snapshot copy/memmove is
not equivalent.

The adapted source is now the production `src/engine/copytilepiece.c`: **336
bytes and all eight LE sites/targets match, without inline instructions**.
Pinned Watcom 10.5 `/4r /s /or /bt=dos` reproduces it when the original `char dat`
is kept and the condition explicitly widens `(unsigned long)(unsigned char)dat`
before comparing with 255. The unchanged expression shrinks to a byte comparison;
changing only char signedness instead gives MOVSX rather than MOVZX. Widening
the local rather than the expression also changes allocation. These are
code-generation clues preserved in the successful source, not reasons to retain
the old inline implementation.

`SRC/ENGINE.C:766-782` supplies `bunchfront`: reject disjoint screen-X ranges,
then walk the earlier-starting bunch's `p2` chain until its right edge overlaps
the later start. Equal starts select `wallfront(first_scan, second_scan)`.
The production `src/engine/bunchfront.c` now matches all 154 bytes and LE
sites/targets as ordinary C, using only the `wallfront` call's ABI pragma.
Preserving the historical declarations and expression order also removes all
of the previous register-helper functions, not just their instruction strings.
The independent fixture verifies selected call arguments using interval lists
and deliberately noncontiguous scan indices, not a transcription of the C.

`SRC/ENGINE.C:2779-2790` is **not** Fate's square-root table initializer:
the published version has 4,096 entries, `msqrtasm`, and a shift lookup, whereas
Fate builds 2,048 nearest-root entries using Newton iteration and squared-error
correction for `index << 20`. The production `initksqrt.c` retains that older
algorithm. Its C arithmetic cleanup removes 27 inline bytes while preserving
all 144 bytes and LE sites/targets; the fixture checks every table entry against
an independent integer-square-root oracle, output guards, and the shared return.

`SRC/drawing_routines/readme.txt` identifies `A.C` as a C port originally made in
June 1996, with later fixes. It explicitly says it is **not an exact replacement
of A.ASM**, omits optimized four-column variants, and warns that its `ksqrt` and
`krecip` substitutes can desynchronize original demos/network games. Use those
implementations for understanding, not as drop-in exact replacements.

Prefer this historical source for engine-level algorithms; consult modern ports
only when needed to clarify semantics. Neither Duke game code nor modern port
behavior should override differences proven in Fate's executable.
