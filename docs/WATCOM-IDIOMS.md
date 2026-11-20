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
