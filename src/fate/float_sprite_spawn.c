#pragma pack(push, 1)
typedef struct {
    long x, y, z;
    char unknown[2];
    short tile;
    char unknown2[5];
    unsigned char yrepeat;
    char unknown3[14];
    short z_velocity;
    char unknown4[6];
} FloatingSprite;
typedef struct {
    char unknown[8];
    long floor_z;
    char unknown2[28];
} FloatingSector;
typedef struct { long x, y, z; } Position;
#pragma pack(pop)
extern FloatingSprite sprite[];
extern FloatingSector sector[];
extern short float_sprite_list[], float_sprite_count, tilesizy[];
extern char error_buffer[];
extern const char float_sprite_overflow[];
extern int random_value(void);
#pragma aux random_value modify exact [eax];
extern void updatesector(long, long, short *);
#pragma aux updatesector modify exact [eax];
extern short spawn_sprite_at_position(short, Position *, short);
#pragma aux spawn_sprite_at_position modify exact [eax];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];
extern int format_game_error(char *, const char *, ...);
#pragma aux format_game_error "sprintf_" parm caller [] modify exact [eax];

void spawn_float_sprite(short type, short shift_x, short shift_y, const Position *origin, short velocity);
#pragma aux spawn_float_sprite parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
void spawn_float_sprite(short type, short shift_x, short shift_y, const Position *origin, short velocity)
{
    Position point;
    short where, slot;
    long count;
    point.x = origin->x + ((short)(random_value() * 2) >> shift_x);
    point.y = origin->y + ((short)(random_value() * 2) >> shift_y);
    updatesector(point.x, point.y, &where);
    if (where < 0)
        return;
    point.z = sector[where].floor_z - 1000;
    slot = spawn_sprite_at_position(type, &point, where);
    sprite[slot].z = sector[where].floor_z - (tilesizy[sprite[slot].tile] * sprite[slot].yrepeat) * 2 - 1000;
    sprite[slot].z_velocity = velocity;
    count = ++float_sprite_count;
    if (count > 511) {
        format_game_error(error_buffer, float_sprite_overflow);
        report_game_error(error_buffer);
    }
    float_sprite_list[float_sprite_count] = slot;
}
