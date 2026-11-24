# Watcom 10.5 idiom regression evidence

Source: `tools/tests/fixtures/watcom_idioms.c`.
Expected code/layout/fixups: `tools/data/watcom-idioms.json`.

These are compiler-regression examples, not reconstructed Fate routines. Their
bytes never count toward coverage or enter the production link.

```powershell
python tools/check_watcom_idioms.py
python tools/check_watcom_idioms.py --clean
```

The pinned compiler builds one small translation unit with each of:

| Variant | Flags |
| --- | --- |
| `id4` | `/4r /s /or /bt=dos` |
| `id3` | `/3r /s /bt=dos` |
| `idsize` | `/4r /s /os /bt=dos` |

The checked-in fixtures currently establish:

- `register_increment`: an EAX-bound C increment emits `INC EAX; RET`.
- `signed_word`: casting a full EAX parameter to signed short emits `CWDE`.
  This does not claim that a `[ax]` or `[di]` function-definition parameter
  establishes the same ABI.
- `unsigned_word` and `low_byte`: the speed variant uses immediate masks;
  the other tested variants use zero-extension instructions.
- `packed_value`: a packed field at offset one is loaded directly from `[eax+1]`.
- `less_than_memory`: the comparison uses `[edx]` directly. Under `/4r /s /or`,
  its `SETL AL` falls through into the following `low_byte` public's mask and
  return. Public layout and shared tails therefore matter, not only isolated
  byte counts.
- `keep_edx`: an external call declared `modify exact [eax]` lets the caller
  retain its second input in EDX across the call. The puzzle activation phase
  uses this contract to carry the clear tag through `activate_sector_`; its
  two compiler contexts are accepted only as three individually pinned
  410/64/458-byte slices, with five original branch displacements rebound.
  Compare each selected slice and its LE targets, not either whole public.
- `aborting_wrapper`: the tested `aborts` declaration generates a tail JMP,
  not an unconditional guarantee of a particular fatal CALL/no-RET sequence.
- `rotate_idiom`: this shift/OR expression remains separate shifts and an OR,
  rather than becoming ROL, under all three tested flag combinations.

Unit tests execute the stored code with representative signed/unsigned inputs,
packed data, and external-call stubs. The pinned compiler suite then checks that
the actual newly compiled code, public offsets, external table, and fixups match
those expectations. Volatile OMF comments, including timestamps, are not compared.

## Patterns verified in Fate

- Explicit byte inputs (`parm [al]`, `[ch]`, `[cl]`, `[dl]`) prevent argument
  setup from overwriting a register that an auxiliary still consumes. This
  lets the primary audio command-3 constant come from C while preserving the
  original byte-copy encoding. Empty ECX/ESI stages fed by unsigned register
  values plus one generate the startup parser's exact one-byte INCs.

- Nonzero literals passed to empty full-width register stages can generate
  the original five-byte MOV: audio commands 1/5 and the startup argument index
  remove 20 inline bytes this way. Argument preparation may move across an
  auxiliary with undeclared register inputs; exact code verification must
  precede acceptance, and remaining consumers need explicit input contracts.

- The template sprite creator at `0x11073` returns a short in AX and changes
  EAX/EBX/EDX. Its 302-byte body saves ECX/ESI/EDI/EBP, not EBX or EDX.
  Caller declarations and emulator stubs must allow those parameter registers
  to change; the output type alone does not establish register preservation.
  The floating-sprite caller also permits EAX/EBX/EDX for `updatesector` and
  EAX/EDX for `sprintf`; all three corrected declarations retain its exact
  270-byte code and LE relocations.

- [`checksum_gameplay_state`](../src/fate/checksum_gameplay_state.c) keeps the
  CRC accumulator at 16 bits, reuses the player index as the status-loop index,
  and feeds the player-angle and sprite-Y high bytes with the input operand
  first in the lookup-index XOR. The equivalent XOR operand order changes
  Watcom temporary allocation and memory-XOR selection. Under `/4r /s /or`,
  this produces all 1,490 bytes and 71 LE targets without inline assembly.

