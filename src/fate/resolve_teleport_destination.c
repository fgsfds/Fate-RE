/* Resolve a teleporter group destination and position the player within its sector. */
extern short teleport_sectors[], teleport_count;
extern short teleport_sector_tags[];
extern short teleport_sector_wall_starts[], teleport_sector_wall_counts[];
extern long teleport_sector_floors[];
extern const char teleport_sound_name[];
extern long teleport_wall_x[], teleport_wall_y[];
extern short teleport_wall_next[], teleport_wall_link[];

extern void update_sector(long, long, short *);
#pragma aux update_sector "updatesector_" parm [eax] [edx] [ebx] modify exact [eax ebx edx];
extern int get_angle(long, long);
#pragma aux get_angle "getangle_" parm [eax] [edx] modify exact [eax edx];
extern int krand(void);
#pragma aux krand modify exact [eax];

/* Preserve the incoming coordinates and the original callee-cleanup frame. */
extern void begin_destination(long *, long *, long *, short *);
#pragma aux begin_destination = \
    "push esi" "push edi" "push ebp" "sub esp,24h" "mov esi,[esp+34h]" \
    "mov [esp+14h],eax" "mov [esp+8],edx" "mov [esp+0ch],ebx" "mov [esp+10h],ecx" \
    "mov eax,[eax]" "mov [esp+4],eax" "mov eax,[edx]" \
    "xor ecx,ecx" "mov [esp],eax" \
    parm [eax] [edx] [ebx] [ecx] modify exact [eax ecx esi];
extern void end_destination(void);
#pragma aux end_destination = \
    "add esp,24h" "pop ebp" "pop edi" "pop esi" modify exact [];
extern short *destination_sector(void);
#pragma aux destination_sector = value [esi] modify exact [];

extern int slot(void);
#pragma aux slot = value [ecx] modify exact [];
extern int slot_in_ecx(int);
#pragma aux slot_in_ecx = parm [ecx] value [ecx] modify exact [];
extern long in_eax(long);
#pragma aux in_eax = parm [eax] value [eax] modify exact [];
extern short in_ax(short);
#pragma aux in_ax = parm [ax] value [ax] modify exact [];
extern short in_dx(short);
#pragma aux in_dx = parm [dx] value [dx] modify exact [];
extern long in_edx(long);
#pragma aux in_edx = parm [edx] value [edx] modify exact [];
extern short in_bx(short);
#pragma aux in_bx = parm [bx] value [bx] modify exact [];
extern long in_ebx(long);
#pragma aux in_ebx = parm [ebx] value [ebx] modify exact [];
extern long in_edi(long);
#pragma aux in_edi = parm [edi] value [edi] modify exact [];
extern long edx_value(void);
#pragma aux edx_value = value [edx] modify exact [];
extern long eax_value(void);
#pragma aux eax_value = value [eax] modify exact [];
extern short dx_value(void);
#pragma aux dx_value = value [dx] modify exact [];
extern long ebx_value(void);
#pragma aux ebx_value = value [ebx] modify exact [];
extern long edi_value(void);
#pragma aux edi_value = value [edi] modify exact [];

extern short wall_limit(void);
#pragma aux wall_limit = "mov eax,[esp+20h]" value [ax] modify exact [eax];
extern void accumulate_wall_y(long);
#pragma aux accumulate_wall_y = "mov ebp,[eax+teleport_wall_y]" "add [esp+18h],ebp" parm [eax] modify exact [];
extern void load_centroid_y_pointer(void);
#pragma aux load_centroid_y_pointer = "mov eax,[esp+8]" modify exact [eax];
extern void load_centroid_x_pointer(void);
#pragma aux load_centroid_x_pointer = "mov eax,[esp+14h]" modify exact [eax];
extern void fetch_centroid_x(long *);
#pragma aux fetch_centroid_x = "mov ebp,[eax]" parm [eax] modify exact [];
extern long centroid_y_in_esi(void);
#pragma aux centroid_y_in_esi = value [esi] modify exact [];
extern long in_esi(long);
#pragma aux in_esi = parm [esi] value [esi] modify exact [];
extern void store_wall_midpoint_y(long);
#pragma aux store_wall_midpoint_y = "mov [esp+18h],edx" parm [edx] modify exact [];
extern long wall_midpoint_ebp(void);
#pragma aux wall_midpoint_ebp = value [ebp] modify exact [];
extern void destination_sound_y(void);
#pragma aux destination_sound_y = "push 0" "mov eax,[esp+0ch]" "push eax" modify exact [eax];
extern void load_source_sound_x(void);
#pragma aux load_source_sound_x = "lea ecx,[esp+0ch]" modify exact [ecx];
extern void load_destination_sound_x(void);
#pragma aux load_destination_sound_x = "mov ecx,[esp+1ch]" modify exact [ecx];
extern void use_positional_sound(const char *, long, long);
#pragma aux use_positional_sound "play_positioned_sound_" parm [eax] [edx] [ebx] modify exact [eax ebx ecx edx];

