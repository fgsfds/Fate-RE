#pragma pack(push, 1)
typedef struct {
    long x, y, z;
    short cstat, tile;
    char reserved1[2];
    unsigned char clipdist;
    char reserved2[2];
    unsigned char yrepeat;
    char reserved3[2];
    short sectnum;
    char reserved4[18];
} MoveSprite;
#pragma pack(pop)

extern MoveSprite move_sprites[];
extern short move_tile_heights[];
extern long move_ceiling_z, move_ceiling_hit, move_floor_z, move_floor_hit;
extern int move_clip(long *, long *, long *, short *, long, long, long, long, long, unsigned long);
extern int move_change_sector(short, short);
extern void move_zrange(long, long, long, short, long *, long *, long *, long *, long, unsigned long);
#pragma aux move_clip modify exact [eax ebx ecx edx];
#pragma aux move_change_sector modify exact [eax edx];
#pragma aux move_zrange modify exact [eax ebx ecx edx];

/* Keep the sprite offsets and collision result in their original Watcom registers. */
extern int preserve_collision(int);
#pragma aux preserve_collision = parm [edi] value [edi] modify exact [];
extern short hold_cstat(short);
#pragma aux hold_cstat = parm [ax] value [ax] modify exact [];
extern int hold_alignment_flag(int);
#pragma aux hold_alignment_flag = parm [eax] value [eax] modify exact [];
extern short hold_clipped_sector(short);
#pragma aux hold_clipped_sector = parm [dx] value [dx] modify exact [];

extern int hold_repeat(int);
#pragma aux hold_repeat = parm [eax] value [eax] modify exact [];

int move_sprite(short slot, long dx, long dy, long dz, int ceiling_distance, int floor_distance, int clip_type);
#pragma aux move_sprite parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
int move_sprite(short slot, long dx, long dy, long dz, int ceiling_distance, int floor_distance, int clip_type)
{
    MoveSprite *target = &move_sprites[slot];
    int z_offset;
    short where, saved_cstat;
    short clipped_sector;
    int collision, raw_collision;
    long z;

    if (!hold_alignment_flag((short)hold_cstat(target->cstat) & 128)) {
        z_offset = -(2 * (hold_repeat(target->yrepeat) * move_tile_heights[target->tile]));
    } else
        z_offset = 0;

    where = target->sectnum;
    z = target->z + z_offset;
    raw_collision = move_clip(&target->x, &target->y, &z, &where, dx, dy,
                              target->clipdist << 2, ceiling_distance, floor_distance, (unsigned char)clip_type);
    clipped_sector = hold_clipped_sector(where);
    collision = preserve_collision(raw_collision);
    if (clipped_sector < 0)
        collision = -1;
    if (where != target->sectnum && where >= 0)
        move_change_sector(slot, where);

    /* Exclude the moving sprite from the vertical collision query. */
    saved_cstat = target->cstat;
    target->cstat &= ~1;
    move_zrange(target->x, target->y, target->z - 1, target->sectnum,
                &move_ceiling_z, &move_ceiling_hit, &move_floor_z, &move_floor_hit,
                target->clipdist << 2, (unsigned char)clip_type);
    target->cstat = saved_cstat;

    z = target->z + z_offset + dz;
    if (z <= move_ceiling_z || z > move_floor_z) {
        if (!(short)collision)
            return 0x4000 + where;
    } else {
        target->z = z - z_offset;
    }
    return (short)collision;
}
