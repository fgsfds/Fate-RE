/* Crush-bank initialization reconstructed from the pinned FATE executable.
 * klabs pragma from Build Engine & Tools, Copyright (c) 1993-1997 Ken Silverman.
 * See ../engine/BUILDLIC.TXT. The remaining function is reconstructed C.
 */

#pragma aux klabs =\
	"test eax, eax",\
	"jns skipnegate",\
	"neg eax",\
	"skipnegate:",\
	parm nomemory [eax]\


#pragma pack(push, 1)
typedef struct {
    short wallptr, wallnum;
    long ceiling_z, floor_z;
    char reserved[16];
    signed char floor_shade;
    char reserved2[3];
    unsigned char visibility;
    char reserved3;
    unsigned short lotag;
    char reserved4[4];
} InitCrushSector;
typedef struct { long x, y; char reserved[24]; } InitCrushWall;
typedef struct {
    short sector;
    long ceiling_z, floor_z, from_ceiling_z, to_ceiling_z;
    unsigned char visibility;
    signed char initial_shade, shade;
    long state[10];
    char reserved[3];
} CrushEntry;
typedef struct { long enabled, count; CrushEntry entries[16]; } CrushBank;
#pragma pack(pop)
extern CrushBank crush_init_banks[];
extern InitCrushSector crush_init_sectors[], *crush_current_sector;
extern InitCrushWall crush_init_walls[];
extern short crush_init_num_sectors;
extern char crush_init_invalid_text[], crush_init_limit_text[];
extern void crush_init_error(const char *);
extern void crush_init_clear(long);
extern int crush_init_predicate(short);

void init_crush_bank(long index)
{
    CrushBank *bank;
    long sector, wall, y, x, count, divisor, shade, numerator;
    short first, last;
    if (index < 0 || index >= 25) crush_init_error(crush_init_invalid_text);
    bank = &crush_init_banks[index];
    if (bank->enabled == 1) return;
    crush_init_clear(index);
    for (sector = 0; sector < crush_init_num_sectors; sector++) {
        crush_current_sector = &crush_init_sectors[sector];
        if (bank->count == 16) crush_init_error(crush_init_limit_text);
        if (crush_init_predicate(sector) == 1) {
            shade = crush_init_sectors[sector].floor_shade;
            if (shade > 32) crush_init_sectors[sector].floor_shade = 32;
            else if (shade < -32) crush_init_sectors[sector].floor_shade = -32;
            bank->entries[bank->count].sector = sector;
            bank->entries[bank->count].ceiling_z = crush_init_sectors[sector].ceiling_z;
            bank->entries[bank->count].from_ceiling_z = crush_init_sectors[sector].ceiling_z;
            bank->entries[bank->count].to_ceiling_z = crush_init_sectors[sector].ceiling_z;
            bank->entries[bank->count].floor_z = crush_init_sectors[sector].floor_z;
            bank->entries[bank->count].visibility = crush_init_sectors[sector].visibility;
            bank->entries[bank->count].initial_shade = crush_init_sectors[sector].floor_shade;
            bank->entries[bank->count].shade = crush_init_sectors[sector].floor_shade;
            numerator = bank->entries[bank->count].floor_z - bank->entries[bank->count].from_ceiling_z;
            divisor = klabs(32 - bank->entries[bank->count].shade);
            if (divisor == 0) divisor = 1;
            bank->entries[bank->count].state[2] = numerator / divisor;
            switch (crush_init_sectors[sector].lotag) {
            case 100: bank->entries[bank->count].state[3] = 1; bank->entries[bank->count].state[4] = 1; break;
            case 101: bank->entries[bank->count].state[3] = 4; bank->entries[bank->count].state[4] = 4; break;
            case 102: bank->entries[bank->count].state[3] = 12; bank->entries[bank->count].state[4] = 12; break;
            case 103: bank->entries[bank->count].state[3] = 32; bank->entries[bank->count].state[4] = 32; break;
            case 104: bank->entries[bank->count].state[3] = 128; bank->entries[bank->count].state[4] = 128; break;
            case 105: bank->entries[bank->count].state[3] = 1; bank->entries[bank->count].state[4] = 1; bank->entries[bank->count].state[7] = 1; bank->entries[bank->count].state[8] = 1; break;
            case 106: bank->entries[bank->count].state[3] = 6; bank->entries[bank->count].state[4] = 6; bank->entries[bank->count].state[7] = 1; bank->entries[bank->count].state[8] = 1; break;
            case 107: bank->entries[bank->count].state[3] = 32; bank->entries[bank->count].state[4] = 32; bank->entries[bank->count].state[7] = 1; bank->entries[bank->count].state[8] = 1; break;
            case 108: bank->entries[bank->count].state[3] = 64; bank->entries[bank->count].state[4] = 64; bank->entries[bank->count].state[7] = 1; bank->entries[bank->count].state[8] = 1; break;
            case 109: bank->entries[bank->count].state[3] = 160; bank->entries[bank->count].state[4] = 160; bank->entries[bank->count].state[7] = 1; bank->entries[bank->count].state[8] = 1; break;
            case 110: bank->entries[bank->count].state[3] = 1; bank->entries[bank->count].state[4] = 1; bank->entries[bank->count].state[7] = 1; bank->entries[bank->count].state[8] = 0; break;
            case 111: bank->entries[bank->count].state[3] = 6; bank->entries[bank->count].state[4] = 6; bank->entries[bank->count].state[7] = 1; bank->entries[bank->count].state[8] = 0; break;
            case 112: bank->entries[bank->count].state[3] = 32; bank->entries[bank->count].state[4] = 32; bank->entries[bank->count].state[7] = 1; bank->entries[bank->count].state[8] = 0; break;
            case 113: bank->entries[bank->count].state[3] = 64; bank->entries[bank->count].state[4] = 64; bank->entries[bank->count].state[7] = 1; bank->entries[bank->count].state[8] = 0; break;
            case 114: bank->entries[bank->count].state[3] = 160; bank->entries[bank->count].state[4] = 160; bank->entries[bank->count].state[7] = 1; bank->entries[bank->count].state[8] = 0; break;
            }
            first = crush_init_sectors[sector].wallptr;
            last = first + crush_init_sectors[sector].wallnum;
            y = x = 0;
            for (wall = first; wall < last; wall++) {
                x += crush_init_walls[wall].x;
                y += crush_init_walls[wall].y;
            }
            count = last - first;
            if (count) { x /= count; y /= count; }
            bank->entries[bank->count].state[5] = x;
            bank->entries[bank->count].state[6] = y;
            bank->count++;
        }
    }
    bank->enabled = 1;
}
