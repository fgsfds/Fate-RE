extern short activation_sprite_index[], activation_sprite_count, advance_clock;
extern unsigned char activation_counter[];
extern long proximity_player_x, proximity_player_y, proximity_player_z;
extern short proximity_player_sector;
extern long proximity_sprite_x[], proximity_sprite_y[], proximity_sprite_z[];
extern short proximity_sprite_tile[], proximity_sprite_sector[];
extern long absolute_long(long);
#pragma aux absolute_long parm [eax] modify exact [eax];
extern int random_value(void);
#pragma aux random_value modify exact [eax];

/* The activation list is one-based and uses DI for the current list slot. */
extern void init_activation_list(void);
#pragma aux init_activation_list = "push ebx" "push ecx" "push edx" "push esi" "push edi" \
    "push ebp" modify exact [edi];
extern short list_slot(void);
#pragma aux list_slot = value [di] modify exact [];
extern unsigned slot_in_esi(void);
#pragma aux slot_in_esi = value [esi] modify exact [];
extern void release_activation_registers(void);
#pragma aux release_activation_registers = "pop ebp" "pop edi" "pop esi" "pop edx" \
    "pop ecx" "pop ebx" modify exact [];

/* Ask the engine about clear sight from the sprite center to the player. */

extern int sight_saved_ebp(void);
#pragma aux sight_saved_ebp = "" value [ebp] modify exact [];
extern short do_proximity_sight(void);
#pragma aux do_proximity_sight "cansee_" modify exact [eax ebx ecx edx];

/* The final cansee call consumes the four staged stack arguments. */
extern void pass_sight_stack(long);
#pragma aux pass_sight_stack = "" parm routine [] modify exact [];
extern int sight_saved_ebx(void);
#pragma aux sight_saved_ebx = "" value [ebx] modify exact [];
extern void push_sight_height(void);
#pragma aux push_sight_height = "mov ebp,[proximity_player_z]" "push ebp" modify exact [];
extern void load_source_x_in_ebp(void);
#pragma aux load_source_x_in_ebp = "mov ebp,[edx+proximity_sprite_x]" modify exact [];

extern int prox_eax(int);
#pragma aux prox_eax = "" parm [eax] value [eax] modify exact [];
extern int prox_ebx(int);
#pragma aux prox_ebx = "" parm [ebx] value [ebx] modify exact [];
extern void prox_ecx(int);
#pragma aux prox_ecx = "" parm [ecx] modify exact [];
extern void prox_set_edx(int);
#pragma aux prox_set_edx = "" parm [edx] modify exact [];
extern void prox_set_edi(int);
#pragma aux prox_set_edi = "" parm [edi] modify exact [];
extern void prox_set_esi(int);
#pragma aux prox_set_esi = "" parm [esi] modify exact [];
extern int prox_edx(void);
#pragma aux prox_edx = "" value [edx] modify exact [];
extern int prox_edi(void);
#pragma aux prox_edi = "" value [edi] modify exact [];
extern short prox_in_ax(short);
#pragma aux prox_in_ax = "" parm [ax] value [ax] modify exact [];
extern short prox_ax(void);
#pragma aux prox_ax = "" value [ax] modify exact [];
extern void prox_set_al(unsigned char);
#pragma aux prox_set_al = "" parm [al] modify exact [];
extern void prox_set_ah(unsigned char);
#pragma aux prox_set_ah = "" parm [ah] modify exact [];
extern int prox_result(void);
#pragma aux prox_result = "" value [eax] modify exact [];
extern void prox_clear_eax(int);
#pragma aux prox_clear_eax = "" parm [eax] modify exact [eax];
extern unsigned char prox_bl(unsigned char);
#pragma aux prox_bl = "" parm [bl] value [bl] modify exact [];
extern long prox_fixed_floor(long);
#pragma aux prox_fixed_floor = "" parm [ecx] value [ecx] modify exact [];