extern short discard_sector_tag_high_byte(short);
#pragma aux discard_sector_tag_high_byte = "xor ah,ah" parm [ax] value [ax] modify exact [eax];
extern void save_zero_y_sum(void);
#pragma aux save_zero_y_sum = "mov dword ptr [esp+18h],edi" modify exact [];
extern void save_wall_start(long);
#pragma aux save_wall_start = "mov [esp+1ch],edx" parm [edx] modify exact [];
extern void save_wall_end(long);
#pragma aux save_wall_end = "mov [esp+20h],edx" parm [edx] modify exact [];
extern void load_wall_start(void);
#pragma aux load_wall_start = "mov edx,[esp+1ch]" modify exact [edx];
extern long wall_count_in_ebx(void);
#pragma aux wall_count_in_ebx = value [ebx] modify exact [];

extern void load_height_pointer(void);
#pragma aux load_height_pointer = "mov edx,[esp+0ch]" modify exact [edx];

extern short ax_value(void);
#pragma aux ax_value = value [ax] modify exact [];
extern void load_centroid_y_in_edx(void);
#pragma aux load_centroid_y_in_edx = "mov edx,[esp+8]" modify exact [edx];
extern void load_centroid_x_in_edx(void);
#pragma aux load_centroid_x_in_edx = "mov edx,[esp+14h]" modify exact [edx];
extern void load_short_wall_start(void);
#pragma aux load_short_wall_start = "movsx eax,word ptr [esp+1ch]" modify exact [eax];
extern void load_y_sum(void);
#pragma aux load_y_sum = "mov eax,[esp+18h]" modify exact [eax];
/* Divide the signed EDX:EAX sum by the wall count already in EBX. */
extern void divide_wall_sum(void);
#pragma aux divide_wall_sum = "idiv ebx" modify exact [eax edx];

/* Keep the unshifted midpoint sum live through the saved X pointer load. */
extern void keep_x_lookup_order(long);
#pragma aux keep_x_lookup_order = parm [edi] modify exact [];

/* Delay assigning the gain until the pitch is in EDX. */
extern void finish_previous_sound_arg(long);
#pragma aux finish_previous_sound_arg = parm [ebx] modify exact [];
extern void load_teleport_angle(void);
#pragma aux load_teleport_angle = "mov edx,[esp+10h]" "push 0" modify exact [edx];
extern void push_source_sound_y(void);
#pragma aux push_source_sound_y = "lea eax,[esp+4]" "push eax" modify exact [eax];

void resolve_teleport_destination(long *, long *, long *, short *, short *);
#pragma aux resolve_teleport_destination parm routine [eax] [edx] [ebx] [ecx] \
    modify exact [eax ebx ecx edx esi edi];

