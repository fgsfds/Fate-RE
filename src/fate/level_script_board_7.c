extern short board7_reset, board7_present, board7_previous_present, board7_trigger_sectors[];
extern short board7_sector_head, nextspritesect[], board7_sector_lotag[], board7_key_wall_tile;
typedef struct {
    short sprite, target;
} SpriteEvent;
extern SpriteEvent sprite_events[];
extern short sprite_event_count;
extern unsigned char board7_sprite_tile[];
extern long board7_key_consumed;
extern unsigned char board7_level_flags;
extern void play_sound(int sound, int x, int y, int repeat);
#pragma aux play_sound parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx esi];
extern void activate_sector(int);
#pragma aux activate_sector parm [eax] modify exact [eax];
extern void sequence_remove_sprite(int);
#pragma aux sequence_remove_sprite parm [eax] modify exact [eax ebx];

/* Visit the sector's linked sprite list and latch whether it contained a sprite. */
extern short sprite_index_in_dx(void);
#pragma aux sprite_index_in_dx = value [dx] modify exact [];

extern void set_sprite_in_dx(short);
#pragma aux set_sprite_in_dx = "" parm [dx] modify exact [];
extern void set_index_in_edx(int);
#pragma aux set_index_in_edx = "" parm [edx] modify exact [];
extern int wide_index_in_edx(void);
#pragma aux wide_index_in_edx = "" value [edx] modify exact [];
extern int sprite_in_eax(int);
#pragma aux sprite_in_eax = "" parm [eax] value [eax] modify exact [];
extern int tag_index_in_ebx(int);
#pragma aux tag_index_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern void set_present_in_edi(int);
#pragma aux set_present_in_edi = "" parm [edi] modify exact [];
extern short present_in_di(void);
#pragma aux present_in_di = "" value [di] modify exact [];
extern short previous_in_ax(short);
#pragma aux previous_in_ax = "" parm [ax] value [ax] modify exact [];
extern short current_in_si(short);
#pragma aux current_in_si = "" parm [si] value [si] modify exact [];
extern short absent_in_cx(short);
#pragma aux absent_in_cx = "" parm [cx] value [cx] modify exact [];

extern void finish_sprite_presence(int);
#pragma aux finish_sprite_presence = "" parm [eax] modify exact [edx];

extern int trigger_index_in_eax(void);
#pragma aux trigger_index_in_eax = "" value [eax] modify exact [];
extern unsigned char key_flags_in_ah(unsigned char);
#pragma aux key_flags_in_ah = "" parm [ah] value [ah] modify exact [];
extern int key_in_ebx(int);
#pragma aux key_in_ebx = "" parm [ebx] value [ebx] modify exact [];

extern void finish_clear_tag(void);
#pragma aux finish_clear_tag = "" modify exact [edx];

extern void stage_board7_sound(int sound, int x, int y, int repeat);
#pragma aux stage_board7_sound = "" parm [eax] [edx] [ebx] [ecx] modify exact [];
extern int sound_id_in_eax(void);
#pragma aux sound_id_in_eax = "" value [eax] modify exact [];
extern int value_in_ebx(void);
#pragma aux value_in_ebx = "" value [ebx] modify exact [];
extern int sound_repeat_in_ecx(void);
#pragma aux sound_repeat_in_ecx = "" value [ecx] modify exact [];
extern short presence_in_si(void);
#pragma aux presence_in_si = "" value [si] modify exact [];
extern void stage_activation_tag(int);
#pragma aux stage_activation_tag = "" parm [esi] modify exact [];
extern int sector_in_ecx(int);
#pragma aux sector_in_ecx = "" parm [ecx] value [ecx] modify exact [];

extern void finish_activation_address(int);
#pragma aux finish_activation_address = "" parm [eax] modify exact [edi];

extern void set_event_target(int);
#pragma aux set_event_target = "" parm [ebx] modify exact [];
extern void set_event_sprite(short);
#pragma aux set_event_sprite = "" parm [cx] modify exact [];
extern short event_sprite_in_cx(void);
#pragma aux event_sprite_in_cx = "" value [cx] modify exact [];
extern void set_event_target_low(short);
#pragma aux set_event_target_low = "" parm [bx] modify exact [];
extern short event_in_ax(short);
#pragma aux event_in_ax = "" parm [ax] value [ax] modify exact [];

extern void update_board_7_script(void);
#pragma aux update_board_7_script modify exact [eax];

