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

The startup actor disable loop needs the complete constructor's register
allocation. An isolated signed-word loop keeps its counter in BX and adds
EAX/EDX copies. In the full typed constructor, a truthful empty int identity
with `parm nomemory [edx] value [edx] modify exact [edx]` in the `<= 500`
condition emits the original `MOVSX EDX,AX; CMP EDX,500` while retaining the
EAX counter. The conservative EDX clobber blocks comparison-value reuse.
The six-register save frame and both internal branches match as one 33-byte
prefix. That frame remains live into retained assembly; the complete context
and all fixups are guarded, and the fixture checks its exact saved words,
501 ordered writes, arithmetic flags and whole-routine restoration. Do not
infer a whole-constructor match from the prefix. Source:
`src/fate/board_actor_configuration.c`, `ACTOR_DISABLE_CONTEXT`.

For a destination assignment whose `MOVSX EDX,AX` is hoisted past a waypoint
store, qualify the complete typed assignment using both compiler fragments.
The omitted store must read no EDX alias and change no register or flags;
check its typed address/value and keep the original store order. Guard the
entire compiler object, pin all fragment boundaries and DATA sites, exclude
incoming branches, and replay both the natural and commuted contexts. Check
the original site's live AX too: identical destination bytes occur for other
actors, so byte equality and injected test inputs do not establish placement.
Use separate fragment metadata; retain strict contiguous-operation partitions.
The actor-104/105 X fixtures include duplicate-byte wrong-actor controls.

Keep DOS compiler argument tails short by deriving related context macros
from one selector, as in `ACTOR_CLOBBER_CONTEXT`. The three-selector probe
produced `AC.OBJ` instead of the requested `ACTCLOB.OBJ` despite zero compiler
errors; the production missing-object check rejected it. The single selector
produces the intended object with the same CODE and parsed fixups as the probe.
Merge existing conditional pragma blocks as complete blocks when adding a new
selector. Mechanically wrapping diff hunks can misnest existing `#else` and
`#endif` directives. Recompile every affected prior selector and compare its
full CODE and parsed OMF before qualifying the new variant.


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


### RNG byte projections and signed union word counts

The encounter draw witness uses truthful AH/DH/BH projections and a join of
disjoint low/high byte inputs. After copying the actual raw EAX value into EDX
or EBX, XORing the copied high byte with AH produces zero while preserving EAX.
Watcom emits the original MOV/XOR pair. The pinned RNG returns 0..32767 and
preserves the other registers. Keep that domain and the incoming register proof;
do not claim arbitrary upper bits are zero from a narrow return declaration.
`src/fate/encounter_byte.c` supplies the compact context, and the encounter
fixture separately executes its complete private algorithm before qualifying
pure conversion/mask slices. A full draw context that grew the frame to 188
bytes was rejected as a frame replacement. Its spills are not production code.

For masked 0/1 shift counts, writing a union's full unsigned dword and reading
its low signed word preserves the four-byte store while producing the original
MOVSX word load on the pinned little-endian compiler. A signed short x count
similarly produces MOVSX ECX,BX. Guard zero-length literal prefixes explicitly
as well as nonempty ones: a body digest and absolute fixup snapshot alone do
not prove the public stayed at zero. The empty-prefix digest and a moved-public
counterexample make that layout check part of the binder itself.

### Word operands and standalone signed promotion

The encounter operand context carries a masked low-byte draw through a real DX
word identity, then promotes that signed word through an EBX identity before
both table loads. This yields the original AND DL / MOVSX EBX,DX and ESP+EBX*8
addressing in the 184-byte frame. For the tile word, a DX-to-EDX capture may
leave the upper word unspecified: unsigned addition followed by a short store
depends only on the low word. Prove that truncation explicitly. The placed
original byte producer supplies zero upper bits, while the natural private
prefix can retain poisoned upper bits without changing its modeled effects.
Its natural terminal register differences are not a shared-ABI acceptance.

An AX width identity and DL/AL byte identities preserve the original table
word load and repeat transfer. When the large context still emits MOV EBX,EAX
followed by MOVSX EBX,BX, a standalone C conversion with an int EAX parameter,
int EBX result and body `return (short)value;` emits MOVSX EBX,AX and a private
RET. `src/fate/encounter_width.c` guards that complete four-byte context. Its
fixture poisons the input upper word and checks signed results and preserved
registers. A zero-extension control produces the same clipped byte but the
wrong terminal EBX, so DATA-only replay would miss that ABI error.