extern void counter_inc_finished(int);
#pragma aux counter_inc_finished = "" parm [edx] modify exact [eax];

extern void activate_proximity_sprite(int sprite, long x, long y, long height,
                                      int radius, int kind);
#pragma aux activate_proximity_sprite "activate_sprite_at_player_" parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx edx];
extern long prox_saved_height(void);
#pragma aux prox_saved_height = "" value [ecx] modify exact [];
extern unsigned char prox_al(void);
#pragma aux prox_al = "" value [al] modify exact [];

extern void update_proximity_sprites(void);
#pragma aux update_proximity_sprites modify exact [eax ebx ecx edx esi edi];

void update_proximity_sprites(void)
{
    int tile, height;
    short sprite;

    init_activation_list();
    prox_set_edi(1);
    goto count;
entry:
    prox_set_esi(list_slot());
    sprite = prox_in_ax(activation_sprite_index[slot_in_esi()]);
    prox_set_edx(prox_eax(sprite) * 44);
    tile = prox_ebx(*(short *)((char *)proximity_sprite_tile + prox_edx()));
    if (tile < 0x3a6 || tile > 0x3a9)
        goto advance;
    if (activation_counter[slot_in_esi()] <= 0)
        goto check_range;
    /* Pending lower tiles trigger once. Upper tiles keep their counter until it expires. */
    height = prox_fixed_floor(proximity_player_z);
    prox_ecx(height + 2000);
    if (tile >= 0x3a8)
        goto upper_tile;
    activate_proximity_sprite(prox_result(), proximity_player_x, proximity_player_y, prox_saved_height(), 512, 5);
    prox_set_al(0);
    activation_counter[slot_in_esi()] = prox_al();
    goto tick;
upper_tile:
    activate_proximity_sprite(prox_result(), proximity_player_x, proximity_player_y, prox_saved_height(), 512, 4);
tick:
    if (!advance_clock)
        goto advance;
    prox_set_edx(list_slot());
    ++activation_counter[prox_edx()];
    /* Zero-extend the updated counter after incrementing its byte in memory. */
    counter_inc_finished(prox_edx());
    prox_clear_eax(0);
    prox_set_al(activation_counter[prox_edx()]);
    if (prox_result() <= 3)
        goto advance;
    activation_counter[prox_edx()] = prox_bl(0);
    goto advance;

check_range:
    /* Prime idle tiles only after the distance, visibility, and chance checks. */
    if (absolute_long(prox_eax(proximity_player_x) -
                      *(long *)((char *)proximity_sprite_x + prox_edx())) >= 8192 ||
        absolute_long(prox_eax(proximity_player_y) -
                      *(long *)((char *)proximity_sprite_y + prox_edx())) >= 8192)
        goto advance;
    /* Pass the four destination arguments before loading the source coordinates. */
    prox_eax(proximity_player_sector);
    pass_sight_stack(prox_result());
    push_sight_height();
    prox_eax(proximity_player_y);
    prox_ebx(proximity_player_x);
    pass_sight_stack(prox_result());
    prox_ecx(*(short *)((char *)proximity_sprite_sector + prox_edx()));
    load_source_x_in_ebp();
    pass_sight_stack(sight_saved_ebx());
    prox_eax(*(long *)((char *)proximity_sprite_y + prox_edx()));
    prox_ebx(*(long *)((char *)proximity_sprite_z + prox_edx()));
    prox_set_edx(prox_result());
    prox_eax(sight_saved_ebp());
    if (prox_eax(do_proximity_sight()) != 1)
        goto advance;
    random_value();
    prox_set_ah(0);
    if (prox_eax(prox_ax()) >= 10)
        goto advance;
    activation_counter[slot_in_esi()] = 1;
advance:
    prox_set_edi(prox_edi() + 1);
count:
    if (list_slot() <= activation_sprite_count)
        goto entry;
    release_activation_registers();
}