void update_board_7_script(void)
{
    short previous, absent;
    int sprite, sector, tag_offset, consumed;
    int event, sprite_offset, event_tile;
    unsigned event_sector;
    short target;
    short tag, tile;
    unsigned char flags;

    set_sprite_in_dx(board7_reset);
    if (sprite_index_in_dx())
        goto sprites;
    goto check_clear;
clear:
    /* Each sector record is 40 bytes, addressed from its lotag field. */
    sector = tag_index_in_ebx(board7_trigger_sectors[trigger_index_in_eax()]);
    tag_offset = sprite_in_eax(sector * 5);
    tag = (short)tag_index_in_ebx(0);
    /* Keep the tag setup ahead of the loop index update. */
    finish_clear_tag();
    set_index_in_edx(wide_index_in_edx() + 1);
    board7_sector_lotag[tag_offset * 4] = tag;
check_clear:
    if (sprite_in_eax(sprite_index_in_dx()) <= 15)
        goto clear;

sprites:
    /* The sector is occupied if its sprite list has at least one entry. */
    set_present_in_edi(1);
    absent = absent_in_cx(0);
    set_sprite_in_dx(board7_sector_head);
    board7_present = absent;
    goto check_sprite;
visit:
    sprite = sprite_in_eax(sprite_index_in_dx());
    board7_present = present_in_di();
    /* Store presence before loading the next linked sprite. */
    finish_sprite_presence(sprite);
    set_sprite_in_dx(nextspritesect[sprite]);
check_sprite:
    if (sprite_index_in_dx() >= 0)
        goto visit;

    previous = previous_in_ax(board7_previous_present);
    if (previous == current_in_si(board7_present))
        goto key;
    /* Latch the state change before playing the cue. */
    stage_board7_sound(0x9c, 0, 0, 0);
    board7_previous_present = presence_in_si();
    play_sound(sound_id_in_eax(), wide_index_in_edx(), value_in_ebx(), sound_repeat_in_ecx());
    stage_activation_tag(6);
    set_index_in_edx(0);
    goto check_activation;
activate:
    /* Activate with lotag 6, then clear the tag after the callback. */
    sector = sector_in_ecx(board7_trigger_sectors[value_in_ebx()]);
    tag_offset = sprite_in_eax(sector * 5);
    board7_sector_lotag[tag_offset * 4] = presence_in_si();
    activate_sector(sector);
    sector = tag_index_in_ebx(board7_trigger_sectors[value_in_ebx()]);
    tag_offset = sprite_in_eax(sector * 5);
    /* Finish locating the sector before zeroing the tag. */
    finish_activation_address(tag_offset);
    set_present_in_edi(0);
    finish_clear_tag();
    set_index_in_edx(wide_index_in_edx() + 1);
    board7_sector_lotag[tag_offset * 4] = present_in_di();
check_activation:
    if (tag_index_in_ebx(sprite_index_in_dx()) <= 15)
        goto activate;

key:
    if (board7_key_consumed)
        goto done;
    set_index_in_edx(1);
    goto check_trigger;
scan_trigger:
    /* The event must target the key sector and carry its expected tile. */
    event = sprite_in_eax(sprite_index_in_dx());
    set_event_target(0);
    set_event_sprite(sprite_events[event].sprite);
    target = event_in_ax(sprite_events[event].target);
    set_event_target_low(target);
    if (value_in_ebx() >= 0x8000)
        goto next;
    event_sector = (unsigned)sprite_in_eax((unsigned short)(trigger_index_in_eax() - 0x4000U));
    if (event_sector != 0x5d)
        goto next;
    sprite = sprite_in_eax(event_sprite_in_cx());
    sprite_offset = tag_index_in_ebx(sprite * 44);
    event_tile = tag_index_in_ebx(*(short *)(board7_sprite_tile + sprite_offset));
    if (event_tile != 0x20f)
        goto next;
    sequence_remove_sprite(trigger_index_in_eax());
    consumed = key_in_ebx(1);
    flags = key_flags_in_ah(board7_level_flags);
    board7_key_consumed = consumed;
    flags = key_flags_in_ah(flags | 1);
    tile = (short)key_in_ebx(0x689);
    board7_level_flags = flags;
    board7_key_wall_tile = tile;
next:
    set_index_in_edx(wide_index_in_edx() + 1);
check_trigger:
    if (sprite_index_in_dx() <= sprite_event_count)
        goto scan_trigger;
done:
    return;
}