### State-machine tables and DATA views

For unrolled startup records, an actual signed-short AX argument/result
identity can keep the configured slot runtime-indexed instead of folding
every address into a constant. Retain the real field types and whole-array
bounds. Qualify complete scalar assignments or full coordinate pairs, including
their address preparation and masked live inputs. Coalesce only when both the
original and compiler intervals are adjacent. Guard the entire private code
and every fixup, including the many excluded configuration stores.

Operation fixtures should require canonical field tuples and exact partitions
of each placed run. Otherwise dropping a Y write from metadata may escape a
whole-routine replay that still contains the original instruction. Use exact
complements of the same poisoned register seed before applying live masks, so
each omitted input bit is challenged in one of the cases.

A whole-array character view should start from `&array`, so byte arithmetic
can cover all rows rather than only the first element. Separate mutable X/Y
word views of the same verified DATA object can retain two indexed load
displacements instead of a shared relocated pointer addition. Capture the
three-times-slot factor in EDX and the signed frame in BX; widening the frame
to EAX before the two shifts reproduces the original byte-offset sum and its
return flags. Preserve the in-DATA lookup domain and alignment explicitly.

Use a distinct external name for a typed view when another translation unit
already exposes the storage through a different C type. A normalized OMF
public tuple omits PUBDEF group/type fields. For a shared multi-public object,
pin the full CODE and raw semantic EXTDEF/PUBDEF/LNAMES/SEGDEF/GRPDEF records
alongside all parsed fixup forms, names and addends. A checksum-valid FLAT-to-
DGROUP PUBDEF mutation can otherwise pass a normalized-layout check.

To preserve a volatile field-transfer sequence, name the table value and the
next signed slot separately: load the table word, capture the requested slot
as an int, then store the previous word. In weapon animation this produces
`MOVSX EDX,[requested_weapon]` before the AX store; a direct assignment had
placed the store first. Check that order from the actual selected instructions.
Truthful SI/BX identities can retain a displayed slot and signed frame word
across the default-frame join. A private compiler context may save fewer
registers than production when the selected operations have no stack/frame
dependence and the original entry, return and all continuations remain exact.

Promoting the actual signed state through an empty full-EDX identity after
the idle branch keeps the tick flag live in EAX and restores active-state
dispatch groups. Keep the original short-DX capture before that branch.
These lifetimes can require separate guarded whole-algorithm contexts; the
state allocation alone does not also fix the earlier clock load/store.
For reused pure index intermediates, prove the same input and result at
each placement: `3 * slot` may feed either a 24-byte definition or a 96-byte
frame row. Preserve each original continuation, other live registers, flags
and memory order, and check that no branch enters inside the selected group.

Nominal table bounds need not describe every original lookup. Weapon slot zero
uses zero lowering/base/ready tiles, so its frame lookup can use index -1053
and read before the nominal offset table. Model the resolved address, then use
an appropriately bounded mutable DATA view when the original can reach other
fields. The pinned LE object's virtual extent is `0x28a300`, distinct from its
stored file bytes and the emulator's larger mapped address space. Derive that
extent from the LE object table; keep stub markers inside the intended object.
Document valid definition-slot and resolved-address preconditions separately.

Final-memory and callback models do not prove volatile access order or clock
interrupt interleavings. Keep the selected instructions' ordered accesses and
branch-entry contracts as separate evidence. A complete private C replay can
match all state effects and callee-saved registers while returning different
raw EAX bits or flags; those differences cannot qualify a shared ABI boundary.

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


For the sound archive phase, assign the unsigned scaled index to a normal
first-use value, then store it to the volatile stack scratch. Use that normal
value for the first lookup and reload the scratch only after the real CRT
calls. Reading the volatile spill immediately after writing it instead emits
an extra MOV. Preserve each required volatile access during placement.
The 125-byte context in `sound_playback_archive.c` supplies 118 selected bytes
while borrowing [ESP]; its private SUB/ADD/RET are excluded and guarded.
Both aborting failure continuations compile as near Jcc fixups to the shared
frame return, with no CALL or pushed return word. Check the actual transfer
opcodes and frame contract; an `aborts` declaration alone proves neither.
The direct archive-entry fixture covers the full-slot edge that normal
whole-routine execution preempts earlier in the slot scan.


