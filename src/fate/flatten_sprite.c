#pragma pack(push, 1)
typedef struct {
    long x, y, z;
    short cstat, tile;
    char shade_palette_clip[2];
    unsigned char xrepeat;
    char reserved[2];
    unsigned char yrepeat;
    char reserved2[2];
    short sector;
    char remaining[12];
    short lotag;
    char tail[4];
} CollisionSprite;

typedef struct {
    short wall_start, wall_count;
    long ceiling_z, floor_z;
    char reserved[28];
} CollisionSector;

#pragma pack(pop)

extern CollisionSprite sprite[];
extern CollisionSector sector[];
extern short numsectors, tilesizy[];
extern const char invalid_flatten_sector[];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];
extern void adjust_status_value(short);
#pragma aux adjust_status_value modify exact [eax];

void flatten_sprite(short slot)
{
    CollisionSprite *target = &sprite[slot];
    CollisionSector *where;
    long height, middle;
    long flags;
    if (target->sector < 0 || target->sector >= numsectors)
        report_game_error(invalid_flatten_sector);
    where = &sector[target->sector];
    height = target->yrepeat * tilesizy[target->tile];
    flags = (short)(target->cstat & 0x80);
    height *= 2;
    if (!flags) {
        if (target->z != where->floor_z) {
            middle = (where->floor_z + where->ceiling_z) >> 1;
            target->z = middle;
            if (middle < where->floor_z)
                target->z = where->floor_z;
        }
    } else {
        if (target->z >= where->floor_z - 3072) {
            middle = (where->floor_z + where->ceiling_z) >> 1;
            target->z = middle;
            if (middle < where->floor_z)
                target->z = where->floor_z - height;
        }
    }
}

extern const char invalid_crush_sprite[];
extern short sprite_actor_index[], actor_health[], first_player_sprite;
extern short held_sprite_type, holding_sprite;
extern unsigned char actor_kind[];

extern void start_sequence(short);
#pragma aux start_sequence modify exact [eax];
#pragma aux flatten_sprite modify exact [eax];
void crush_sprite(short slot)
{
    CollisionSprite *target;
    short actor_id;
    int actor;
    if (slot < 0 || (int)slot >= 4096)
        report_game_error(invalid_crush_sprite);
    target = &sprite[slot];
    actor_id = sprite_actor_index[slot];
    actor = (int)actor_id;
    if (actor != -1) {
        actor_health[actor] = 0;
        target->z = sector[target->sector].floor_z;
        target->xrepeat += target->xrepeat;
        actor_kind[actor] = 3;
        target->cstat = 0;
        start_sequence(slot);
    } else if (slot == first_player_sprite) {
        adjust_status_value(50);
    } else if (target->tile == held_sprite_type) {
        holding_sprite = held_sprite_type = 0;
    } else if ((target->lotag & 0xff00) >> 8) {
        start_sequence(slot);
    } else {
        flatten_sprite(slot);
    }
}
