extern unsigned short effect_speed;
extern short effect_count, player_sector, player_sprite, player_angle;
extern long player_x, player_y, player_z;
extern short effect_sprite_xvel, effect_sprite_yvel, effect_sprite_zvel;
extern short sintable[];
extern int spawn_sprite_at_position(int, const long *, int);
extern void add_listed_sprite(int);
#pragma aux add_listed_sprite parm [eax] modify exact [eax];

/* Keep C expressions in the registers used by the remaining motion stub. */
extern long effect_eax(long);
#pragma aux effect_eax = "" parm [eax] value [eax] modify exact [];
extern long effect_ebx(long);
#pragma aux effect_ebx = "" parm [ebx] value [ebx] modify exact [];
extern long effect_ecx(long);
#pragma aux effect_ecx = "" parm [ecx] value [ecx] modify exact [];
extern long effect_edx(long);
#pragma aux effect_edx = "" parm [edx] value [edx] modify exact [];
extern long effect_edi(long);
#pragma aux effect_edi = "" parm [edi] value [edi] modify exact [];
extern long effect_esi(long);
#pragma aux effect_esi = "" parm [esi] value [esi] modify exact [];
extern long eax_value(void);
#pragma aux eax_value = "" value [eax] modify exact [];
extern long ebx_value(void);
#pragma aux ebx_value = "" value [ebx] modify exact [];
extern long esi_value(void);
#pragma aux esi_value = "" value [esi] modify exact [];
extern long edi_value(void);
#pragma aux edi_value = "" value [edi] modify exact [];
extern long ecx_value(void);
#pragma aux ecx_value = "" value [ecx] modify exact [];
extern short effect_bx(short);
#pragma aux effect_bx = "" parm [bx] value [bx] modify exact [];
extern short effect_dx(short);
#pragma aux effect_dx = "" parm [dx] value [dx] modify exact [];
extern short effect_di(short);
#pragma aux effect_di = "" parm [di] value [di] modify exact [];
extern short effect_cx(short);
#pragma aux effect_cx = "" parm [cx] value [cx] modify exact [];
extern short bx_value(void);
#pragma aux bx_value = "" value [bx] modify exact [];
extern short dx_value(void);
#pragma aux dx_value = "" value [dx] modify exact [];
extern void start_speed_word(long);
#pragma aux start_speed_word = "" parm [edx] modify exact [edx];
extern void set_speed_low(unsigned short);
#pragma aux set_speed_low = "" parm [dx] modify exact [];
#define VELOCITY(field, offset) (*(short *)((char *)&effect_sprite_##field##vel + (offset)))

/* Set the two launch vector components 512 angle units apart. */
extern long *position_in_edx(long *);
#pragma aux position_in_edx = "" parm [edx] value [edx] modify exact [];
extern long *current_position(void);
#pragma aux current_position = "" value [edx] modify exact [];
#pragma aux spawn_sprite_at_position parm [eax] [edx] [ebx] modify exact [eax ebx edx];
/* These stack arguments are consumed by the final motion call. */
extern void stash_first_motion(long component, int stack_flag);
#pragma aux stash_first_motion = "mov [esp+4],eax" parm routine [eax] [] modify exact [];

extern void retain_second_motion_angle(long);
#pragma aux retain_second_motion_angle = "" parm [eax] modify exact [esi];
extern long retain_second_motion_component(long);
#pragma aux retain_second_motion_component = "" parm [eax] value [eax] modify exact [];
extern short motion_sprite_id(void);
#pragma aux motion_sprite_id = "" value [si] modify exact [];
extern void retain_motion_sprite_order(long);
#pragma aux retain_motion_sprite_order = "" parm [eax] modify exact [esi];
/* Push a motion scale without changing the staged value in EAX. */
extern long push_motion_scale(long component, int scale);
#pragma aux push_motion_scale = "" parm routine [eax] [] value [eax] modify exact [eax];

extern unsigned char effect_bh(unsigned char);
#pragma aux effect_bh = "" parm [bh] value [bh] modify exact [];
extern unsigned char bh_value(void);
#pragma aux bh_value = "" value [bh] modify exact [];
extern long effect_speed_in_edx(void);
#pragma aux effect_speed_in_edx = value [edx] modify exact [];

extern void finish_effect_velocity_store(void);
#pragma aux finish_effect_velocity_store = "" modify exact [eax];
extern long x_direction_in_eax(long);
#pragma aux x_direction_in_eax = parm [eax] value [eax] modify exact [];