- [`process_gameplay_frame`](../src/fate/process_gameplay_frame.c) reuses short
  loop indices and keeps the recording count's ESI identity stage local to one
  iteration. This lets ESI hold the column after the count dies; constraining
  player and column separately lengthens lifetimes and changes allocation.
  `/4r /s /or /bt=dos` matches all 732 bytes and 64 LE targets; only the
  two-byte position-copy primitive remains inline.

- A full-width zero passed to an empty register stage can generate the original
  XOR from C, as in [`format_engine`](../src/runtime/format_engine.c). Parameter
  setup may move or disappear in other contexts; verify each complete object
  and its relocations before accepting the replacement.

- In [`dispatch_actor_update`](../src/fate/actor_dispatch.c), distinct entry-index and profile-index lifetimes prevent shared scaled-address spills. The explicit actor stage in the flags comma expression controls Watcom-only argument order; verify exact code, LE sites, and fixtures.

- `update_menu_selection` matches ordinary C under `/4r /s /or /bt=dos`; check the routine’s historical scheduling flags before introducing register helpers. The actor dispatcher’s no-`/or` build is a distinct compiler context.

- In [`getangle`](../src/engine/getangle.c), the call clobbers EAX and EDX.
- [`play_sound`](../src/fate/play_sound.asm) clobbers at least EBX and EDX; a conservative caller contract is EAX/EBX/ECX/EDX.

- `copytilepiece` keeps a `char` local and compares
  `(unsigned long)(unsigned char)dat != 255` to recover MOVZX and the
  full-width comparison.
- `run_mouse_button_menu` and `run_key_binding_menu` use a returning
  `modify exact [eax]` contract so Watcom emits the register frame and return.
  Explicit EBP accesses and deferred caller cleanup still need separate review.
- `update_sprite_sequence_state` declares the six-argument movement ABI so
  Watcom can track pending stack arguments and reload the saved sector.
- The ceiling and floor loops use a jump to a do-while test to preserve the
  original bottom-tested layout. Keep shared-frame continuation declarations
  compatible with their definitions.
- PCM input uses initialized union storage and empty register bindings for
  partial-register loads under the Watcom/x86 representation. See the open PCM
  probe notes before changing getter clobbers or channel lifetimes.
- In [wallmost](../src/engine/wallmost.c), a volatile union keeps the original
  integer store, x87 conversion, and exponent byte read at one scratch address.
  Without `volatile`, `/4r /s /or /bt=dos` used an ESP temporary, changing both
  the shared frame and the LE sites.

### Literal-template and marker guards

For an unlinked initialized-array prefix in CODE, pin its payload digest,
public offset and exact internal pointer fields. Reject fixups in the literal
prefix or pinned epilogue and overlaps with the complete pointer instructions.
Validate ordinary and marker objects with the same guards; credit only the
selected instructions, never discarded compiler code or literal tables.

### Placed CODE literals and frame checks

For selected slices that point into a digest-checked literal prefix, bind through its explicit registered CODE-object offset and export typed `code_bindings`; load through the CODE segment base (`+0x10000` here). Never infer prefix placement from the selected slice address or add the DS base. For frame tests, prefill saved-register slots with distinct poison, prove entry pushes overwrite them, then pass the captured initialized frame into the return phase and clobber registers before checking restoration and guards.

### Separated NASM ranges

Use `section name align=1 vstart=... follows=...` for each physically separated range. Register each physical range in `ASM_SLICES` and verify the whole linked image; a correct local range does not prove intervening bytes or final placement.

## Adding or changing a probe

1. Add the smallest freestanding expression and its explicit Watcom ABI to the
   fixture source. Do not change game sources to run a compiler experiment.
2. Observe the result in ignored scratch:

   ```powershell
   python tools/check_watcom_idioms.py --observe --build work/idiom-research
   ```

3. Review the generated instructions, layout, and fixups. Add semantic cases to
   `tools/tests/test_watcom_idioms.py`, then deliberately update the expected JSON
   and source hash. `--observe` never updates that file automatically.
4. Run the ordinary probe check and unit tests. Keep a failed approach's concise
   lesson here or in `docs/C-RESTORATION-ATTEMPTS.md`, rather than retrying it
   without a new hypothesis.

An idiom matching this fixture does not establish that it matches a Fate routine.
Game code still needs its own exact byte, LE-relocation, and whole-image checks.

