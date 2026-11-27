extern short player_sector, player_angle;
extern long player_x, player_y, player_z, player_horizon;
extern long presentation_height, presentation_width;
extern volatile long totalclock;

extern long dispatch_ticks(long);
#pragma aux dispatch_ticks modify exact [eax];
extern void drawrooms(long, long, long, short, long, short);
#pragma aux drawrooms modify exact [eax ebx ecx edx];
extern void drawmasks(void), nextpage(void);
#pragma aux drawmasks modify exact [eax];
#pragma aux nextpage modify exact [eax];
extern void rotatesprite(long, long, long, short, short, signed char, unsigned char, unsigned char, long, long, long, long);
#pragma aux rotatesprite modify exact [eax ebx ecx edx];

typedef struct {
    short first_wall, wall_count;
    long ceiling_z, floor_z;
    unsigned char rest[28];
} IntroSector;

extern IntroSector sector[];
extern long intro_visibility;
extern int classify_sector_hit(short);
#pragma aux classify_sector_hit modify exact [eax];
/* The banner cleanup releases one stack word and the six saved registers. */
extern void status_banner_cleanup(void);
#pragma aux status_banner_cleanup aborts modify exact [];

void draw_animated_intro(void)
{
    long zoom = 256;
    long previous_tick = totalclock;
    long deadline = (long)((unsigned long)previous_tick + (unsigned long)dispatch_ticks(4));
    volatile long saved_visibility = intro_visibility;

    if (!classify_sector_hit(player_sector))
        player_z = sector[player_sector].floor_z - 1024;

    while (deadline > totalclock) {
        if (zoom < 65536) {
            zoom = (long)((unsigned long)zoom + (((unsigned long)totalclock - (unsigned long)previous_tick) << 8));
            previous_tick = totalclock;
            if (zoom > 65536)
                zoom = 65536;
        }
        intro_visibility += 32;
        if (!classify_sector_hit(player_sector))
            player_horizon += 6;
        if (player_horizon > 200)
            player_horizon = 200;
        drawrooms(player_x, player_y, player_z, player_angle, player_horizon, player_sector);
        drawmasks();
        rotatesprite(160 << 16, 100 << 16, zoom, 0, 0x839, 0, 0, 3,
                     0, 0, presentation_width - 1, presentation_height - 1);
        nextpage();
    }
    intro_visibility = saved_visibility;
    status_banner_cleanup();
}