/* The motion call consumes the three arguments assembled on the stack. */
extern void leave_first_motion_on_stack(long);
#pragma aux leave_first_motion_on_stack = "mov edx,[esp+12]" "mov [esp+16],eax" parm [eax] modify exact [edx];
extern void call_prepared_effect_motion(long sprite, long second_component);
#pragma aux call_prepared_effect_motion "set_sprite_motion_" parm [eax] [ebx] modify exact [eax ebx ecx edx];

extern void keep_zero_argument_immediate(long);
#pragma aux keep_zero_argument_immediate = "" parm [eax] modify exact [ecx];

extern void spawn_counted_player_effect(void);
#pragma aux spawn_counted_player_effect parm caller [] modify exact [eax];

void spawn_counted_player_effect(void)
{
    struct {
        volatile long x, y, z;
    } position;
    short remaining = effect_dx(effect_count);
    long direction;

    if (remaining <= 0)
        goto done;
    effect_eax(player_x);
    effect_ebx(effect_speed_in_edx());
    position_in_edx((long *)&position);
    position.x = eax_value();
    effect_eax(player_y);
    effect_ebx(ebx_value() - 1);
    position.y = eax_value();
    effect_eax(player_z);
    effect_count = bx_value();
    effect_eax((long)((unsigned long)eax_value() + 4000));
    effect_ebx(player_sector);
    position.z = eax_value();
    effect_eax(spawn_sprite_at_position(36, current_position(), ebx_value()));
    effect_edx(player_angle);
    effect_esi(eax_value());
    effect_eax((effect_speed_in_edx() + 212) & 2047);
    effect_eax(sintable[eax_value()]);
    effect_ecx(0);
    effect_eax((unsigned long)eax_value() << 8);
    keep_zero_argument_immediate(eax_value());
    stash_first_motion(eax_value(), 0);
    effect_eax(effect_speed_in_edx() - 300);
    retain_second_motion_angle(eax_value());
    effect_eax(push_motion_scale(eax_value(), 1024));
    effect_eax(eax_value() & 2047);
    /* Sign-extend the spawned sprite index after masking the angle. */
    retain_motion_sprite_order(eax_value());
    effect_esi(motion_sprite_id());
    effect_eax(sintable[eax_value()]);
    effect_eax(push_motion_scale(eax_value(), 1024));
    effect_eax((unsigned long)retain_second_motion_component(eax_value()) << 8);
    leave_first_motion_on_stack(eax_value());
    effect_ebx(eax_value());
    effect_eax(esi_value());
    call_prepared_effect_motion(eax_value(), ebx_value());

    /* Horizontal speed uses the player heading and the effect's unsigned speed word. */
    effect_eax(player_angle);
    effect_eax((eax_value() + 512) & 2047);
    start_speed_word(0);
    effect_eax(sintable[eax_value()]);
    set_speed_low(effect_speed);
    direction = effect_eax(eax_value() >> 3);
    effect_ebx(effect_eax(effect_speed_in_edx() * x_direction_in_eax(direction)));
    effect_eax(esi_value() * 44);
    VELOCITY(x, eax_value()) = bx_value();
    effect_bx(player_angle);
    effect_bh(bh_value() & 7);
    effect_ebx(bx_value());
    effect_ebx(sintable[ebx_value()]);
    direction = effect_ebx(ebx_value() >> 3);
    VELOCITY(y, eax_value()) = (short)effect_edx(effect_speed_in_edx() * direction);

    /* Add the player's momentum, with 16-bit velocity truncation. */
    effect_edx(player_sprite);
    effect_edx(effect_speed_in_edx() * 44);
    VELOCITY(z, eax_value()) = -1000;
    effect_bx(VELOCITY(x, effect_speed_in_edx()));
    effect_di(VELOCITY(x, eax_value()));
    effect_ebx((unsigned long)ebx_value() << 3);
    VELOCITY(x, eax_value()) = (short)effect_edi(edi_value() + ebx_value());
    effect_bx(VELOCITY(y, effect_speed_in_edx()));
    effect_cx(VELOCITY(y, eax_value()));
    effect_ebx((unsigned long)ebx_value() << 3);
    VELOCITY(y, eax_value()) = (short)effect_ecx(ecx_value() + ebx_value());
    effect_dx(VELOCITY(z, effect_speed_in_edx()));
    effect_di(VELOCITY(z, eax_value()));
    effect_edx((unsigned long)effect_speed_in_edx() << 3);
    VELOCITY(z, eax_value()) = (short)effect_edi(edi_value() + effect_speed_in_edx());
    finish_effect_velocity_store();
    add_listed_sprite(effect_eax(esi_value()));
done:
    return;
}
