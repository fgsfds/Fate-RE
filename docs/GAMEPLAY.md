# START.MAP movement and object behavior

Measured in the October 18, 1996 demo, SHA-256
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
Addresses below use the original LE code object's logical base 0x10000.
DS offsets refer to the data object at base 0x80000. The table and object
behavior below come from disassembly and executable extraction.

## Recovered behavior

| Routine / address | Recovered behavior |
| --- | --- |
| 0x34811 / 0x3483e | Timer registration at 120 Hz |
| 0x2d4ca–0x2d4e9 | Movement clock advances by three ticks: 40 Hz |
| 0x2b3ed | Player movement, collision and vertical physics |
| 0x2b4c6–0x2b5d8 | Forward scale 4 (walk), 8 (run); strafe scale twice forward |
| 0x2d820–0x2d9c5 | Forward acceleration 12, side acceleration 24, drag 6; output -120..119 |
| 0x26bc7–0x26bda | Initial eye z = sector floor minus 8192 |
| 0x28574–0x285bf | Low tag byte 100: center movable sprites and add cstat 0x181 |
| 0x1351a | Push tagged sprites at half player motion, radius clipdist*2 |
| 0x13860 | Falling movable-object physics |
| 0x10b8f | Melee hitscan from eye+2048, distance strictly below 350, random gate 1 in 4 |
| 0x11fdd | Start object sequence selected by high byte of sprite lotag |
| 0x123d6 | Advance object art, then set final tile and next sequence or delete |
| 0x144c9–0x144e3 | Object animation interval 12 timer ticks (10 Hz) |
| 0x3b609 | Initializes object sequence table at DS:0x6807c, stride 120 bytes |

Player collision uses Build clipmove: radius 128, ceiling distance 3000, floor
distance 5000; pushmove uses radius 128 and clearances 1024. getzrange uses radius
127. The standing eye target is floor-9216. If this intersects the ceiling+4096,
the target becomes the floor/ceiling midpoint. Jump lowers the target by 8192,
or 16384 when running; crouch raises it by 3072, or 6144 when running. Downward
velocity gains 96 each update; upward correction is `(target-eye)*3 >> 5`.
Eye z clamps to ceiling+1024 and floor-1024.

START sprite 44 is the cell door, tile 1515, sequence 28. Sequence 28 shows cracked
tile 1516 and transfers to sequence 29. Sequence 29 runs tiles 1517–1521 and retains
1521 as a final stump with no next sequence. The blocking flag remains set: Build
allows the player to step over the short remaining sprite. Each eligible punch has a 25% success gate.

Barrels 47 and 69 use sequence 55; barrel 70 uses sequence 50. All have low tag
100, tile 1362, yrepeat 37. Initialization moves their centers up by 4810, giving
a top height of floor-9620. Pushing moves their centers through Build collision.
Grates 43 and 78 use sequence 61, which holds
tile 1408 for one sequence interval and then deletes the sprite.

The map and executable evidence is recorded in the [door sprite report](../tools/data/start-door.json),
[melee hitscan report](../tools/data/start-door-hitscan.json), and [barrel report](../tools/data/start-barrels.json).
The [START map hook](START-HOOK.md) documents the sector-occupation and
event-table behavior selected by the map dispatcher.

## Reproducible executable extraction

`tools/recover_sequences.py` checks the exact executable hash, loads both LE
objects, applies all 23,359 relocations, and runs only the table initializer in
Unicorn's isolated x86 memory. It has instruction and time limits and checks the
return address. It does not launch FATE.EXE, emulate DOS, install host system-call
handlers, or write game files. It emits only the five relevant table records;
the recovered output is [sequences.json](../tools/data/sequences.json). Unicorn 2.1.4 was used.

## Reproducing the door and barrel reports

Use `$demo`, `$original`, `$build`, and the generated `c.json` from the
[build guide](EXACT-BUILD.md). The door fixtures use `rand.obj` from the
pinned Watcom 10.5 `CLIB3R.LIB`. The command below uses Watcom 11.0c WLIB to
extract that member. The barrel fixture uses the October 25, 1995
`ENGINE.OBJ` from the historical Build snapshot archive. Its SHA-256 is
`e2fed37d656b26ff6e8faefc1052b83c7379269f16795fcf8298b5632283e721`.

```powershell
$map = Join-Path $demo START.MAP
$art = Join-Path $demo TILES005.ART
$clib = 'reference/watcom105-full/LIB386/DOS/CLIB3R.LIB'
$engine = 'reference/buildsrc-20190520/buildsrc-20190520/19951025/ENGINE.OBJ'
New-Item -ItemType Directory -Force "$build/clib" | Out-Null
& reference/watcom110c/binnt/wlib.exe "-d=$build/clib" -x $clib

$door = @($original, $build, "$build/asm", "$build/c.json", $clib, "$build/clib/rand.obj", $map)
python tools/check_start_door.py @door --output "$build/start-door.json"
python tools/check_start_door.py @door --art $art --output "$build/start-door-hitscan.json"
python tools/check_start_barrels.py $original $engine $build "$build/asm" "$build/c.json" $map $art --output "$build/start-barrels.json"
python tools/recover_sequences.py $original --output "$build/sequences.json"
```

## DOSBox observations

The rebuilt executable loaded the prison cell on Easy. Mouse turning and the
punch animation were observed. Automated key taps did not establish forward
movement, running or jumping. Door breakage, crossing the threshold and barrel
movement were not verified in that session.
