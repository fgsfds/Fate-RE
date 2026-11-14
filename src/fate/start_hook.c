/* Reconstructed START-specific behavior; provisional names, not original names.
 * See docs/START-HOOK.md. Structs expose only accessed Build fields.
 * Matching status is recorded separately; this file alone claims no byte match.
 */
typedef struct { char before_lotag[34]; short lotag, hitag, extra; } HookSector;
typedef struct { char before_picnum[14]; short picnum; char rest[28]; } HookSprite;
typedef struct { char before_picnum[16]; short picnum; char rest[14]; } HookWall;
typedef struct { short sprite; unsigned short encoded; } HookEvent;

extern HookSector hook_sectors[];
extern HookSprite hook_sprites[];
extern HookWall hook_walls[];
extern HookEvent hook_events[];
extern short hook_event_count, hook_headspritesect[], hook_nextspritesect[];
extern long hook_done;
extern short hook_guard, hook_current, hook_previous, hook_sector_list[16];
extern unsigned char hook_flags;
extern void hook_effect(long, long, long, long);
extern void hook_sector_action(short);
extern void hook_remove(short);

void start_hook(void)
{
    short i, sprite;
    unsigned short encoded;
    if (!hook_guard)
        for (i = 0; i < 16; i++)
            hook_sectors[hook_sector_list[i]].lotag = 0;
    hook_current = 0;
    for (i = hook_headspritesect[150]; i >= 0; i = hook_nextspritesect[i])
        hook_current = 1;
    if (hook_previous != hook_current) {
        hook_previous = hook_current;
        hook_effect(156, 0, 0, 0);
        for (i = 0; i < 16; i++) {
            hook_sectors[hook_sector_list[i]].lotag = 6;
            hook_sector_action(hook_sector_list[i]);
            hook_sectors[hook_sector_list[i]].lotag = 0;
        }
    }
    if (!hook_done)
        for (i = 1; i <= hook_event_count; i++) {
            sprite = hook_events[i].sprite;
            encoded = hook_events[i].encoded;
            if (encoded < 32768 && (unsigned short)(encoded - 16384) == 93 &&
                hook_sprites[sprite].picnum == 527) {
                hook_remove(sprite);
                hook_done = 1;
                hook_flags |= 1;
                hook_walls[761].picnum = 1673;
            }
        }
}