In `sound_playback_cache.c`, a getter reads the active index still live in
EBX immediately after the full-slot comparison. Reusing a C local instead
introduced an EAX copy before the cache gate. Prove the register survives
the guard and preserve its full-width domain. The 79-byte private lookup
context ends in RET at offset 78; cropping that byte places both the short
miss branch and exhausted-loop fallthrough directly at the next archive C
phase. Guard the full context and both external continuations, then exercise
all four exit paths. No opcode rewrite or new transfer is needed.


The slot scan in `sound_playback_slots.c` stages the unsigned 240-byte stride
as shift/subtract/shift. Register-only data dependencies retain the ESI base
between the shifts and the EBX count before the final add. Its ESI getter reads
the base established by the preceding producer, before any clobber. A copy of
the real cache-entry guard supplies a shared successor in the 109-byte private
context, preventing a tail JMP to memset or cloned cache transfers. Only the
first 93 bytes are linked; check the excluded 15-byte guard against installed
cache code and its typed LE site, and guard the final private RET separately.
The narrow fill alias relies on the pinned CRT saving EAX/ECX and retaining
ESI while EDX may change; the fixture models that contract with a stub, rather
than independently executing the real CRT.


The completed playback frame uses a valid 760-byte full C context around the
already accepted middle phases. An emitted reverse EAX copy is idempotent after
MOV EDI,EAX and can be excluded after proving equality along every comparison
path. A separate signed C predicate supplies the exact six-byte CMP EDI,163
instead of the private context's five-byte EAX comparison; the placed JLE consumes
identical comparison flags. Guard the predicate's entire SETcc/mask/RET suffix,
not merely its matching prefix. Two near return jumps retain their opcodes and
widths while rebinding the checked compiler-local epilogue target. Verify the
excluded five-byte success load and DATA LE against its installed C provider.

Do not replace a real C lifetime with repeated naked register getters throughout
an unlinked full context: the allocator may repurpose that register. A mixed
placement can still pass while the private algorithm fails. The accepted frame
keeps the actual sound variable and passes natural whole-context cases as well
as placed cases. Keep its custom hidden EBX input and public-name distinction
explicit, and match shared global and real-callee types. No new padding,
handwritten instructions or volatile-access reordering is required.

For keyboard motion, calculate additions, subtractions, scaled steps and limit
negation in unsigned long before converting to signed long for clamps. This
preserves x86 wrap at extreme loaded state, including INT_MIN limits. Key
consumption may alias later configurable keys: model and execute each clear
before the next lookup. Only commute fixed DATA loads after checking register,
flags, memory and branch-entry independence in both instruction streams.

Watcom may assign one storage location to a repeatedly reused C temporary.
Extending a routine across calls can therefore spill even previously matched
blocks. Distinct locals scoped to complete operations removed those spills in
the input collector: the private context shrank from 1,415 to 1,300 bytes and
retained all 686 earlier selected bytes while adding 131. Recheck the complete
context and old slices after this change. Explicit EBP parameter/result pragmas
are rejected by 10.5 with E1122; leave EBP allocation to the compiler.

A four-sample smoothing table can receive negative signed indices when its
index only has an upper reset. Model the actual LE DATA backing object and
all aliasing stores; an enlarged table declaration is not a bounds proof.
The input history reaches DATA bytes 0x75292..0x85299, and an incoming index
of -14798 changes the packed forward byte before it is read again. Check
volatile read order independently of sums: swapping sample reads 1 and 0
can preserve every result and register. For selected branches, also bind
the compiler successor to the logical placed entry; a same-opcode branch
from another condition can otherwise pass byte normalization.

A compiler return suffix can follow a retained POP EBP when its five saved
registers and return address have exactly the original stack layout. Exclude
private local cleanup and verify both original incoming return branches, the
restored EBP boundary, saved registers and sentinel through the real RET.
For volatile FIFO indices, identical results do not prove access order: count
every repeated read, and keep malformed stable states as bounded cycles
rather than normalizing their indices or claiming termination.

For an interrupt-owned byte, a distinct volatile external alias can retain
direct DATA-relative operands where a local volatile pointer induces indirect
addressing. Bind the alias to the independently verified byte offset, explicitly
sequence the condition samples, and preserve every repeated read. Requalify all
previous slices: this FIFO change altered 17 earlier action bytes despite an
unchanged source prefix, so its 52-byte phase uses a separate guarded context.

A short-register identity at a final word store may keep a clamp result in EAX
even when its constants are staged in EBX. Passing the full long result through
the EBX identity before truncating the store removed that join copy in the
vertical map clamp. Constant constraints alone did not fix it. Requalify all
prior slices; the X/Y/scale joins still need a distinct lifetime solution.