- **EBP output contracts:** a result-only auxiliary declared `modify exact []`
  does not track EBP writes. In the isolated probe, input 5 produced outputs 5
  and 7 (expected sum 12, actual 14), and the caller's EBP sentinel became 7;
  Watcom did not save it automatically. Explicitly declaring `modify EBP`
  fails with compiler error E1122. An empty getter is not equivalent to a
  helper that writes EBP. This probe establishes only this EBP behavior; do not
  infer preservation or clobber rules for other registers.

## Historical networking companions

An unlinked historical companion can be useful when its provenance and exact
link boundary are explicit. `ipxctx.c` is such a companion: it is not linked
into the production image and contributes no IPX coverage. Its C body provokes
Watcom's six-byte five-`POP`-plus-`RET` epilogue; the binder verifies the local
epilogue, opcodes, and original targets, then rebinds only two branch displacements
(`EB`/`E9`) to the existing `ASM` routine at `0x41a3f`. It does not patch
opcodes. The ES-preservation wrapper is excluded from production; keep
selection strict and coverage reporting honest.

The marker comparison recognizes up to three total padding bytes after `RET`,
including `NOP` (`90`) and `MOV EAX,EAX` (`8b c0`). This does not relax
production acceptance; the verifier checks the padding explicitly.

## Packet receiver ABI and selected branches

The snapshot callee is 129 bytes and truly preserves its incoming ESI. Its
`parm [esi] value [esi]` contract returns that same value with zero ABI
instructions; this is verified passthrough behavior, not an invented clobber
exception. For selected C/assembly branch replacements, the binder validates
the branch opcode and width, compiled target, placement, and overlap before
changing the displacement. Exact routine bytes and LE targets remain required.

The receiver's 105-byte CRC and 7-byte parity contexts compile as standalone C
in `receive_checksums.c` and `receive_parity.c`. Preserve the RET-suffix guard
when selecting those C spans; the C contexts contain no inline assembly
instructions.

A length-scaling phase can return its result in EAX, then a separate clock phase can consume EAX. Selecting these adjacent compiler contexts preserves load order directly, without volatile tricks or added CALLs. Private RETs stay unlinked and guarded.

## Main-menu shared-frame idiom

Keep the retained 32-byte table and alignment in place; a checked compiler table is excluded and earns zero restoration credit. The selected C prefix emits a real outgoing PUSH; the following draw_menu_text call consumes that argument through its RET 4. Guard the private call/read suffix and verify exact fixup names and addends even though those successor instructions stay unlinked. Keep the shared-frame continuation as a tail transfer. The generic loaded-binding limitation applies to the switched main-menu binder; use `check_main_menu` to validate the integrated object and behavior.

The menu entry is covered by four instruction-aligned C phases spanning source
bytes 0–41 exactly once. An independent swap of the register-zero and tick-load
operations is proven to preserve clock-read order, flags, all six saves, and the
shared frame. The shared guard is emitted once and linked at two disjoint original
addresses; account for 13 linked image bytes and zero new unique compiler bytes.
For an unfolded semantic source block, pin its ingress and egress boundaries and
account linked image bytes by address, separately from unique compiler bytes.
Keep the full selected compiler context and fixups pinned, and verify the accepted image hash; isolated phase bytes
are not sufficient evidence.

## Reusable receiver ABI lesson

Declare function formals at their full ECX/EDX width, then narrow them inside the body; narrow formals can change Watcom's register/stack ABI. A sender stored in a 12-byte struct has its field at offset 8; with the 4-byte return address, it is at ESP+12. Keep suffix guards when selecting spans that share a return tail. The RET-suffix guard and the separate send-tail JMP guard protect different excluded contexts. For packet receiver branch selection, preserve both applicable guards and validate branch opcode/width, compiled target, placement, and overlap; exact routine bytes and LE targets remain required.


## Preserve a live register while matching a loop

`src/engine/palette_lookup.c` uses empty EBX getter/consumer declarations to
keep the incoming EBX value live through a standalone C loop. Watcom 10.5
`/4r /s /or /bt=dos` then assigns the per-iteration zero to ECX and emits
`inc eax` before `xor ecx,ecx`, matching the original 19-byte loop. Constraining
the zero through an ECX identity alone schedules the XOR before the increment.
The checked public has one extra private RET, excluded by the leaf slice.


