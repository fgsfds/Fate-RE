enum { SPRITE_BYTES = 44u, SECTOR_BYTES = 40u };

extern short numsectors, headspritesect[], nextspritesect[], tilesizy[];
/* These bases point to the corresponding fields in the packed engine tables. */
extern const unsigned char crusher_floor[], crusher_ceiling[];
extern const unsigned char crusher_sprite_tile[], crusher_sprite_repeat[];
extern const char crushed_sprite_bad_sector[], crushed_sprite_null_record[];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];
/* These calls pass a sign-extended sprite index in EAX. */
extern int check_player_index(int);
#pragma aux check_player_index "is_first_player_sprite_" modify exact [eax];
extern void crush_sprite_index(int);
#pragma aux crush_sprite_index "crush_sprite_" modify exact [eax];

/* These annotations keep the original traversal and collision registers. */
extern int keep_next_sprite(int);
#pragma aux keep_next_sprite = "" parm [ecx] value [ecx] modify exact [];
extern long keep_sprite_height(long);
#pragma aux keep_sprite_height = "" parm [esi] value [esi] modify exact [];
extern long keep_projected_clearance(long);
#pragma aux keep_projected_clearance = "" parm [edx] value [edx] modify exact [];
extern int keep_sprite_index(int);
#pragma aux keep_sprite_index = "" parm [eax] value [eax] modify exact [];
/* Only the low byte is loaded, so mask the register after reading it. */
extern unsigned extract_repeat_register(unsigned char);
#pragma aux extract_repeat_register = "" parm [dl] value [edx] modify exact [];
extern int keep_crusher_walker(int);
#pragma aux keep_crusher_walker = "" parm [edx] value [edx] modify exact [];
extern long keep_crusher_sector_size(long);
#pragma aux keep_crusher_sector_size = "" parm [eax] value [eax] modify exact [];

extern short keep_crush_sector(short);
#pragma aux keep_crush_sector = "" parm [di] value [di] modify exact [];

void check_crushed_sprites(const void *crusher, short sector_index)
{
    int index;

    if (sector_index < 0 || sector_index >= numsectors)
        report_game_error(crushed_sprite_bad_sector);
    if (!crusher)
        report_game_error(crushed_sprite_null_record);
    sector_index = keep_crush_sector(sector_index);
    index = headspritesect[sector_index];
    goto test_sprite;
    do {
        int sprite_index = (short)index;
        int player_index = keep_sprite_index(sprite_index);
        int next = keep_next_sprite(nextspritesect[index]);
        if (!check_player_index(player_index)) {
            long displacement = keep_crusher_walker(index * (unsigned)SPRITE_BYTES);
            long height = keep_sprite_height((long)tilesizy[*(const short *)(crusher_sprite_tile + displacement)]);
            unsigned repeat = extract_repeat_register(crusher_sprite_repeat[displacement]) & 0xff;
            height *= repeat;
            {
                long sector_scale = keep_crusher_sector_size(((unsigned)SECTOR_BYTES / 8) * sector_index);
                long clearance;
                height = keep_sprite_height(height * 2);
                clearance = keep_projected_clearance(*(const long *)(crusher_floor + sector_scale * 8));
                if (clearance - height < *(const volatile long *)(crusher_ceiling + sector_scale * 8))
                    crush_sprite_index(sprite_index);
            }
        }
        index = next;
    test_sprite:
        ;
    } while (index >= 0);
}
