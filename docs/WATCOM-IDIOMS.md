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
  retain its second input in EDX across the call.
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