void resolve_teleport_destination(long *x, long *y, long *z, short *angle, short *sector)
{
    short table_sector, input_sector, wall_end;
    long count, current_tag;
    unsigned wall_offset;
    long delta_x;

    begin_destination(x, y, z, angle);
    /* Select the next teleporter with the same low-byte sector tag. */
    goto check_destination;
find_destination:
    table_sector = in_ax(teleport_sectors[slot()]);
    input_sector = in_dx(*destination_sector());
    if (table_sector == input_sector) {
        count = in_edx(input_sector);
        table_sector = in_ax(teleport_sector_tags[(in_eax(count) * 4 + count) * 4]);
        current_tag = in_edi(discard_sector_tag_high_byte(table_sector));
        do {
            count = in_eax(teleport_count);
            slot_in_ecx(slot() + 1);
            if (slot() >= count)
                slot_in_ecx(0);
            in_edx(slot() * (long)sizeof(teleport_sectors[0]));
            in_ebx(*(const short *)((const char *)teleport_sectors + edx_value()));
            in_ax(teleport_sector_tags[(in_eax(ebx_value()) * 4 + ebx_value()) * 4]);
        } while (in_eax(discard_sector_tag_high_byte(ax_value())) != edi_value());
        *destination_sector() = in_ax(*(short *)((char *)teleport_sectors + edx_value()));
        goto destination_found;
    }
    slot_in_ecx(slot() + 1);
check_destination:
    count = in_eax(teleport_count);
    if (slot() < count)
        goto find_destination;
destination_found:
    /* Average the wall vertices and remember the last linked wall. */
    count = in_edx(*destination_sector());
    wall_offset = in_eax(in_eax(count) * 4 + count);
    in_edi(0);
    in_dx(teleport_sector_wall_starts[wall_offset * 4]);
    in_bx(teleport_sector_wall_counts[eax_value() * 4]);
    save_wall_start(edx_value());
    in_edx(edx_value() + wall_count_in_ebx());
    save_zero_y_sum();
    save_wall_end(edx_value());
    load_wall_start();
    goto check_walls;
add_wall:
    in_ebx(dx_value());
    wall_offset = in_eax(ebx_value() * 32);
    in_edi(edi_value() + *(const long *)((const char *)teleport_wall_x + wall_offset));
    accumulate_wall_y(eax_value());
    if (*(const short *)((const char *)teleport_wall_link + eax_value()) >= 0)
        slot_in_ecx(ebx_value());
    in_edx(edx_value() + 1);
check_walls:
    wall_end = wall_limit();
    if (dx_value() < wall_end)
        goto add_wall;
    /* Divide each accumulated coordinate by the destination wall count. */
    in_ebx(ax_value());
    in_edx(edi_value());
    load_short_wall_start();
    in_edx(edx_value() >> 31);
    in_ebx(ebx_value() - eax_value());
    in_eax(edi_value());
    divide_wall_sum();
    load_centroid_x_in_edx();
    *(long *)edx_value() = eax_value();

    load_y_sum();
    in_eax(eax_value() / ebx_value());
    load_centroid_y_in_edx();
    *(long *)edx_value() = eax_value();
    /* The destination height is one player offset above the sector floor. */
    count = in_edx(*destination_sector());
    delta_x = in_eax(teleport_sector_floors[(in_eax(count) * 4 + count) * 2]);
    load_height_pointer();
    *(long *)edx_value() = delta_x - 8192;
    load_centroid_y_in_edx();
    load_centroid_x_pointer();
    in_ebx((long)destination_sector());
    in_edx(*(long *)edx_value());
    in_eax(*(long *)eax_value());
    slot_in_ecx(slot() * 32);
    update_sector(eax_value(), edx_value(), (short *)ebx_value());
    /* Aim at the linked wall midpoint, then play sounds at both positions. */
    in_eax(*(const short *)((const char *)teleport_wall_next + slot()));
    in_edi(*(const long *)((const char *)teleport_wall_x + slot()));
    in_eax(eax_value() * 32);
    in_edx(*(const long *)((const char *)teleport_wall_y + slot()));
    in_ebx(*(const long *)((const char *)teleport_wall_x + eax_value()));
    slot_in_ecx(*(const long *)((const char *)teleport_wall_y + eax_value()));
    load_centroid_y_pointer();
    in_edx(edx_value() + slot());
    in_edi(edi_value() + ebx_value());
    in_edx(edx_value() >> 1);
    in_esi(*(long *)eax_value());
    load_centroid_x_pointer();
    keep_x_lookup_order(edi_value());
    in_edi(edi_value() >> 1);
    store_wall_midpoint_y(edx_value());
    fetch_centroid_x((long *)eax_value());
    in_eax(edi_value());
    in_edx(edx_value() - centroid_y_in_esi());
    delta_x = in_eax(eax_value() - wall_midpoint_ebp());
    table_sector = (short)get_angle(delta_x, edx_value());
    load_teleport_angle();
    *(short *)edx_value() = in_ax(table_sector);
    push_source_sound_y();
    in_eax(krand() & 127);
    load_source_sound_x();
    in_edx(eax_value() + 0xbc0);
    finish_previous_sound_arg(ebx_value());
    in_ebx(0xc0);
    use_positional_sound(teleport_sound_name, edx_value(), ebx_value());
    destination_sound_y();
    in_eax(krand() & 127);
    load_destination_sound_x();
    in_edx(eax_value() + 0xfc0);
    finish_previous_sound_arg(ebx_value());
    in_ebx(0x100);
    use_positional_sound(teleport_sound_name, edx_value(), ebx_value());
    end_destination();
}