### Byte-register identities and natural EBP constant allocation

Empty identities can bind CH/CL as byte values while preserving the other bits
of ECX. In the stereo mode-6 state context, holding the unchanged EBX/ESI/EDI
values live makes Watcom allocate page-flip constant 1 to EBP without an EBP
input auxiliary (which fails E1122). The enclosing routine already owns the
saved EBP slot; the private context's PUSH/POP EBP and RET stay unlinked and
are covered by the complete raw-context digest. Mode 7 excludes only RET.

Use ordinary global accesses when independently scheduled instructions must
be linked in their original order. Every reordered pair must have disjoint
register/flag/memory dependencies. The stereo fixture compares original,
placed and natural compiler order, including poisoned byte-register upper
bits and shared return restoration. Do not reorder volatile accesses to make
this proof: volatile access order is part of that C program's semantics.


### Switch index byte writes and generated table relocation

For the video-mode dispatch, zero an unsigned dword union through an empty
EDX identity, write its low byte from AL, and keep height in EBX and the
unsigned wrapping product in EAX. Watcom emits the original XOR EDX,
MOV DL,AL and CS:EDX table jump. The private switch's CMP EDX/JA is redundant
under the earlier linked AL guard; excluding it preserves the original IMUL
flags. This relies on the pinned 32-bit little-endian Watcom representation.

A generated table can be placed separately from selected code in the same
object. Guard the entire raw group and fixup inventory, then translate each
same-CODE target through its checked case-entry map. Verify every placed
CODE relocation and replay with the translated table installed. Count table
bytes as data. The image builder routes only the registered contiguous group
interval through its group binder and binds separately placed leaves normally.

### Ripple phases and complete control contexts

The ripple stencil keeps each byte addition in AL or DL with empty
unsigned-char identities after each update. Constraining only the first
loads lets Watcom introduce AH/DH temporaries and an ECX save; constraining
each result emits the original eight-instruction, 38-byte sum with no
auxiliary instructions. One checked compiler body is placed at all four
original sites: 152 linked image bytes, 38 distinct compiler body bytes,
and no linked RET. The independent oracle checks seven neighbors (the
lower-right sample is omitted), toroidal borders, and the original write
to the final bottom-row padding byte.

The ripple row helper returns the destination for the next row in EAX.
A void helper lets Watcom discard the final MOV EAX,EBX, even though the
retained outer loop consumes that handoff. The pointer return keeps all
32 original body bytes, including internal short branches, without an
inline instruction. Destination arithmetic uses a byte pointer into the
entire assembly-owned raw bordered plane; packed word accesses cover the
unaligned stores, and the source advances through exactly 32 packed words.

For the top/bottom border loop, an empty full-pointer EDX identity fixes
the memory-base allocation. Watcom privately saves ESI, homes the incoming
EDX pointer there, then repeats it into EDX. The production caller already
has that exact pointer in EDX throughout the masked-row phase. Two slices
therefore retain the ECX initialization and loop, excluding the guarded
private save/copy/restore and flag-neutral identity copy. The isolated
fixture starts ESI with unrelated poison and checks that the linked code
preserves both EDX and ESI, all source bytes, and every untouched plane byte.

The radius-removal leaf publishes the decremented count before copying
the replacement X coordinate, then reads Y and stores radius/Y. Qualifying
the count store, X store and Y read as volatile lvalue accesses retains
that order without changing the external declarations. The independent
oracle records write order and rejects swapped count/X stores even when
all final state agrees. Self-removal copies the radius after its increment,
so the inactive last slot retains 11 as in the reference.

The X-slot store and four corner stores can retain their compiler order
while independent register bookkeeping runs between slices.
MOV EBP,ECX / SUB EBP,ESI only affect the X countdown; MOV ESI,EDX /
XOR EBP,EBP prepare output after the corner reads. Separate natural and
interleaved oracles check the distinct register handoffs. Their final
EFLAGS need not agree; the whole-image byte comparison verifies the
production flag behavior.

Caller-cleanup stack formals can model in-place frame fields without
introducing a competing local frame: the ripple radial leaves use an
unused +4 formal and amplitude/X at +8/+12. Volatile setup formals retain
the original stores. The original EBP assignments remain outside these
leaves and supply the slot and Y getter contracts. Compatible 4096-word
radial table declarations permit aligned scalar C loads while retaining
the initializer's existing exact stores.

