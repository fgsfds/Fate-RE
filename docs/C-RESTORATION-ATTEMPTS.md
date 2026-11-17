# Fate C restoration attempts

Keep one entry per unresolved issue with the tested flags or variant, the
first meaningful mismatch, and any clue that would change the next probe.
Use pinned Watcom 10.5 in windowless DOSBox. Keep full logs and variant
sources in ignored scratch. Remove resolved entries when the exact fix
lands.

## Measured attempts

| Routine or variant | Watcom output | Result |
| --- | ---: | --- |
| `write_vga_palette`, C loop using Watcom `outp` intrinsic | 47 bytes | The reference is 27 bytes. Watcom emitted `mov`/load/`inc` sequences and a register-counter loop instead of `lodsb` and `loop`; the final `cld` is also assembly-specific behavior. |
| `setuphlineasm4_`, C rotate and patch stores | 71 bytes | The reference is 50 bytes. The shift/OR expression compiled as separate shifts and an OR instead of `rol`; updating the low byte of the second register became several bitwise operations instead of `mov bl,al`. |
| `step_interleaved_up/down`, 16-bit C arithmetic | 28 / 30 bytes versus 17-byte bodies | Watcom 10.5 ignored the `[di]` register parameter on these function definitions: it loaded the argument from the stack, emitted a separate `test` for the sign branch, and returned with `ret 4`. |
| `report_stack_overflow`, direct C wrapper | 18 bytes versus 15 | Watcom saved EDX around the call (`push edx` / `pop edx`) and emitted a trailing `ret`. Adding `__declspec(noreturn)` to suppress the return failed at compile time with Watcom error E1169 (`Invalid __declspec declaration`). |
| `strcpy_`, unrolled two-byte C loop | 33 bytes versus 31 | Watcom preserved the destination in EBX and used BL for the byte temporary; the original saves EAX/ECX and uses CL. The C object also reordered the second-byte store and used `test` instead of `cmp`. Two alternate register-clobber pragmas changed or retained the save sequence, but both kept the same 33-byte body shape. |
| `fill_byte_pattern`, pointer-loop translation with pattern rotation | 88 bytes; one 4-byte external fixup to `fill_dword_pattern_` | The reference body is 49 bytes. Watcom added EBX/ESI/EDI saves and a return-pointer epilogue, emitted shift/OR rotation instead of `ror edx,8`, and inserted extra count tests. The candidate call fixup is at object offset 50; the assembly uses an in-segment relative call at body offset 24, so the relocation form/site also differs. |
| `strcat_`, scalar C append loop | 31 bytes; no fixups | The reference is 55 bytes. Watcom saved EBX/ECX/EDX instead of ECX/ESI/EDI and emitted scalar scan/copy loops; the assembly saves/restores ES, uses `repne scasb`, then copies byte pairs. Only 1 byte matches at the same offset. |
| `copy_driver_record`, far-pointer C loop | 70 bytes; 4 data fixups | The reference is 74 bytes with 3 LE sites. Watcom accessed the far table through GS and emitted a byte-at-a-time loop; the target loads DS:ESI with `LDS`, preserves DS/ES/FS/GS, and copies 80 bytes with `REP MOVSB`. A far-memory intrinsic variant grew to 93 bytes and emitted an external helper call. The `/os` variant was 77 bytes with the same four fixups; it added an EBP frame but retained GS access and the scalar loop. |
| DOS DTA transfers, replacing the remaining byte copy with Watcom intrinsic `memcpy` | 49 bytes per direction with `/or`, 37 with `/os`, versus 35 | The speed form emits a dword copy and a byte remainder. The size form emits `push edi; repne movsb; pop edi`. The reference emits only `rep movsb` with a different repeat prefix, so the two-byte copy remains inline. |

## Engine source references

