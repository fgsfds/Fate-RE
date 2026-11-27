#pragma pack(push, 1)
typedef struct {
    char prefix[36];
    short hit_tag;
    char tail[2];
} HitSector;
typedef struct {
    char prefix[40];
    short hit_tag;
    char tail[2];
} HitSprite;
#pragma pack(pop)

extern HitSector hit_sectors[];
extern HitSprite hit_sprites[];
extern short numsectors, hit_sprite_list_head, next_sprite_stat[];
extern signed char current_board;

extern int classify_sector_hit(int);
#pragma aux classify_sector_hit modify exact [eax];
extern void trigger_board_hit(int, int);
#pragma aux trigger_board_hit "trigger_tagged_crushers_" modify exact [eax edx];
extern void activate_sector_for_hit(int);
#pragma aux activate_sector_for_hit "activate_sector_" modify exact [eax];
extern void start_sequence_for_hit(int);
#pragma aux start_sequence_for_hit "start_sequence_" modify exact [eax];

/* Preserve the original register assignments across the dispatch calls. */
extern int keep_hit_sector(int);
#pragma aux keep_hit_sector = "" parm [edx] value [edx] modify exact [];
extern int keep_next_hit_sprite(int);
#pragma aux keep_next_hit_sprite = "" parm [esi] value [esi] modify exact [];

extern int keep_dispatch_tag(int);
#pragma aux keep_dispatch_tag = "" parm [eax] value [eax] modify exact [];

void dispatch_hit_event(short tag)
{
    int index;

    for (index = 0; index < numsectors; ++index) {
        if (tag == hit_sectors[index].hit_tag) {
            int sector = keep_hit_sector((short)index);
            if (classify_sector_hit(sector) == 1)
                trigger_board_hit(current_board, sector);
            else
                activate_sector_for_hit(index);
        }
    }

    index = hit_sprite_list_head;
    goto test_sprite;
    do {
        /* Compare the low byte of the sprite hit tag. */
        int hit_tag = (short)(hit_sprites[index].hit_tag & 0xff);
        int wanted_tag = keep_dispatch_tag(tag);
        int next = keep_next_hit_sprite(next_sprite_stat[index]);
        if (hit_tag == wanted_tag)
            start_sequence_for_hit(index);
        index = next;
    test_sprite:
        ;
    } while (index >= 0);
}