The vertical row can split around its original INC EBP: one C leaf reads
the old row and last-column pixel, then another reads the advanced row,
stores the one-byte scratch formal at ESP+16, and writes both borders.
This avoids forcing a C function to modify EBP through an unsupported
auxiliary declaration. Output setup similarly uses a caller-stack pointer
formal at +4; an empty two-input handoff keeps both updated word/cursor
pointers in their original registers.

A public function may return a value in EBP even though EBP input and
modify declarations are rejected. With a true EBP getter and a 0..127
row contract, returning `row + 1` emits `INC EBP; RET`; the increment now
replaces all three ripple row steps. This is an explicit output contract,
not an automatically preserved EBP value. The same public output contract
also supports an EAX slot identity, ECX-minus-ESI countdown and indexed Y load through a true EBP getter.
The countdown's copy and subtraction can link around an independent
coordinate phase that preserves ECX, ESI and the pending EBP value.
An `aborts` continuation can produce the original near conditional jump directly from a signed guard.
Keep a guard's private RET separately guarded: combining functions may
cause Watcom to share a preceding RET and invert the conditional branch.
The ripple word guard starts its own translation unit to retain the exact
layout. A conservative clobber on an empty identity may also constrain
scheduling without adding instructions; the ripple EAX destination
handoff invalidates ESI before binding its tile pointer.


For an in-place field at ESP+0, an initialized volatile local struct can
provide the correct compiler context when a stack formal begins at +4.
The ripple index contexts allocate the real 20-byte layout, initialize
the index, then read or decrement it. Selected instructions reuse the
caller's already allocated frame; one context also supplies the outer
allocation, release and return. Guard the complete context and its zero
fixups, including any private initializer or shared-return jump. A raw
ESP getter instead introduced an EAX home and saved-register wrappers.
Do not execute a private RET with the index still at the top of stack.

A C wrapper returning the RNG's EAX value in EBX emits CALL, a result
copy and RET rather than a tail JMP. The ripple build links the CALL
twice; existing coordinate phases perform the result copy. Guard the
unlinked copy/RET and the relative-call symbol, and test the actual call
stack before relying on the selected instruction alone.


The remaining ripple control layout comes from a complete readable C
algorithm context. Its 865-byte compiler function supplies 43 matching
save/restore/transfer bytes to the 855-byte production routine; exact C
phase contexts supply the other 812. Register allocation may differ in
unlinked producers, so verify the logical predicate and actual placed
flag producer for each selected conditional branch. Preserve the compiler
opcode and width, check its original internal target, then remap only its
displacement to the corresponding production label. Check all edges and
save/restore order independently, and execute both the private whole C
model and the final routine against the toroidal oracle.

Guard large private contexts with the raw CODE SHA-256 as well as a
complete fixup inventory. Two-field context fixup metadata requires a
zero raw addend; an optional third field pins a nonzero DATA addend.
This protects unlinked symbolic references even when selected spans have
no LE sites. The ripple fixture rejects a changed private opcode/return,
external name, addend, compiler target and production destination.


### Serialized field transfers and guarded stream contexts

For literal `fread`/`fwrite` records, conservative clobbers on empty
identities preserve the original EBX-count, EDX-size, EAX-buffer and
ECX-stream preparation order. The actual stream callees preserve
ESI/EDI/EBP and may clobber all four argument registers. Model raw saved
state as the bounded character representation of the original LE DATA
object, rather than inventing incompatible typed global declarations.
Pin its real extent/base and every record's address, size and LE target.

A void final transfer becomes a tail JMP. Returning its actual item
count in EBX preserves CALL in a two-function probe, but multiple
same-callee contexts may still share the entire final call/return tail.
Returning the last complete item's bounded end cursor gives each run
a meaningful distinct suffix and keeps every required CALL. The cursor
is private: select only the field calls and guard all prefix/suffix
bytes and fixups. A non-power-of-two final size can introduce PUSH ESI
for private cursor arithmetic; exclude it when the placed body uses
only register arguments and the caller's existing stack. For private
behavior tests, keep the compiler object's full layout so shared tails
still reach their original targets. Check both empty/short I/O and
complete-item cursor semantics, not just successful transfers.


