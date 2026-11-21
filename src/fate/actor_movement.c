extern short movement_actor_sprite[];
extern long movement_sprite_x, movement_sprite_y;
extern short movement_sprite_angle, advance_clock;
extern unsigned char actor_kind[];

extern long absolute_long(long);
extern short absolute_int(int);
extern short getangle(long, long);
extern void route_actor_toward_target(int, long, long, int);
extern void move_actor_return(void);

/* Empty Watcom auxiliaries bind C values to the original live registers. */
extern long into_eax(long);
#pragma aux into_eax = "" parm [eax] value [eax] modify exact [];
extern long from_eax(void);
#pragma aux from_eax = "" value [eax] modify exact [];
extern long into_ebx(long);
#pragma aux into_ebx = "" parm [ebx] value [ebx] modify exact [];
extern long from_ebx(void);
#pragma aux from_ebx = "" value [ebx] modify exact [];
extern long into_ecx(long);
#pragma aux into_ecx = "" parm [ecx] value [ecx] modify exact [];
extern long from_ecx(void);
#pragma aux from_ecx = "" value [ecx] modify exact [];
extern long into_edx(long);
#pragma aux into_edx = "" parm [edx] value [edx] modify exact [];
extern long from_edx(void);
#pragma aux from_edx = "" value [edx] modify exact [];
extern long into_edi(long);
#pragma aux into_edi = "" parm [edi] value [edi] modify exact [];
extern long from_edi(void);
#pragma aux from_edi = "" value [edi] modify exact [];
extern long into_esi(long);
#pragma aux into_esi = "" parm [esi] value [esi] modify exact [];
extern long from_esi(void);
#pragma aux from_esi = "" value [esi] modify exact [];
extern short from_ax(void);
#pragma aux from_ax = "" value [ax] modify exact [];
extern short from_bx(void);
#pragma aux from_bx = "" value [bx] modify exact [];
extern short from_si(void);
#pragma aux from_si = "" value [si] modify exact [];
extern short from_di(void);
#pragma aux from_di = "" value [di] modify exact [];
extern short into_bx(short);
#pragma aux into_bx = "" parm [bx] value [bx] modify exact [];
extern unsigned char from_bh(void);
#pragma aux from_bh = "" value [bh] modify exact [];
extern unsigned char into_bh(unsigned char);
#pragma aux into_bh = "" parm [bh] value [bh] modify exact [];
extern unsigned char into_bl(unsigned char);
#pragma aux into_bl = "" parm [bl] value [bl] modify exact [];
extern unsigned char into_dl(unsigned char);
#pragma aux into_dl = "" parm [dl] value [dl] modify exact [];
#pragma aux absolute_long modify exact [eax];
#pragma aux absolute_int modify exact [eax];
#pragma aux getangle modify exact [eax];
#pragma aux route_actor_toward_target modify exact [eax];
#define POSITION(field, offset) (*(long *)((char *)&movement_sprite_##field + (offset)))
#define ANGLE(offset) (*(short *)((char *)&movement_sprite_angle + (offset)))

extern void set_actor_turning(void);
#pragma aux set_actor_turning = "mov byte ptr [ecx+actor_kind],2" modify exact [];

/* Preserve the original shared frame, which shifts the incoming stack arguments by 16 bytes. */
extern void begin_actor_move(int actor, long x, long y, int target);
#pragma aux begin_actor_move = \
    "push esi" "push edi" "sub esp,8" "mov edi,eax" "mov esi,edx" "mov [esp],ecx" \
    "movsx ecx,ax" "mov ax,[ecx*2+movement_actor_sprite]" "movsx edx,ax" \
    "imul edx,edx,44" "mov [esp+4],eax" \
    parm [eax] [edx] [ebx] [ecx] modify exact [eax ecx edx esi edi];

extern long horizontal_distance(void);
#pragma aux horizontal_distance = "mov eax,esi" "sub eax,[edx+movement_sprite_x]" \
    "call absolute_long" value [eax] modify exact [eax];

/* When no turning point is supplied, clear the actor state and leave through the shared tail. */
extern void require_turning_point(void);
#pragma aux require_turning_point = \
    "cmp dword ptr [esp+14h],0" "jne turn" "cmp dword ptr [esp+18h],0" "jne turn" \
    "xor bh,bh" "mov [ecx+actor_kind],bh" "jmp move_actor_return" "turn:" \
    modify exact [ebx];

extern short target_angle(void);
#pragma aux target_angle = value [dx] modify exact [];
extern short current_angle(void);
#pragma aux current_angle = value [bx] modify exact [];
extern int turn_step_in_eax(int);
#pragma aux turn_step_in_eax = parm [eax] value [eax] modify exact [];

extern void load_route_target_and_mark_actor(void);
#pragma aux load_route_target_and_mark_actor = "movsx ecx,word ptr [esp]" "mov [eax+actor_kind],dl" modify exact [ecx];

extern void release_actor_move_frame(void);
#pragma aux release_actor_move_frame = "add esp,8" "pop edi" "pop esi" modify exact [];

extern void move_actor(int, long, long, int, long, long);
#pragma aux move_actor parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx esi edi];

void move_actor(int actor, long x, long y, int attack_target, long turn_x, long turn_y)
{
    int step;

    begin_actor_move(actor, x, y, attack_target);
    if (horizontal_distance() > 512 || absolute_long(into_eax(from_ebx()) - POSITION(y, from_edx())) > 512)
        goto request;
    require_turning_point();
    if (!advance_clock)
        goto done;

    /* The compiler-facing turn_x slot now overlays the saved sprite index. */
    into_eax((long)*(short *)&turn_x);
    into_eax(from_eax() * 44);
    into_ecx(from_di());
    set_actor_turning();
    into_edx(*(volatile long *)((char *)&turn_y + 16));
    into_esi(POSITION(y, from_eax()));
    into_bx(ANGLE(from_eax()));
    into_edx(from_edx() - from_esi());
    into_esi(*(long *)((char *)&turn_x + 16));
    into_edi(POSITION(x, from_eax()));
    into_eax(from_esi());
    into_eax(from_eax() - from_edi());
    getangle(from_eax(), from_edx());
    into_edx(from_eax());
    into_esi(from_eax());
    into_edi(from_ax());
    into_eax(from_bx());
    into_edi(from_edi() - from_eax());
    into_eax(from_edi());
    absolute_int(from_eax());
    into_edi(from_eax());
    if (into_eax(from_ax()) >= 256)
        goto gradual_turn;
    actor_kind[from_ecx()] = into_bl(0);
    into_ebx(from_edx());
    goto save;
gradual_turn:
    /* Build angles wrap every 2048 units. An ordinary step turns one eighth of a circle. */
    if (target_angle() <= current_angle())
        goto negative_turn;
    step = turn_step_in_eax(256);
    goto wrap;
negative_turn:
    step = turn_step_in_eax(-256);
wrap:
    if (into_edx(from_di()) > 1024)
        step = into_eax(-step);
    into_ebx(from_ebx() + step);
    into_bh(from_bh() & 7);
    into_edx(from_si());
    into_edx(from_edx() - into_eax(from_bx()));
    absolute_int(into_eax(from_edx()));
    if (into_eax(from_ax()) < 256)
        into_ebx(from_esi());
save:
    ANGLE(into_eax((long)*(short *)&turn_x) * 44) = from_bx();
    goto done;
request:
    into_dl(1);
    into_eax(from_di());
    load_route_target_and_mark_actor();
    into_edx(from_esi());
    route_actor_toward_target(from_eax(), from_edx(), from_ebx(), from_ecx());
done:
    release_actor_move_frame();
}
