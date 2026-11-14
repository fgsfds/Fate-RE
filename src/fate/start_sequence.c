/* Candidate for 0x11fdd; unmatched until the strict verifier passes. */
#pragma pack(push, 1)
typedef struct {
    long x, y, z;
    short cstat, picnum;
    signed char shade;
    unsigned char pal, clipdist, filler, xrepeat, yrepeat;
    signed char xoffset, yoffset;
    short sectnum, statnum, ang, owner, xvel, yvel, zvel, lotag, hitag, extra;
} StartSequenceSprite;
typedef struct { long x, y, z; } SequencePosition;
typedef struct { char before_floor[8]; long floorz; char rest[28]; } SequenceSector;
#pragma pack(pop)
extern StartSequenceSprite start_sequence_sprites[];
extern SequenceSector start_sequence_sectors[];
extern short start_sequence_rows[][60], start_sequence_count, start_sequence_list[];
extern short start_sequence_tile_heights[];
extern char start_sequence_error_buffer[], start_sequence_overflow_text[];
extern int sequence_random(void);
extern void sequence_sound(short, long, long, short);
extern int format_sequence_error(char *, const char *, ...);
extern void report_sequence_error(const char *);
extern short sequence_spawn(short, const SequencePosition *, short);
extern void sequence_move(short, long, long, long, long, long, unsigned char);
extern void sequence_append_movement(short);

void start_sequence(short sprite)
{
    short sequence, i, type, spawned, sector, xsign, ysign, speed, spread;
    long count;
    SequencePosition position;
    sequence = (start_sequence_sprites[sprite].lotag & 0xff00) >> 8;
    if (!sequence) return;
    for (i = 1; i <= start_sequence_count; i++)
        if (start_sequence_list[i] == sprite) return;
    if (start_sequence_rows[sequence][52])
        sequence_sound(start_sequence_rows[sequence][52 + (sequence_random() & 7)],
            start_sequence_sprites[sprite].x, start_sequence_sprites[sprite].y, 2);
    count = ++start_sequence_count;
    if (count > 511) {
        format_sequence_error(start_sequence_error_buffer, start_sequence_overflow_text);
        report_sequence_error(start_sequence_error_buffer);
    }
    start_sequence_list[start_sequence_count] = sprite;
    if (start_sequence_rows[sequence][0] > 0) {
        start_sequence_sprites[sprite].picnum = start_sequence_rows[sequence][0];
        if (start_sequence_sprites[sprite].picnum == 807 ||
            start_sequence_sprites[sprite].picnum == 803 ||
            start_sequence_sprites[sprite].picnum == 827 ||
            start_sequence_sprites[sprite].picnum == 910 ||
            start_sequence_sprites[sprite].picnum == 771 ||
            start_sequence_sprites[sprite].picnum == 866) {
            start_sequence_sprites[sprite].shade = -64;
            if (start_sequence_sprites[sprite].owner == 1) {
                start_sequence_sprites[sprite].xrepeat *= 2;
                start_sequence_sprites[sprite].yrepeat *= 2;
            }
            if (start_sequence_sprites[sprite].extra & 0x2000) {
                start_sequence_sprites[sprite].cstat &= ~128;
                start_sequence_sprites[sprite].z = start_sequence_sectors[start_sequence_sprites[sprite].sectnum].floorz;
            }
        } else if (start_sequence_sprites[sprite].cstat & 128) {
            start_sequence_sprites[sprite].cstat &= ~128;
            start_sequence_sprites[sprite].z = start_sequence_sectors[start_sequence_sprites[sprite].sectnum].floorz;
        }
    }
    for (i = 4; i <= 51; i += 4) {
        type = start_sequence_rows[sequence][i];
        if (!type) return;
        xsign = (sequence_random() & 1) ? -1 : 1;
        ysign = (sequence_random() & 1) ? -1 : 1;
        position.x = start_sequence_sprites[sprite].x;
        position.y = start_sequence_sprites[sprite].y;
        position.z = start_sequence_sprites[sprite].z;
        sector = start_sequence_sprites[sprite].sectnum;
        spawned = sequence_spawn(type, &position, sector);
        speed = start_sequence_rows[sequence][i + 2];
        if (!speed) {
            long height;
            if (start_sequence_sprites[spawned].cstat & 128)
                height = start_sequence_tile_heights[start_sequence_sprites[spawned].picnum] * start_sequence_sprites[spawned].yrepeat * 2;
            else height = 0;
            start_sequence_sprites[spawned].z = start_sequence_sectors[sector].floorz - height;
        } else {
            spread = start_sequence_rows[sequence][i + 1];
            position.x = ((sequence_random() & 32767) * xsign * spread) << 6;
            position.y = ((sequence_random() & 32767) * ysign * spread) << 6;
            position.z = 0;
            sequence_move(spawned, position.x, position.y, 0, 1024, 1024, 0);
            start_sequence_sprites[spawned].xvel = (sequence_random() & 255) * xsign * speed;
            start_sequence_sprites[spawned].yvel = (sequence_random() & 255) * ysign * speed;
            start_sequence_sprites[spawned].zvel = -(sequence_random() & 511) * speed;
            if (start_sequence_rows[sequence][i + 3] == 1)
                start_sequence_sprites[spawned].extra |= 0x8000;
            sequence_append_movement(spawned);
        }
    }
}
