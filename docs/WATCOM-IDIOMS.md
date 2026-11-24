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


A shared context can materialize a constant in a register to reuse it on a later
path, changing an otherwise simple memory store. `src/fate/encounter_reset.c`
isolates the actor reset from the exit scan so Watcom emits the immediate word
store. Its `aborts` continuation emits the original tail JMP while preserving
the caller's existing frame. Verify the complete standalone body and its branch
fixup before replacing the shared-frame assembly tail.


The encounter trigger phase uses `play_sound_` with an additional EDI input and
DI result to carry zero across the call. The pinned callee saves ESI/EDI/EBP,
overwrites EDI before consuming it internally, and restores all three at its
common return. Keep the original four game arguments and conservative
EAX/EBX/ECX/EDX clobbers. A two-byte compiler-generated EDI clear can be selected
separately when Watcom schedules it before the first sound call. Check that
intervening instructions do not consume the value or its flags, and compare
natural versus linked order with poisoned caller-clobbered registers.


The encounter position context initializes all bytes of a 32-bit unsigned union,
then constrains its byte fields to reproduce DH/AH clearing and DL masking.
After MOVSX EBX,DX, the masked index is already 0..15. A second MOVSX EBX,BX
is idempotent and flag-neutral; its exact bytes are guarded even though that
private instruction stays unlinked. The natural-order fixture retains it and
compares the frame, register handoff, and resulting sprite fields. A getter for
the legacy EBP height is valid only after the retained initializer on every
reaching path, including loop backedges that preserve EBP through callees.

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
