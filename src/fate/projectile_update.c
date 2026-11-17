/* Move each active projectile and process its collision result. */
extern short projectile_count, projectile_list[], projectile_player_sprite;
extern short projectile_sector[], projectile_owner[], projectile_lotag[], projectile_hitag[];
extern short projectile_xvel[], projectile_yvel[], projectile_zvel[];
extern long projectile_x[], projectile_y[], projectile_z[], projectile_ticks;
extern long projectile_player_x, projectile_player_y, projectile_player_z;
extern long projectile_player_hit_x, projectile_player_hit_y;
extern short projectile_player_hit_timer, projectile_selected_weapon, projectile_close_hit_tile;
extern unsigned char projectile_player_mode, projectile_extra_high[];

extern int move_updated_projectile(void);
#pragma aux move_updated_projectile "move_sprite_" modify exact [eax ecx edx];
extern long ksqrt(long);
#pragma aux ksqrt parm [eax] modify exact [eax];
extern void adjust_status_value(int);
#pragma aux adjust_status_value parm [eax] modify exact [eax];
extern void change_projectile_sector(int, int);
#pragma aux change_projectile_sector "changespritesect_" parm [eax] [edx] modify exact [eax edx];
extern void dispatch_hit_event(int);
#pragma aux dispatch_hit_event parm [eax] modify exact [eax];
extern void apply_projectile_hit(int, int, int);
#pragma aux apply_projectile_hit parm [eax] [edx] [ecx] modify exact [eax edx];
extern void start_sequence(int);
#pragma aux start_sequence parm [eax] modify exact [eax];
extern void remove_updated_projectile(int);
#pragma aux remove_updated_projectile "sequence_remove_sprite_" parm [eax] modify exact [eax];

/* Retain the original movement scratch slots and register saves. */
extern void begin_projectile_update(void);
#pragma aux begin_projectile_update = \
    "push ebx" "push ecx" "push edx" "push esi" "push edi" "push ebp" \
    "sub esp,14h" "mov dword ptr [esp+10h],1" modify exact [];
extern void end_projectile_update(void);
#pragma aux end_projectile_update = \
    "add esp,14h" "pop ebp" "pop edi" "pop esi" "pop edx" "pop ecx" "pop ebx" modify exact [];
extern void save_previous_projectile_x(long);
#pragma aux save_previous_projectile_x = "mov [esp+8],edx" parm [edx] modify exact [];
extern void save_previous_projectile_y(long);
#pragma aux save_previous_projectile_y = "mov [esp+4],edx" parm [edx] modify exact [];
extern void save_previous_projectile_sector(void);
#pragma aux save_previous_projectile_sector = "mov [esp+0ch],edx" modify exact [];
extern void prepare_projectile_clip(long,long,long);
#pragma aux prepare_projectile_clip = "push 1" "push 10h" "push 10h" parm [edx] [ebx] [ecx] modify exact [];
extern void capture_previous_projectile_z(void);
#pragma aux capture_previous_projectile_z = "mov ebp,[esi+projectile_z]" modify exact [];
extern void save_projectile_delta_square(long);
#pragma aux save_projectile_delta_square = "mov [esp],eax" parm [eax] modify exact [];
extern long complete_projectile_distance_square(long);
#pragma aux complete_projectile_distance_square = "add eax,[esp]" parm [eax] value [eax] modify exact [eax];
extern short projectile_list_slot(void);
#pragma aux projectile_list_slot = "mov eax,[esp+10h]" value [ax] modify exact [eax];
extern void load_projectile_slot_in_edx(void);
#pragma aux load_projectile_slot_in_edx = "movsx edx,word ptr [esp+10h]" modify exact [edx];
extern void advance_projectile_slot(void);
#pragma aux advance_projectile_slot = "inc dword ptr [esp+10h]" modify exact [];
extern void load_midpoint_previous_x(void);
#pragma aux load_midpoint_previous_x = "mov eax,[esp+8]" modify exact [eax];
extern void load_midpoint_previous_y(void);
#pragma aux load_midpoint_previous_y = "mov eax,[esp+4]" modify exact [eax];
extern void load_midpoint_sector(void);
#pragma aux load_midpoint_sector = "movsx edx,word ptr [esp+0ch]" modify exact [edx];
extern void load_midpoint_current_z(void);
#pragma aux load_midpoint_current_z = "mov ebp,[ebx+projectile_z]" modify exact [];
extern void subtract_midpoint_z_delta(long);
#pragma aux subtract_midpoint_z_delta = "sub ebp,eax" parm [eax] modify exact [];
extern unsigned short hitag_low_byte(void);
#pragma aux hitag_low_byte = "xor ah,ah" "cwde" value [ax] modify exact [eax];
extern void keep_low_collision_lotag(void);
#pragma aux keep_low_collision_lotag = "xor dh,dh" modify exact [edx];

