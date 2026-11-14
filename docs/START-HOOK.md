# START map hook and the per-map dispatcher

The original behavior was verified with nine bounded emulator fixtures. The
reconstructed hook is included in the exact executable build.

## Inputs and address model

FATE.EXE SHA-256:
`61df230ffb83629764f8c2656f068c6fbcfa17d5180eafb660504b6069a0906f`.
START.MAP SHA-256:
`812f8deec1af874af4d71ed7bb21ddc70a3d40a2a3844ffa83713156e1a61b1e`.
Both original inputs were read-only. Code addresses below are loaded linear
addresses (LE object 1 base `0x10000`); code raw file offset is address plus
`0x25600`. Global `DS:` values are original object-2-relative operands; add
`0x80000` for loaded addresses. Relocations are applied before emulation.

The full wcdatool output identified the bounded dispatch table, then focused
Capstone 5.x decoding and the original LE records established instruction and
pointer boundaries. See [the full-pipeline evidence](WCDATOOL-FULL.md).

## Dispatcher

The map-name lookup at `0x3b404..0x3b496` searches the fixed-width names at
`DS:0x2041` and stores the selected index at `DS:0x7f87e`. The dispatcher
at `0x1e7b0..0x1e91a` uses the 25-entry table at `0x1e74c` for selectors
1 through 25. Selectors 3, 4, 5 and 7 call the ALTER, POWER, POWER2 and
START hooks. The other in-range selectors call return-only stubs.

## START behavior

The 361-byte START hook occupies `0x1e5d1..0x1e73a` (end exclusive).
It clears the lotags of sectors 87, 76, 75, 74, 72, 86, 80, 79, 78, 77,
56, 57, 58, 59, 60 and 159 while guard `DS:0x12844` is zero. It tracks
whether sector 150 contains any sprite. On either occupation transition
it calls `0x34f79` with EAX set to 156, then calls `0x28710` for each listed
sector with its lotag temporarily set to 6.

While latch `DS:0x12840` is clear, the hook scans the event table for encoded
word `0x405d` paired with a sprite whose picnum is 527. For each match it calls
`0x10f9f` with the sprite index in EAX, sets the latch, sets bit 0 at
`DS:0x203c`, and writes tile 1673 to wall 761. The latch suppresses the scan
on later invocations. In the original map, wall 761 uses tile 1672 and sector
150 starts empty. The map contains no initial sprite with picnum 527.

## Verification

Run the bounded fixtures with Unicorn 2.1.4 from the repository root, using
`$original` from the [build guide](EXACT-BUILD.md).

```powershell
$env:PYTHONPATH = "work/ci-build/python-deps"
python tools/check_start_hook.py $original --output work/start-hook-oracle.json
```

The nine fixtures record calls to the three callees through stubs. They
cover both occupation transitions, the tag-clear guard, event matches and
near misses, and latch behavior. The report records the isolated hook
effects. [Fixture report](../tools/data/start-hook-oracle.json)
