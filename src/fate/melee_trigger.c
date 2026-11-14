/* Reconstructed melee sequence trigger; the compiler emits its preceding jump table. */
extern short melee_enabled, melee_angle, melee_horizon, melee_sector;
extern short melee_mode, melee_sound_flag, melee_sprite_mapping[], melee_sines[];
extern long melee_x, melee_y, melee_z;
extern void melee_hitscan(long,long,long,short,long,long,long,short*,short*,short*,long*,long*,long*);
extern long melee_distance(long);
extern int melee_random(void);
extern void melee_sound(long,long,long,long);
extern void melee_start_sequence(short);

void melee_trigger(void)
{
    long hitx, hity, hitz, dx, dy;
    short hitsprite, hitsect, hitwall;
    short vx, vy, vz;
    if (!melee_enabled) return;
    vx = melee_sines[(melee_angle + 512) & 2047] >> 5;
    vy = melee_sines[melee_angle & 2047] >> 5;
    vz = (100 - melee_horizon) << 6;
    melee_hitscan(melee_x, melee_y, melee_z + 2048, melee_sector,
        vx, vy, vz, &hitsect, &hitwall, &hitsprite, &hitx, &hity, &hitz);
    dx = hitx - melee_x;
    dy = hity - melee_y;
    if (melee_distance(dx*dx + dy*dy) >= 350) return;
    switch ((short)((melee_mode >> 13) & 7)) {
    case 0:
        melee_sound(23 + melee_random() % 4, 0, 0, 0);
        if (melee_random() % 2)
            melee_sound(15 + melee_random() % 2, 0, 0, 0);
        melee_sound_flag = 1;
        break;
    case 1:
        melee_sound(23 + melee_random() % 4, 0, 0, 0);
        melee_sound_flag = 1;
        break;
    case 2: case 3: case 4: case 5: case 6: case 7: break;
    }
    if ((melee_random() & 3) == 1 && hitsprite != -1 && melee_sprite_mapping[hitsprite] == -1)
        melee_start_sequence(hitsprite);
}
