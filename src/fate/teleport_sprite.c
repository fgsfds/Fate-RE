#include "copybuf.h"

#pragma pack(push, 1)
typedef struct {
    long x, y, z;
    short cstat, picnum;
    signed char shade;
    unsigned char pal, clipdist, filler, xrepeat, yrepeat;
    signed char xoffset, yoffset;
    short sectnum, statnum, ang, owner, xvel, yvel, zvel, lotag, hitag, extra;
} GameSprite;
typedef struct { long x, y, z; } SpritePosition;
#pragma pack(pop)

extern GameSprite game_sprites[];
extern SpritePosition sprite_old_positions[];
extern unsigned char sprite_visibility[];
extern const unsigned char show_2d_sectors[];

extern void resolve_teleport_destination(long *, long *, long *, short *, short *);
#pragma aux resolve_teleport_destination parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern int changespritesect(short, short);
#pragma aux changespritesect modify exact [eax ebx edx];
/* This view starts at the sectnum field of the first sprite. */
typedef struct {
    short number;
    unsigned char rest[42];
} SpriteSector;
extern const SpriteSector sprite_sector_numbers[];

extern unsigned char keep_visibility_byte(unsigned char);
#pragma aux keep_visibility_byte = parm [bl] value [bl] modify exact [];
extern int keep_sector_offset(int);
#pragma aux keep_sector_offset = parm [ebx] value [ebx] modify exact [];

/* Empty constraints preserve the original scheduling without emitting code.
   The masked sector supplies a shift count in 0..7, including for negative
   signed sector values; no unmasked machine-register count is used in C. */
extern short keep_sector_bit(short);
#pragma aux keep_sector_bit = "" parm [cx] value [cx] modify exact [esi];
extern unsigned long keep_sector_mask(unsigned long);
#pragma aux keep_sector_mask = "" parm [esi] value [esi] modify exact [];
extern long keep_sector_shift(long);
#pragma aux keep_sector_shift = "" parm [ecx] value [ecx] modify exact [ebx];
extern unsigned long sector_byte_in_ebx(void);
#pragma aux sector_byte_in_ebx = value [ebx] modify exact [];

void teleport_sprite(short sprite)
{
    short sector = sprite_sector_numbers[sprite].number;
    GameSprite *position = &game_sprites[sprite];
    unsigned char bit;

    resolve_teleport_destination(&position->x, &position->y, &position->z, &position->ang, &sector);
    copybuf(position, &sprite_old_positions[sprite], 3);
    changespritesect(sprite, sector);
    bit = 1 << (sprite & 7);
    sprite_visibility[sprite >> 3] &= ~bit;
    {
        /* Stage BL; the masked full-register read below clears its upper bits. */
        unsigned char visible = keep_visibility_byte(show_2d_sectors[keep_sector_offset(sector >> 3)]);
        short shift = keep_sector_bit(sector & 7);
        unsigned long mask = keep_sector_mask(1);
        long count = keep_sector_shift(shift);
        keep_sector_offset(sector_byte_in_ebx() & 255);
        mask = keep_sector_mask(mask << count);
        if (sector_byte_in_ebx() & mask)
            sprite_visibility[sprite >> 3] |= bit;
    }
}
