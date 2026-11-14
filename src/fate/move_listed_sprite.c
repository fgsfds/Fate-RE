/* Exact movement-list caller at loaded 0x1351a. Local declaration order
 * preserves the original Watcom register allocation and stack slots. */
#pragma pack(push, 1)
typedef struct {
    long x, y, z;
    short cstat, picnum;
    signed char shade;
    unsigned char pal, clipdist, filler, xrepeat, yrepeat;
    signed char xoffset, yoffset;
    short sectnum, statnum, ang, owner, xvel, yvel, zvel, lotag, hitag, extra;
} MoveSprite;
#pragma pack(pop)
extern MoveSprite move_sprites[];
extern short move_tile_heights[];
extern int move_clip(long *, long *, long *, short *, long, long, long, long, long, unsigned long);
extern int move_change_sector(short, short);
extern void move_zrange(long, long, long, short, long *, long *, long *, long *, long, unsigned long);
extern void move_add_listed(short);

void move_listed_sprite(short sprite, long xvector, long yvector)
{
    short saved_cstat;
    long ceiling_z;
    long ceiling_hit;
    short sector;
    long height;
    long floor_z;
    long floor_hit;
    long x;
    long y;
    long z;
    if ((long)(short)(move_sprites[sprite].lotag & 255) != 100 || move_sprites[sprite].zvel != 0)
        return;
    height = (move_tile_heights[move_sprites[sprite].picnum] * move_sprites[sprite].yrepeat) << 1;
    x = move_sprites[sprite].x;
    y = move_sprites[sprite].y;
    z = move_sprites[sprite].z;
    sector = move_sprites[sprite].sectnum;
    move_clip(&x, &y, &z, &sector, xvector >> 1, yvector >> 1,
              move_sprites[sprite].clipdist << 1, height, height, 0);
    if (sector >= 0 && sector != move_sprites[sprite].sectnum)
        move_change_sector(sprite, sector);
    saved_cstat = move_sprites[sprite].cstat;
    move_sprites[sprite].cstat &= ~1;
    move_zrange(x, y, z, sector, &ceiling_z, &ceiling_hit, &floor_z, &floor_hit,
                move_sprites[sprite].clipdist << 1, 0);
    move_sprites[sprite].cstat = saved_cstat;
    if (floor_z - height - move_sprites[sprite].z > 0) {
        move_sprites[sprite].xvel = xvector >> 8;
        move_sprites[sprite].yvel = yvector >> 8;
        move_sprites[sprite].zvel = 100;
        move_sprites[sprite].extra |= 0x1000;
        move_add_listed(sprite);
    }
    move_sprites[sprite].x = x;
    move_sprites[sprite].y = y;
}
