# Additional Build source references

These repositories were reviewed at the commits below, including the commercial
repository's nested Build archive. This is a pinned-tree comparison, not an
exhaustive search of their histories. References are not production link inputs
and never override Fate's exact machine code or LE relocations.

| Repository | Reviewed commit | Useful engine contents |
| --- | --- | --- |
| [NBlood/Redneck-Rampage-RE](https://github.com/NBlood/Redneck-Rampage-RE/) | `4109fb04260eaaddf9ccfcd5ef42bcd355b5f353` | `enginera/ENGINE.C`, `enginerr/ENGINE.C`, and `makemap/rr/engine/ENGINE.C`, with headers and assembly. Three distinct engine variants, not just game code. |
| [videogamepreservation/dukenukem3d](https://github.com/videogamepreservation/dukenukem3d) | `ef609159bd352985a0c63734a11241d86c873fe5` | `SRC/ENGINE.C` and `SRC/PRAGMAS.H`; engine C matches the pinned vanilla reference after CRLF/LF normalization. |
| [commercial-game-sources/duke_nukem_3d](https://github.com/commercial-game-sources/duke_nukem_3d) | `e75bb067c0d3eba8f716b7781a5c5b6ec93cc2d4` | `BuildEngine.zip` contains `SRC.ZIP`, which contains `ENGINE.C` and headers. Engine C is byte-identical to the pinned vanilla reference. |
| [NBlood/Blood-RE](https://github.com/NBlood/Blood-RE) | `4d4869a695a8799c2c564b53f8ef429dc3816599` | `3dfx/ENGINE.C` and headers; software engine is supplied as `build/ENGINE.LIB`, not corresponding software engine C in this tree. |

## Concrete findings

- None of the six inspected engine C files contains Fate's 2,048-entry
  seed-128 Newton/correction square-root initializer. All use the later
  4,096-entry `msqrtasm`/`shlookup` algorithm. Keep Fate's algorithm.
- The Duke and Redneck `loadtables` bodies corroborate one-time initialization,
  2,048 `divscale30` reciprocal entries, optional file loading, font/brightness
  reads, and setting `tablesloaded` even if opening fails. Their radar-angle
  layout is different: Fate reads 320 shorts after a 4,096-byte seek and sets
  entry 320 to 16,384; do not substitute their 640-short mirrored table.
  Blood's 3DFX variant omits the reciprocal initialization loop.
- The reviewed `PRAGMAS.H` files retain `klabs` as `TEST/JNS/NEG`, supporting
  the historical origin of Fate's inline absolute-value primitive. They also
  retain the sign primitive used by `keepaway`. These are assembly definitions,
  not proof that ordinary C absolute value will emit the same instructions.
- The Duke and Redneck `keepaway` loops use a byte axis toggle and a
  cross-product stopping condition. Fate's variant uses split coordinate
  arrays, a short clip index, and a shared collision exit.
- `raytrace`, `prepwall`, `wallmost`, and `owallmost` offer related expression
  and loop-order references. Larger remaining assembly has named C counterparts
  including `scansector`, `wallscan`, `maskwallscan`, `hitscan`, `getzrange`,
  `clippoly`, and `fillpolygon`. These remain version-sensitive leads, not
  already-qualified replacements.

## Reproducibility and hashes

Downloaded sources, full trees, pinned raw URLs, nested archive listings,
acquisition scripts, and manifests are under ignored
`work/additional-source-references/`. All **75 manifest file hashes** and the
six engine hashes below were rechecked. Preserve each source's attribution and
applicable license; inclusion in these repositories is not a new license grant.

| Engine file | SHA-256 |
| --- | --- |
| Commercial nested `ENGINE.C` | `73deb68fc2dc07dc668febbf70ab55441c8b9221cd541fb49792688b1de09760` |
| Preservation `SRC/ENGINE.C` | `6cfcd84a321af76063eeda911d11df494abde4347239c195e4f70a73553d9933` |
| Redneck `enginera/ENGINE.C` | `4b38ab7cf6e06bf1b82fcf6fd0671fbfaf85aca70c5ae85d46d08ad3b0b6f6de` |
| Redneck `enginerr/ENGINE.C` | `0dac4eeaa4c792aeac626877e1815cdd899a3e66c9e5900c4d9558570229ec2c` |
| Redneck `makemap/rr/engine/ENGINE.C` | `b84684e8be46b21a32ebab4d57e15d785c4e5203a287df734b4d848b6b5c1a82` |
| Blood `3dfx/ENGINE.C` | `5c720cca820de0eb18a277157e2c400c774457db52c1ebf46c2309ca2038babc` |
