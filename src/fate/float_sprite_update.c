#pragma pack(push, 1)
typedef struct {
    char reserved[36];
    short z_velocity;
    char tail[6];
} FloatingSprite;
#pragma pack(pop)
extern FloatingSprite sprite[];
extern short float_sprite_list[], float_sprite_count;
extern long loop_updates;
extern int move_sprite(short sprite, long dx, long dy, long dz,
                       int ceiling_distance, int floor_distance, int clip_type);
#pragma aux move_sprite parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern int deletesprite(short);
#pragma aux deletesprite modify exact [eax];

/* Preserve the original registers for the two count reads and the replacement slot. */
extern short hold_count(short);
#pragma aux hold_count = parm [cx] value [cx] modify exact [];
extern short hold_replacement(short);
#pragma aux hold_replacement = parm [ax] value [ax] modify exact [];
extern int hold_replacement_index(int);
#pragma aux hold_replacement_index = parm [eax] value [eax] modify exact [];

void update_float_sprites(void)
{
    short index;
    for (index = 1; index <= float_sprite_count; ++index) {
        short slot = float_sprite_list[index];
        int outcome = move_sprite(slot, 0, 0,
                                  (sprite[slot].z_velocity * loop_updates) >> 2, 16, 16, 1);

        if ((short)outcome && (outcome & 0xffff) < 0x8000) {
            short count;
            short replacement;
            int read_index;

            deletesprite(slot);
            /* Replace the removed sprite with the final active entry. */
            count = hold_count(*(volatile short *)&float_sprite_count);
            read_index = hold_replacement_index(*(volatile short *)&float_sprite_count);
            count = hold_count(count - 1);
            replacement = hold_replacement(float_sprite_list[read_index]);
            float_sprite_count = count;
            float_sprite_list[index] = replacement;
        }
    }
}