/* Zero-byte bindings preserve the original Watcom register assignments. */
extern long in_eax(long);
#pragma aux in_eax = parm [eax] value [eax] modify exact [];
extern long in_ebx(long);
#pragma aux in_ebx = parm [ebx] value [ebx] modify exact [];
extern long in_ecx(long);
#pragma aux in_ecx = parm [ecx] value [ecx] modify exact [];
extern long in_edx(long);
#pragma aux in_edx = parm [edx] value [edx] modify exact [];
extern long in_esi(long);
#pragma aux in_esi = parm [esi] value [esi] modify exact [];
extern long in_edi(long);
#pragma aux in_edi = parm [edi] value [edi] modify exact [];
extern short in_ax(short);
#pragma aux in_ax = parm [ax] value [ax] modify exact [];
extern short in_di(short);
#pragma aux in_di = parm [di] value [di] modify exact [];
extern short in_dx(short);
#pragma aux in_dx = parm [dx] value [dx] modify exact [];
extern unsigned char in_al(unsigned char);
#pragma aux in_al = parm [al] value [al] modify exact [];
extern long eax_value(void);
#pragma aux eax_value = value [eax] modify exact [];
extern long ebx_value(void);
#pragma aux ebx_value = value [ebx] modify exact [];
extern long ecx_value(void);
#pragma aux ecx_value = value [ecx] modify exact [];
extern long edx_value(void);
#pragma aux edx_value = value [edx] modify exact [];
extern long esi_value(void);
#pragma aux esi_value = value [esi] modify exact [];
extern long edi_value(void);
#pragma aux edi_value = value [edi] modify exact [];
extern long ebp_value(void);
#pragma aux ebp_value = value [ebp] modify exact [];
extern short bx_value(void);
#pragma aux bx_value = value [bx] modify exact [];
extern short ax_value(void);
#pragma aux ax_value = value [ax] modify exact [];
extern short cx_value(void);
#pragma aux cx_value = value [cx] modify exact [];
extern short dx_value(void);
#pragma aux dx_value = value [dx] modify exact [];
extern short di_value(void);
#pragma aux di_value = value [di] modify exact [];
extern short si_value(void);
#pragma aux si_value = value [si] modify exact [];

/* Keep the list slot store before decrementing the global count. */
extern void keep_projectile_list_publication_order(void);
#pragma aux keep_projectile_list_publication_order = "" modify exact [];
extern void copy_projectile_collision_number(void);
#pragma aux copy_projectile_collision_number = "mov ebx,ecx" modify exact [ebx];

void update_projectiles(void);
#pragma aux update_projectiles modify exact [eax ebx ecx edx esi edi];