For one-byte save fields, the original size uses `MOV EDX,EBX` after
the stream copy instead of a second literal load. Carry the real count
through an empty EDX identity and conservatively clobber EDX on the
stream identity. This preserves the shared value without new inline
instructions. Contexts in one object may share private cursor tails
across read/write directions: bind every public in that object before
emulating a full private context, and guard each tail and addend.


For a retained pointer-table loop, a single-step C context can read its
physical incoming index through an empty ABI getter and return the new
index in that same register. Conservative index clobbers on a value
identity force a fresh getter after the compiler's base shift; the actual
empty identity preserves the index. Bound entry indices to 0..511 and
decrement as signed int, then store at index+1. Convert the flat pointer
to unsigned and use unsigned shifts/add/sub for the address words.

An exact indexed load from an addition context may also supply the same
load in the subtraction loop: prove matching input/output registers,
memory operand, flags and LE target before composing it with the actual
subtraction suffix. Credit only the placed instruction, retain full
context hashes/fixup guards, and exercise all indices plus complete loops.
If emulation reuses an address for different private contexts, invalidate
Unicorn's translated-code cache after writing new instructions.


To extend a register-getter step into a complete pointer loop, keep its
initialization in the C context and read the physical index again in
the condition. This preserves the preheader, original TEST register and
short back edge without a loop-carried C shadow variable. The reader's
table transfer supplies the same EDI initialization as the writer's
explicit setter. Bind a shortened subtraction context with the existing
section-branch metadata: check raw opcode/target first, then calculate
the original placed displacement. Private emulation must temporarily
suppress that placement mapping and restore it in finally. Require full
C coverage of loop test ranges and exercise both complete placed paths
and private contexts, including partial table reads.


For a saved status length, truncate to unsigned char before scaling in
unsigned arithmetic. Empty identities can keep the scaled value in EAX
while the clock and sum stay in EDX, preserving the original mask/shift,
clock load, two additions and final store. Return the actual zero result
to preserve the final XOR. Test poisoned upper length bits and clocks
around wrap and exact zero; XOR leaves AF undefined, so exclude AF from
the defined-flag oracle. Keep DF and IF preservation separate.


Fixed character-only structures of 13 and 12 bytes produce three MOVSDs
plus an optional MOVSB under the pinned flags. Structure assignment copies
bytes after NUL too; measure the resulting string separately. A meaningful
EBX length result prevents a final tail transfer, but another context may
share that CALL/return tail. Keep the complete object layout for private
emulation and select only the actual placed instructions. Calls between
pointer setup and copy require proven ESI/EDI preservation. Native strlen
loads ES, so initialize a flat GDT and DS/ES/SS in the fixture.

For marker comparisons of a shared suffix, an external E8 CALL can be
compared by identical complete suffix instructions and normalized fixups.
Require a relative dword external FLAT relocation and matching addend,
reject indirect transfers and unverified PC-relative branches, and require a terminal near RET to exclude an
unchecked fall-through into another public. Keep unsupported transfers
unknown; a matching printed target alone is insufficient.


A 20-byte filename structure with a nine-byte basename, three-byte gap
and eight-byte suffix selects the original two MOVSDs and MOVSB. Format
into its suffix, assign the basename, then pass the complete structure's
character representation to the audited forward-append runtime alias.
An intrinsic memcpy probe instead used a counted copy. ISO strcat's
overlap contract is unsuitable when the appended NUL reaches the suffix;
document and test the target routine's exact forward-copy behavior.

Bind the real header and file stream consumers to EDI/ESI before the
null test. This keeps both original copies and the TEST live for retained
control flow. The compiler's private return cleanup can supply the
original full-frame epilogues when its register-save order, local size
and EAX return convention agree. Prove the stack layout and all restored
registers. If the function entry now comes from C, retained NASM must use
its first remaining virtual address; keep the original entry as an EQU.

Capstone may classify LOOP/LOOPE/LOOPNE only as BRANCH_RELATIVE. In a
shared external-call tail, reject those unverified transfers even when their
encoded displacements match: marker insertion can change the destination.
The regression uses the same rel8 byte to reach an ordinary NOP and a
marked end marker. Relocated E8 calls remain subject to complete target,
operand, addend, frame and return-path checks.