Consult the [pinned Build sources](BUILD-SOURCE-REFERENCES.md) first.
[Ken Silverman's Build source page](https://advsys.net/ken/buildsrc/default.htm)
and [icculus's portable raster routines](https://github.com/icculus/buildengine/blob/main/a.c)
help explain the algorithms. Fate's patched immediates, register contracts,
and string instructions still need independent byte and LE verification.

### `drawmasks`: historical source does not yet reproduce the sort

Source-backed scratch: `work/drawmasks-source/v041.c`, based on the pinned
`ENGINE.C:2830-2970`, compiled with Watcom 10.5 `/4r /s /or /bt=dos`.
The best candidate is 1,259 bytes versus 1,289, with 71 absolute bindings.
Only the first **359 bytes and their 25 LE sites** are verified exact; no partial
span is accepted into production.

Fate predates the published pointer-based sprite sorting: it uses packed
44-byte records, halving Shell-sort gaps, and in-sort stat-number/floor-Z ties.
The projection pass matches after those version differences and historical
arithmetic-helper ABIs are restored. The first byte mismatch is `+0x168`, the
displacement of the jump around the sort. The first body divergence is target
`+0x177`: `mov ebp,ecx` versus the candidate's load/add sequence. Target keeps the
sort index in EBP and sprite pointers in EBX/EDX; the compiler coalesces them
differently. First full LE discrepancy is candidate `spritesy` at `+0x180`
versus target `+0x187`/`+0x18e`. Matching relocation counts alone is insufficient.

The `/3r` and size-optimized probes change the entry/frame and do not improve
this. EBP-bound auxiliary parameters fail with Watcom E1122. Register keywords,
trig alias spelling, and record-scratch spelling did not recover the required
allocation. Next investigate the older comparator's expression/liveness and
translation-unit context: the target also shares a return epilogue with
`transmaskvline2`. Do not replace that branch with a private return or transcribe
the sort into inline instructions merely to increase the C-object percentage.

## Other unresolved probes

### Network control packet frame and dispatch

With Watcom 10.5 `/4r /s /or /bt=dos`, the whole C draft with corrected
register-call declarations emits 570 bytes versus 719. The first mismatch
at `+0x7` reserves eight stack bytes instead of four, then spills EAX and
holds the packet in EBP instead of EDI. Removing volatile qualifiers emits
605 bytes with the same frame mismatch. Next bind the incoming length to
ESI and packet to EDI, then recover the original opcode comparison order.
Scratch source and objects are in `work/network-control-candidate/`.

### Counted player effect: ordinary motion-call argument staging

With pinned Watcom 10.5 `/3r /s /or /oa /bt=dos`, replacing the staged motion
helpers with two C vector temporaries and a seven-argument register/stack ABI
produces 360 bytes versus the exact 374. The first body divergence is at `+0x68`:
the first sine load targets EDI instead of EAX. Watcom keeps the first component
in EDI, pushes the constants later, and emits CWDE instead of the original
SI-to-ESI extension. The 12 inline stack-load/store bytes remain in production.
An isolated C local store after the empty stack-argument helper is not a valid
substitute: the compiler no longer tracks the outstanding pushed argument and
addresses `[ESP]` instead of `[ESP+4]`. Next recover ordinary full-call register
lifetimes and argument scheduling; do not fake stack offsets with another local.
Probe object/log: `work/peffspn-next/`.

### Proximity sprite sight arguments: EBP is not a usable auxiliary parameter

A C height load bound through an empty `[ebp]` parameter auxiliary fails with
Watcom E1122, including when EBP is added to the caller's modify list. The
existing EBP load/push helpers remain; no nonmatching candidate was integrated.
Next investigate an ordinary full `cansee` argument declaration rather than
repeating unsupported EBP parameter constraints. Probe: `work/proxupd-next/`.

### Ripple table indexed stores

Pinned Watcom 10.5 `/4r /s /or /bt=dos` emits 183 bytes versus 181 for C dword
stores through typed arrays. It inserts `MOV EDI,ESI` and uses EDI instead of
the original ESI-scaled index. Empty EDI barriers or preservation constraints
grow the function to 186–188 bytes; explicit address arithmetic still yields
183. Defined four-byte intrinsic `memcpy` stores produce 296 bytes. Both inline
stores remain. Next recover the original index lifetime without changing the
declared backing storage contract. Details: `work/ripple-next/RESULTS.md`.

### Pixel store allocation

Separate EDI-pointer and AL-value constraints produce 100–104 bytes versus the
94-byte `plotpixel`, changing register allocation. The original store and VGA
port output remain inline. Next preserve the original color widening and
pointer lifetime through the shared store. Scratch: `work/pixels-next/`.

A later `/4r /s /or /bt=dos` scratch batch consumed a full-width EAX result
around the C store: the shared form grows to 115 bytes and spills the color
(`SUB ESP,4` at +3); branch-local `nomemory` forms reach 100 bytes but change
the prologue EDI/ESI allocation and add a BL-to-CH copy. A one-byte `memset`
intrinsic request preserves original allocation/widening through +41, then
emits `MOV ECX,1` and a call instead of an intrinsic store (107 bytes).
All variants preserve the 79-byte `getpixel`; none qualifies `plotpixel`.
Next investigate a supported single-operation intrinsic/register ABI rather
than separate consumed getters. Evidence: `work/dsh-r1-pixels/RESULTS.md`.

### Sector panning's partial-register copy

Replacing `MOV SI,DX` with empty unsigned-short DX/SI helpers produces
`MOV ESI,EDX`, shrinking the six-span object from 262 to 261 bytes. The full
register copy is not byte-identical and the original remains. Next require a
compiler idiom that retains the 16-bit operand-size prefix; do not repeat the
same register-only helper pair. Evidence: `work/sectpan-next/NOTES.md`.

### PCM pointer advancement and output bias

The C dword-source and mono/stereo destination increments succeed in PCM input.
The byte-source increment still emits `INC ESI` rather than the original
`ADD ESI,1`, so that helper remains. Candidate/log:
`work/pcminput-next/failed-all-advances.c`, `advance-c.log`.

PCM output C bias expressions choose shorter `XOR AH,80h` / `XOR BH,80h`
encodings and sometimes reorder operations. C pointer increments choose
`INC EDI`, reorder source advancement, or advance the stereo destination between
stores. These output candidates do not match, so none was integrated.
Next constrain the required full-width bias operation and store/advance
lifetimes rather than repeating plain expressions.
Evidence: `work/pcmoutput-next/attempt1-bias.*`, `attempt2-pointers.*`.

### Plane texture shifts: valid C count masking changes the bytes

The ceiling/floor transpose and double-scale cleanups succeeded and are omitted
from the failed list. A separate ceiling shift-helper probe used pinned Watcom
10.5 `/4r /s /or /bt=dos`. Replacing four register shifts with C using a
CL-valued getter adds three `AND ECX,0xff` instructions: the 255-byte
`ceilscan_begin_spans` span grows to 273 bytes.

A full ECX getter emits matching instructions but is rejected as C: the
register's upper bits need not be clear, making counts above 31 undefined.
Explicit `& 31` masking also changes the CODE size. The original eight inline
shift bytes therefore remain. Next require a compiler-supported masked-shift
idiom that preserves defined x86 count behavior without emitting extra masks.
Do not claim the unmasked full-register expression as a valid C replacement.
Scratch: `work/ceiltail-next/`; flags and target remain unchanged.

Replacing `clear_y_panning_byte` with empty-EAX-constrained C zeroing retains
the 255-byte span but moves `XOR EAX,EAX` before the preceding panning store.
First mismatch is `+0x72` in `ceilscan_begin_spans`. That two-byte helper stays
inline until a defined C scheduling constraint preserves the store/XOR order.

### `loadtables`: the final signed hardware divide

The remaining instruction is `IDIV EBX`. The published `PRAGMAS.H:1352-1358` implements the same
historical `divscale30` helper; Fate's numerator is a signed 64-bit value built
from high/low words, not a 32-bit C divide.

Existing compiler probes establish that Watcom 10.5 rejects both `__int64` and
`long long`; those were not repeated here. Next require a supported multiword
divide intrinsic/idiom before attempting to remove the final two bytes.
Do not use a 32-bit shifted numerator, which discards its high word.
Evidence: `work/loadtables-next/NOTES.md`.

### `initksqrt`: remaining upper-error address arithmetic

The 2,048-entry domain bounds the root at 46,330. The four absolute-value
sites still rely on the `TEST/JNS/NEG` form documented under `getangle`.

The remaining four-byte helper computes the upper error with
`LEA EAX,[EBX+ESI+1]`. With pinned Watcom 10.5
`/4r /s /or /bt=dos`, `error + delta + 1` retains the total 144-byte size but
first differs at `+0x5d`: `LEA EAX,[EBX+ESI]; INC EAX` replaces the displacement
form. Grouping `error + (delta + 1)`, including an address-expression spelling,
instead increments ESI before the LEA, first differing at `+0x5c`. That also
changes the register value consumed by the following correction loop.
Next investigate a supported C address-generation idiom that folds the constant
into the LEA without modifying ESI. Do not repeat simple reassociation or
substitute the newer 4,096-entry upstream algorithm.

A whole-function C Newton/correction probe retaining only the absolute-value
primitive and shared return produces 150 bytes versus 144 with the same flags.
Its first meaningful difference is at `+0x0c`: number initialization chooses
ECX instead of ESI and the root lives in EBX instead of ECX. The first differing
byte at `+0x08` is only the changed initial jump displacement.
Scratch source: `work/sqrtinit-next/ordinary.c`. A future whole-body attempt
needs a source-supported register-liveness change, not another direct paste
of this already-tested loop.

### View-angle interpolation: remaining multiply and shared frame

`rebuild_view_angle_table` still uses two `IMUL EBX; SHRD EAX,EDX,16` pairs and `ADD ESP,8` still
account for 15 inline bytes. The source reference is the pinned
`ENGINE.C:6456-6462`; `PRAGMAS.H:115-119` documents the historical signed
multiply/shift primitive.

Under pinned Watcom 10.5 `/4r /s /or /bt=dos`, an ordinary signed 64-bit product
using `__int64` fails with E1011/E1012; `long long` fails with E1060. A 32-bit
product/shift is not semantically equivalent: it discards the high product,
compiles to 120 versus 123 bytes, and first differs at `+0x09` as the constant
multiply becomes shifts/adds. Do not substitute it for the signed high-product
operation. Next require a verified multiword multiplication idiom supported by
10.5, while preserving the branch to the existing shared register restore.
Evidence: `work/viewangle-next/NOTES.md`.

### `setgamemode`: palette-loop allocation remains nonexact

The pinned historical `ENGINE.C` guides the candidate under ignored
`work/setgamemode-source/`. Best remains 851 bytes versus Fate's 834; only the
first 243 bytes and their 21 LE sites/targets match. The first divergence at
loaded `0x4b140` is `xor ebx,ebx` instead of `xor ecx,ecx` in the palette loop.
Full code and relocation checks fail, so the production assembly is unchanged.

Saved notes record pinned Watcom 10.5 flags, the earlier compiler-option matrix,
and switch/loop register-liveness experiments. The resumed investigation found
no productive new hypothesis; do not repeat those matrices. Next require a
source-motivated allocation change that preserves the exact prefix while
recovering ECX for the loop, then recheck the whole switch and all 75 LE sites.
Partial-prefix agreement is not accepted coverage. No game smoke test ran.

### `getangle`: keep the historical absolute-value primitive

The source-backed retry used the pinned `ENGINE.C:2757-2766` and
`PRAGMAS.H:1681-1686`, with Watcom 10.5 `/4r /s /or /bt=dos`. Fate's existing
320-entry table and wrapped products were preserved. The routine remains exact
at 236 bytes, including its two six-byte inline `TEST EAX,EAX; JNS; NEG EAX`
primitives; no nonmatching replacement was integrated.

A C conditional absolute value produced 242 bytes and `JGE`/alternate register
paths at `+0x71`, instead of moving through EAX and using `JNS`. The `labs`
intrinsic produced 240 bytes, first differing with an extra ESI save at `+0x02`,
and used `CDQ/XOR/SUB`. Unsigned sign-mask and register-constrained versions
produced 248–251 bytes with extra saves or `TEST immediate/JE`. Isolated probes
confirm plain signed comparisons select JGE, not JNS, under these flags.
Next require a small ordinary-C/intrinsic probe that demonstrably emits the
historical JNS sequence before repeating whole-function allocation experiments.
Reproduction and disassembly: `work/engine-inline-next/notes.md`.

- `report_stack_overflow`. Declaring the callee with `#pragma aux
  ... aborts` generated a 16-byte body with `push edx` and a tail JMP.
  Calling through an aborting intrinsic removed the save and generated the
  required CALL, but Watcom still emitted a trailing RET. The body remains
  16 bytes against 15, so the assembly stays in the build. Any future source
  retry needs to suppress that final RET while retaining the CALL encoding.

### Two-byte string copy retry

A register-constrained C loop for `strcpy_` reproduced the ECX and EAX
saves, CL byte loads, store ordering, and two-byte cursor advances. With
`/3r /s`, `/ox`, and `/os`, Watcom emitted 29 bytes with no fixups.
Both NUL tests used `84 C9` (TEST CL, CL) in place of the three-byte
`80 F9 00` (CMP CL, 0), shortening the body and changing the branch
displacements. Disabling optimization with `/od` produced 61 bytes.
The 31-byte assembly remains active. A further attempt needs a way to
preserve both immediate compares while keeping the pair loop in C.

### Save-slot name editor without two inline updates

An empty Watcom register-binding helper fed from C reproduced the intent
of the length clamp at 16, but the 374-byte object added moves from EAX to
ESI and back. Moving the backspace decrement into C yielded 373 bytes:
Watcom moved the length to ESI before the second NUL store, eliminating
the original indexed minus-one store and adding register moves. The
shipped 370-byte implementation retains both inline updates. Revisit
with the name length live in ESI across the range check and terminator.

### VESA draw-page window number

Replacing the inline EBX clear with a C zero, with or without an empty
EBX binding, gave 162 bytes against the 164-byte reference. Watcom reused
the zero inferred from the protected-mode window test. An empty EBX
clobber made it emit the clear again, but then the earlier pointer test
became a memory compare. A further attempt needs to keep the pointer
load and test in EBX while allowing the compiler to regenerate the clear
on the BIOS path.

### Map loader dword fills without inline instructions

Replacing all three clear sequences with Watcom's memset intrinsic produced
437 bytes against the 401-byte reference. Replacing only the sector clear
produced 412 bytes and kept all 15 relocation targets. Watcom selected a
byte count, an extra EDI save, and a REP STOSW/STOSB sequence. The target
uses a dword count and REP STOSD. An indexed C dword-clear loop reached
404 bytes but still emitted scalar stores and changed the frame layout.
The bitmap addresses and dword counts can now come from C. A further
attempt needs a compiler-recognized dword fill that preserves
the register state across the next read.

### Menu loop entry

The 17-byte entry still comes from assembly. Watcom schedules the argument
copies into EDI and EBP before storing the count. A volatile parameter
variant instead stores the count before loading the ESI row pointer.
Disabling scheduling moves the EDI copy ahead of the ESI load. The
original loads ESI, stores the count, then copies the other arguments.

### Menu entry mask shift

Replacing the inline shift with a C expression using a byte count added
an AND ECX, 255. Reading the full shift register and masking to the x86
five-bit count instead added an AND ECX, 31. The target shifts directly
by CL, so the inline shift remains.

### Menu selection input

A C switch reproduced the target's balanced key comparison tree. The
closest equal-offset candidate reached 283 matching bytes in a 583-byte
function against the 595-byte reference. Watcom assigned a different
register in the mouse reset and cursor handlers, then factored the row
and sound-feedback blocks differently. Preserve the EBP lifetime and
the original branch-local feedback before tuning the case encodings.

### Save-slot preview rendering

A register-constrained camera and overlay probe generated 577 bytes
against the 579-byte reference. It reproduced the original saved
registers, frame slots, and listener indexing. Watcom still rearranged
the camera coordinate and horizon interpolation, and allocated the
packed weapon arguments differently across the overlay call. A
579-byte variant matched only 138 byte positions and failed relocation
verification. Keep the camera and overlay register lifetimes separate
when probing the scheduling differences.

### Software float-to-integer truncation shifts

With `/4r /s /or`, direct C shifts from the CL byte value introduce a
six-byte `and ecx,0xff` ahead of the shift. The saturation path also
shares the right-shift tail when both paths use the same C expression.
Preserve live CH and verify each fixed entry when testing a replacement.

### Mirror aperture comparisons

A C comparison using direct sector-field addresses and `/4r /s /or`
loaded the ceiling into EBX before comparing it to EDX. The target
compares EDX directly to the indexed field. The extra instruction
added two bytes and consumed a register used by the following scan.
The sector address calculation now matches in C, so a retry can focus
on selecting a memory operand for the two comparisons.

### Recycled stream open flags

With `/4r /s /or`, the register-constrained allocator matched the
instruction sequence and all six relocation operands except at the
recycled stream flag update. Watcom emitted three-byte OR EDI, 3
instead of four-byte OR DI, 3 even with a DI binding and explicit
unsigned-short cast. The allocator now uses C for the other 164
bytes. A retry needs to preserve the operand-size prefix while
keeping the flags in EDI for the later dword store.

### DOS parser next-word cursor

With `/3r /s`, computing the cursor in C and binding it to EBP emitted
the expected LEA but added an EBP save and restore around the 233-byte
parser. Watcom also reported E1122 for the auxiliary's EBP modification.
The parser's retained assembly frame already saves EBP and uses it for
the next-word pointer. A retry needs a compiler-managed frame that
preserves the original stack-slot positions and EBP lifetime.

### Printf decimal character load

With `/3r /s`, widening the C byte load emitted MOVZX EDX,[EAX].
The original clears EDX and loads DL separately. A split C load with
a DL binding instead copied EBX into EDX and zeroed EDX with EBX,
adding two bytes at each digit loop. Both loops retain the original
four-byte zero-and-load sequence. The arithmetic and character
handling around those two sequences now match in C.

### Fixed-point formatter entry

With `/3r /s`, assigning the incoming cursor and spec pointer in C
while storing the original number in the local magnitude added a
two-byte MOV EDI, EDX. Watcom kept a second copy of the input across
the sign check. The entry retains its two register moves. A retry
needs to let the original EDX value serve both the first stack store
and the sign check without extending its live range into EDI.

### Printf callback literal-byte setup

With `/3r /s`, passing the literal directly as an unsigned callback
argument emitted MOVZX EBX, CL and MOV EDX, EBX around the state's
address calculation. The original clears EDX and moves CL into DL
after preparing that address. The callback itself now compiles from
C. A retry needs to preserve the separate zero and byte-load encodings
without allocating EBX as a temporary.

### DOS spawn path split

With `/3r /s`, the C split-path argument setup was two bytes
larger. Watcom loaded the buffered path into EAX and then added it
to EDX. The original adds the stack field directly to EDX. The
surrounding pointer calculations now match in C, so a retry can
focus on selecting the memory operand without changing the push
order of the two stack arguments.

### Printf value converter entry type load

With `/3r /s`, reading the type directly from the C format-state pointer
inserted MOV EAX, ESI before the byte load and grew the routine to
1,099 bytes. The target loads AL directly from the ESI-relative field.
Using a volatile byte load kept the extra move. The rest of the entry
setup now compiles from C, so a retry can focus on keeping the format
state in ESI across the AL load and precision reset.

### Menu glyph stack arguments

With `/4r /s /or`, staging all sprite arguments in C changed the
frame and moved the loop index from ESI to a stack slot. Watcom
also kept the font index on the stack. The candidate emitted 341
bytes against 301. The clip rectangle edges now compile from C.
Keep EBP and ESI live across the remaining argument setup before
trying to move the sprite call out of its auxiliary body.

### Wall projection stack reads

With `/4r /s /or`, using a typed pointer bound to ESP for the
final-column frame grew the 919-byte routine to 925 bytes. At
`0x477c0`, Watcom copied ESP into a general-purpose register
before loading the field. The frame loads still use direct ESP
operands. Projection and endpoint calculations around them now
compile from C.

### Proximity sight-call EBP loads

With Watcom 10.5 and `/4r /s /or /os`, replacing both remaining sight
loads with C produced a 359-byte routine when the compiler omitted the
EBP save and restore. A 361-byte variant kept all 27 LE relocation sites
but differed at two byte positions because Watcom used ECX for sprite X.
ECX already holds the sprite sector at that point. The saved frame and the
two sight coordinate loads into EBP still account for 25 inline bytes.

### Actor movement range and route setup

With Watcom 10.5 and `/4r /s /or`, rewriting both coordinate
differences together grew the 326-byte routine by two bytes. The
horizontal difference loaded sprite X into EBX before subtracting,
whereas the original subtracts directly from memory. Volatile loads
kept the extra register move. A C rewrite of the route call also moved
the attack-target stack read ahead of the actor-kind store. Keeping that
read and store together preserves the original ordering while the route
call now compiles from C. The turning-state assignment emitted a constant
load into DL and a register-to-memory store, adding one byte compared
with the original immediate-to-memory store.

### Display-page destination alignment

With Watcom 10.5 and `/4r /s /or`, eight C variants of the low-bit
destination checks copied EDI to EBX and tested BL instead of testing
EDI directly. The routine shrank from 413 to 411 bytes and changed the
short jump displacement at `0x5d178`. Keep the full-width EDI tests
beside the string stores. The page loop and tail tests compile from C.

### Sprite-sequence coordinate stores

With Watcom 10.5 and `/3r /s /or`, the C frame and initial coordinate
stores produced 481 bytes instead of 477. Watcom copied EAX to EBP and
EDX to ECX before the first two stores. Retaining the two original
stores lets Watcom generate the frame and the remaining stack accesses
except for a sector read beneath pending movement arguments. A later C
variant reduced the difference to one redundant `mov ebp,edx` at entry
(479 bytes).

### Teleport destination sound arguments

Watcom 10.5 kept the 501-byte size when the positional-sound argument
expressions and call were moved into C. One variant moved each ECX
coordinate load after EDX, EBX, and EAX setup, changing 34 byte positions
and shifting sound-name LE operands. Explicit register-bound statements
preserved all 20 LE sites but still reordered setup, with 25 differing
byte positions. Keeping the stack arguments and ECX coordinate reloads
inline lets Watcom emit the rates, gains, names, masks, and calls from C.

### Route destination Y-bound operands

Watcom 10.5 with `/4r /s /or` compiled the 126-byte zone-bounds block
to 128 bytes when both destination Y comparisons were written in C.
It loaded the stack slot into ECX before comparing instead of using
a memory operand. Replacing only the first comparison moved the same
extra load to the second one. Both Y comparisons remain inline while
the X comparisons, zone records, and actor checks compile from C.

### Route crossing indexed loads

A direct C rewrite of the 201-byte zone-crossing block produced Watcom
10.5 internal compiler error E1119 under `/4r /s /or`. In a reduced
variant, rewriting the first 147 bytes emitted 162 bytes. Watcom copied
the live index into another register and expanded the parallel waypoint
and sector loads into separate address arithmetic. The verified version
keeps the indexed byte, X-coordinate, and sector loads inline while
calculating the crossing and updating the sprite in C.

### Palette table stack arithmetic

Watcom 10.5 `/4r /s /or` emitted 657 bytes for a 649-byte table builder
when four stack-slot additions were written in C. It loaded each
operand into a temporary register before adding. The original adds
directly from memory. Keeping those four memory operands inline avoids
eight extra bytes.

### DOS environment selector load

Under Watcom 10.5 `/4r /s /or`, the inline word-operand spelling of the
DOS selector load adds a `66h` prefix to the original six-byte
instruction. The dword-operand form fails with E1156. Hand-encoding the
opcode alongside a separate address directive put the OMF fixup two
bytes too early. The exact build retains the assembly segment setup.

### Slope tile lock immediate store

Watcom 10.5 `/4r /s /or` emitted a 52-byte tile touch when the lock set was
a direct C byte assignment, compared with the original 51 bytes. Direct,
volatile, and signed byte stores used a load into DH followed by a store.
The exact version retains the seven-byte memory-immediate store while C
generates the lock test and usage bitmap update.

### Board entry Y coordinate load

Watcom 10.5 `/4r /s /or` introduced an extra register move when the Y array
load was expressed directly in C. The reference indexes the Y array with
EAX and loads straight into EDI. The exact rewrite retains that load inline.

### DOS descriptor writer stack frame

Watcom 10.5 rejected a register-only auxiliary with an EBP input, and an
entry pragma listing EBP as modified, with E1122. The reference saves
EBP and uses it to hold the byte count across both DOS calls. The exact
version preserves that frame setup and EBP assignment inline.

### CD lead-out frame addition

With `/4r /s /or`, a register-bound C variant built to the original
435 bytes and preserved all 19 LE references. Watcom emitted `add eax, ecx`
before clearing EBX, reversing the order of those two instructions. The
exact rewrite calculates the 150-frame subtraction in C and retains the
preceding frame addition inline.

### Slope wall reciprocal shift

A direct C variable shift produced the original instruction, but the
degenerate-wall fixture reaches exponents outside the valid C shift range.
Masking the count in C added three bytes under Watcom 10.5 `/4r /s /or`.
The exact source keeps the x86 shift and its hardware-masked count inline.

### PCM input sign extension and register-copy encoding

Watcom 10.5 `/4r /s /bt=dos` emits `CWDE` (`98`) for a direct signed
short-to-long conversion into EAX, instead of `MOVSX EAX,AX` (`0f bf c0`).
The first meaningful mismatch is at `mix_mono_to_mono_signed_8_+0xa`;
the group shrinks from 6,976 to 6,848 bytes. The equivalent EBX conversion
does match and is restored to C. Do not repeat the direct EAX cast.

A full-register C replacement of the duplicate-left helper keeps the
6,976-byte group size but emits `89 c3` instead of `8b d8` in 16 spans.
Both encode `MOV EBX,EAX`; exact operand-direction encoding remains the
obstacle. First mismatch: `mix_scaled_mono_to_stereo_signed_8_+0xa`.
Further work needs an evidenced instruction-selection hypothesis rather
than equivalent register-identity spellings.

### PCM output byte packing

Under `/4r /s /or /bt=dos`, unsigned C masks/shifts for `MOV BL,AH` and
`MOV AL,BH` generate shifts, masks, and ORs instead of byte-register moves.
The first affected functions grow from 20 to 34 bytes at `+0x8`.
Left-only, right-only, and combined group sizes are 1,442, 1,440, and
1,498 bytes versus the required 1,384. High-byte register selection needs
a new compiler-supported idiom; repeating equivalent packing expressions
does not address the failure.

An initialized unsigned-long byte-subobject copy does recover byte-register
MOVs, but chooses `88 e3`/`88 f8` instead of required `8a dc`/`8a c7`.
All four unsigned stereo-eight spans differ only in opcode direction (31/89
bytes unchanged); signed forms also change scheduling or allocate EDX with
saves/restores. Full group: 1,392 versus 1,384 bytes, 24/32 spans exact.
No variant is integrated. Next require instruction-selector evidence, not
more equivalent byte-copy expressions. Evidence:
`work/dsh-r1-pcm-output/RESULT.md`.

### PCM input remaining sample loads

Under `/4r /s /bt=dos`, two-byte intrinsic `memcpy` loads introduce stack
locals and copy setup: 10,895 versus 6,976 group bytes, 64/128 spans exact.
Union high-byte updates now replace selected regular shapes exactly, but
applying them to all eight-bit readers grows the group to 7,120 bytes.
First remaining mismatch is `mix_mono_to_mono_unsigned_8_`: a saved EDX and
`MOV EDX,EAX; MOV DH,[ESI]; MOV EAX,EDX` replace the direct AH load.
Keep the accepted selected-shape conversion; further work must recover the
remaining AX/BX lifetimes without extra scratch registers. Do not repeat
the unrestricted union transformation. Evidence: `work/dsh-r1-pcm/RESULTS.md`.

### Actor tile lookup and raw save modes

The loader reads actor modes and active flags without validating their domain.
Although normal initialization/writers keep live actors and modes in range,
actor 500 with mode 9 reaches beyond the 4,509-short tile object. A C pointer
load is therefore not accepted merely because ordinary-save fixtures match.
The original eight-byte indexed machine load remains; row/mode/template
arithmetic is still compiler-generated. Further removal needs a truthful
backing-storage/domain model, not a declared array bound or silent clamping.

### Route dispatcher shared-frame continuation interface

The earlier exact C conditional calls used `void(void)` declarations for
resolver definitions taking a `long frame_slot` anchor. `aborts` generates
tail transfers but does not establish compatible C function types. The two
original combined compare/conditional-transfer helpers are restored, with
matching `void(long)` target declarations used only as assembler symbols.
This returns 21 bytes to inline attribution, not a machine-code regression.

With `/4r /s /or /bt=dos`, void-entry GetSP and pointer-valued GetSP designs
materialize ESP in a general register before frame accesses. Explicit ESP
pointer parameters fail with E1122. Keeping C conditions around inline
unconditional JMP helpers grows the dispatcher from 92 to 94 bytes: at
`+0x19`, six-byte `JE near` becomes `JNE +5; JMP near` (seven bytes);
the second exit expands similarly. An alias name alone does not establish
a valid omitted-argument contract. Do not repeat these variants without a
new documented, type-compatible frame interface.

### Heap rounding byte-mask allocation

Watcom 10.5 `/4r /s /or /os /bt=dos` moves the byte-view rounding mask from
DL to CL and adds ECX save/restore when the unsigned-long representation is
accessed through C byte pointers. The exact heap source is retained. A new
probe must address allocation and byte-operand selection, not merely use
another spelling of the object-representation view.

### Ceiling scan-column near-branch encoding

Extracting ceiling scan-column's
first empty-column test instead generates short `7d 5a` rather than the original
near `0f 8d 5a 00 00 00`, shrinking its span from 142 to 138 bytes and the tail
from 752 to 748. That condition remains inline. Future extraction must preserve
the original near selection rather than repeat the same C conditional.
Evidence: `work/dsh-r2-ceiling/v3-report.json`.

### Mouse-menu deferred argument cleanup

An empty-clobber EBP push helper
hoists `XOR EBX,EBX` before the push; retain the original conservative helper
clobbers to preserve scheduling. A full-expression formatting-result experiment
still performs argument cleanup immediately after CALL, ahead of the original
row-pointer load. Complete size stays 550 bytes, but first mismatch is +75 and
six LE sites move. Keep the two deferred caller cleanups inline; expression
sequencing alone is not evidence of original stack-cleanup scheduling.
Evidence: `work/dsh-r2-mouse/v3.json` and `HANDOFF.md`.

### PCM input split getter-clobber lifetime boundary

Applying conservative incoming AX/BX getter clobbers to every byte reader still emits 7,120 bytes
and only 103/128 exact spans. Result-only conservative clobbers leave 102/128
exact. The first broad mismatch remains the unwanted EDX save/DH load in unsigned
mono-eight. Applying separate left/right getter contracts to eleven remaining
signed scaled/resampled stereo shapes gives 7,024 or 7,030 bytes with 118/128
exact spans. Both first differ at resampled signed stereo-to-mono: 53 versus
47 bytes, with an unwanted EDX save and DH scratch load for the left sample.
Neither split recovers the full pair of C loads in resampled signed scaled
stereo-to-mono (63/67 versus 59 bytes).
Next try partial-channel selections in other remaining shapes, rather than
repeat global, result-only, or both-channel split contract matrices.
Evidence: `work/dsh-r2-pcm-input/RESULTS.md` and
`work/dsh-r4-pcm-input/RESULTS.md`.

### Software unsigned integer to float rotate

With `/4r /s /or`, the Watcom `_rotl` and `_lrotl` intrinsic probes
emitted 49 bytes against the 43-byte reference. Both inserted
`and ecx, 0xff` to widen the rotate count from CL. The reference uses
the count already in CL. The exact version keeps that rotate inline.

### Software signed integer to float tail transfer

With `/4r /s /or`, the all-C signed wrapper emitted 21 bytes versus 17.
Watcom used `test eax,eax` and a near conditional branch to the unsigned
entry. The original uses `or eax,eax` and a two-byte short branch. The
exact variant keeps the four-byte entry test and branch inline.
With only the wrapper in its analysis span, Ghidra treated the call to the
preceding unsigned entry as a branch and omitted the sign-bit OR. The
reference listing confirms both the short tail transfer and the returning
call. Use both routines when interpreting this control flow.