void update_projectiles(void)
{
    long dx, dy, squared, distance;
    short slot;

    begin_projectile_update();
    goto check_count;
step:
    in_edi(ax_value());
    in_di(projectile_list[edi_value()]);
    in_eax(di_value());
    in_esi(eax_value() * 44);
    save_previous_projectile_x(in_edx(*(const long *)((const char *)projectile_x + esi_value())));
    save_previous_projectile_y(in_edx(*(const long *)((const char *)projectile_y + esi_value())));
    in_dx(*(const short *)((const char *)projectile_sector + esi_value()));
    in_ebx(projectile_ticks);
    save_previous_projectile_sector();
    in_edx(*(const short *)((const char *)projectile_xvel + esi_value()));
    in_edx(edx_value() * ebx_value());
    in_ecx(projectile_ticks);
    in_ebx(*(const short *)((const char *)projectile_yvel + esi_value()));
    in_ebx(ebx_value() * ecx_value());
    in_ecx(*(const short *)((const char *)projectile_zvel + esi_value()));
    in_ecx(ecx_value() * projectile_ticks);
    prepare_projectile_clip(edx_value(), ebx_value(), ecx_value());
    in_edx(edx_value() * 4096);
    in_ebx(ebx_value() * 4096);
    in_ecx(ecx_value() >> 2);
    capture_previous_projectile_z();
    in_ecx(move_updated_projectile());
    if (!ax_value())
        goto advance;
    in_dx(*(const short *)((const char *)projectile_owner + esi_value()));
    if (in_edx(dx_value()) != 1)
        goto remove_from_list;
    in_eax(eax_value() & 0xffffL);
    in_edx(projectile_player_sprite);
    if (in_eax(eax_value() - 0xc000L) == edx_value())
        goto advance;

    /* The player-owned projectile can cause a close-range recoil effect. */
    in_edx(projectile_player_x);
    in_eax(*(const long *)((const char *)projectile_x + esi_value()) - edx_value());
    in_ebx(projectile_player_y);
    dx = in_edx(eax_value());
    in_eax(*(const long *)((const char *)projectile_y + esi_value()) - ebx_value());
    dy = in_ebx(eax_value());
    in_eax(dx);
    save_projectile_delta_square(in_eax(eax_value() * dx));
    in_eax(dy);
    squared = complete_projectile_distance_square(in_eax(eax_value() * dy));
    distance = ksqrt(squared);
    if (distance >= 256)
        goto remove_from_list;
    in_esi(-50);
    in_eax(-350);
    in_edx(-edx_value());
    in_ebx(-ebx_value());
    in_edx(edx_value() * 16384);
    in_ebx(ebx_value() * 16384);
    projectile_player_hit_timer = si_value();
    projectile_player_hit_x = edx_value();
    projectile_player_hit_y = ebx_value();
    adjust_status_value(eax_value());
    in_eax(0);
    in_al(projectile_player_mode);
    if (eax_value() == 2)
        goto remove_from_list;
    in_eax(projectile_selected_weapon);
    if (eax_value() == 1) {
        projectile_close_hit_tile = 0x323;
        goto remove_from_list;
    }
    if (eax_value() == 2 || eax_value() == 3)
        projectile_close_hit_tile = 0x327;

remove_from_list:
    /* Fill the vacated list slot with the last active projectile. */
    in_esi(di_value());
    in_ebx(esi_value() * 44);
    in_eax(projectile_count);
    load_projectile_slot_in_edx();
    in_ax(projectile_list[eax_value()]);
    projectile_list[edx_value()] = ax_value();
    keep_projectile_list_publication_order();
    --projectile_count;

    /* Resolve a hit halfway between the previous and current sprite positions. */
    load_midpoint_previous_x();
    in_edx(*(const long *)((const char *)projectile_x + ebx_value()) - eax_value());
    *(long *)((char *)projectile_x + ebx_value()) -= in_eax(edx_value() / 2);
    load_midpoint_previous_y();
    in_edx(*(const long *)((const char *)projectile_y + ebx_value()) - eax_value());
    *(long *)((char *)projectile_y + ebx_value()) -= in_eax(edx_value() / 2);
    in_edx(*(const long *)((const char *)projectile_z + ebx_value()) - ebp_value());
    distance = in_eax(edx_value() / 2);
    load_midpoint_current_z();
    load_midpoint_sector();
    subtract_midpoint_z_delta(distance);
    in_eax(esi_value());
    *(long *)((char *)projectile_z + ebx_value()) = ebp_value();
    change_projectile_sector(eax_value(), edx_value());
    /* The low 16 bits of the collision result encode the hit type and index. */
    in_eax(0);
    in_ax(cx_value());
    if ((unsigned long)eax_value() >= 0xc000UL) {
        copy_projectile_collision_number();
        in_ebx(ebx_value() - 0xc000L);
        in_eax(in_eax(bx_value()) * 44);
        in_dx(*(const short *)((const char *)projectile_lotag + eax_value()));
        keep_low_collision_lotag();
        if (in_edx(dx_value()) == 4) {
            in_ax(*(const short *)((const char *)projectile_hitag + eax_value()));
            hitag_low_byte();
            dispatch_hit_event(eax_value());
        }
        in_edx(di_value());
        in_eax(bx_value());
        apply_projectile_hit(eax_value(), edx_value(), ecx_value());
        goto finish;
    }
    if ((unsigned long)eax_value() >= 0x8000UL)
        goto finish;
    in_edx(projectile_player_z);
    if (edx_value() < *(const long *)((const char *)projectile_z + ebx_value()))
        *((unsigned char *)projectile_extra_high + ebx_value()) |= 0x20;

finish:
    if (projectile_close_hit_tile == 0) {
        start_sequence(in_eax(di_value()));
        goto advance;
    }
    remove_updated_projectile(in_eax(di_value()));
advance:
    advance_projectile_slot();
check_count:
    slot = projectile_list_slot();
    if (slot <= projectile_count)
        goto step;
    end_projectile_update();
}
