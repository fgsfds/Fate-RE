/* Promote the sole requesting network player to the front of the player list. */
extern unsigned char rotate_network_enabled;
extern short rotate_first_player, rotate_next_player[], rotate_local_player;
extern unsigned short rotate_player_input_word[];
extern unsigned char rotate_current_a[], rotate_current_b[], rotate_current_c[];
extern unsigned short rotate_current_word[];
extern unsigned char rotate_previous_a[], rotate_previous_b[], rotate_previous_c[];
extern unsigned short rotate_previous_word[];
extern unsigned char rotate_local_a, rotate_local_b, rotate_local_c;
extern unsigned short rotate_local_word;
extern unsigned char rotate_saved_local_a, rotate_saved_local_b, rotate_saved_local_c;
extern unsigned short rotate_saved_local_word;
extern long rotate_actor_clock, rotate_event_read, rotate_event_state, rotate_event_write;
extern long rotate_saved_clock, rotate_last_tick, totalclock;
extern char rotate_lead_text[];
extern const char rotate_remote_lead_format[];
extern unsigned char rotate_lead_text_length;
extern long rotate_text_deadline;
extern int sprintf(char *, const char *, ...);
extern unsigned strlen(const char *);
#pragma aux strlen parm [eax] value [eax] modify exact [eax ecx];

/* These empty ABI bindings retain Watcom's register assignments. */
extern long in_eax(long);
#pragma aux in_eax = parm [eax] value [eax] modify exact [];
extern long eax_value(void);
#pragma aux eax_value = value [eax] modify exact [];
extern long in_edx(long);
#pragma aux in_edx = parm [edx] value [edx] modify exact [];
extern long edx_value(void);
#pragma aux edx_value = value [edx] modify exact [];
extern long in_ebx(long);
#pragma aux in_ebx = parm [ebx] value [ebx] modify exact [];
extern long ebx_value(void);
#pragma aux ebx_value = value [ebx] modify exact [];
extern long in_ecx(long);
#pragma aux in_ecx = parm [ecx] value [ecx] modify exact [];
extern long ecx_value(void);
#pragma aux ecx_value = value [ecx] modify exact [];
extern short in_ax(short);
#pragma aux in_ax = parm [ax] value [ax] modify exact [];
extern short ax_value(void);
#pragma aux ax_value = value [ax] modify exact [];
extern short in_bx(short);
#pragma aux in_bx = parm [bx] value [bx] modify exact [];
extern short bx_value(void);
#pragma aux bx_value = value [bx] modify exact [];
extern short in_dx(short);
#pragma aux in_dx = parm [dx] value [dx] modify exact [];
extern short dx_value(void);
#pragma aux dx_value = value [dx] modify exact [];
extern short in_cx(short);
#pragma aux in_cx = parm [cx] value [cx] modify exact [];
extern short cx_value(void);
#pragma aux cx_value = value [cx] modify exact [];
extern unsigned char in_al(unsigned char);
#pragma aux in_al = parm [al] value [al] modify exact [];
extern unsigned char in_bl(unsigned char);
#pragma aux in_bl = parm [bl] value [bl] modify exact [];
extern unsigned char in_bh(unsigned char);
#pragma aux in_bh = parm [bh] value [bh] modify exact [];
extern unsigned char bh_value(void);
#pragma aux bh_value = value [bh] modify exact [];

#pragma pack(push, 1)
/* The original leader message copy is exactly 18 bytes. */
typedef struct {
    unsigned long words[4];
    unsigned short last;
} LeadMessage;
#pragma pack(pop)
extern LeadMessage rotate_lead_message, rotate_local_lead_message;

extern void keep_request_counter(long);
#pragma aux keep_request_counter = parm [eax] modify exact [];
extern void keep_input_index(long);
#pragma aux keep_input_index = parm [edx] modify exact [];
void rotate_network_lead_player(void)
{
    long ordinal, tick, request_count;
    unsigned char input;
    if (!rotate_network_enabled)
        return;
    /* A transfer occurs only when exactly one linked player requests it. */
    in_edx(rotate_first_player);
    in_eax(0);
    goto count_test;
count_player:
    request_count = in_eax(eax_value());
    in_ecx(edx_value());
    in_ebx(edx_value());
    in_bx(*(const short *)((const char *)rotate_player_input_word + ecx_value() + ebx_value() * 4));
    in_bl(0);
    in_bh(bh_value() & 2);
    if (in_ebx(bx_value())) {
        keep_request_counter(request_count);
        in_eax(eax_value() + 1);
    } else {
        keep_request_counter(request_count);
    }
    in_edx(rotate_next_player[edx_value()]);
count_test:
    if (edx_value() >= 0)
        goto count_player;
    if (eax_value() != 1)
        return;
    in_edx(rotate_first_player);
    in_eax(rotate_next_player[edx_value()]);
    goto candidate_test;
candidate:
    in_ecx(eax_value());
    in_ebx(eax_value());
    in_bx(*(const short *)((const char *)rotate_player_input_word + ecx_value() + ebx_value() * 4));
    in_bl(0);
    in_bh(bh_value() & 2);
    in_ecx(bx_value());
    in_ebx(eax_value() * 2);
    if (!ecx_value())
        goto next_candidate;
    /* Unlink the requesting successor and prepend it to the player list. */
    in_cx(*(const short *)((const char *)rotate_next_player + ebx_value()));
    rotate_next_player[edx_value()] = cx_value();
    in_dx(rotate_first_player);
    rotate_first_player = ax_value();
    /* Bump saved inputs to force their next change notification. */
    input = in_al(rotate_local_a);
    rotate_saved_local_a = in_al(input + 1);
    input = in_al(rotate_local_b);
    rotate_saved_local_b = in_al(input + 1);
    input = in_al(rotate_local_c);
    rotate_saved_local_c = in_al(input + 1);
    in_ax(rotate_local_word);
    *(short *)((char *)rotate_next_player + ebx_value()) = dx_value();
    in_eax((long)((unsigned long)eax_value() + 1UL));
    in_edx(0);
    rotate_saved_local_word = ax_value();
    goto input_test;
reset_input:
    in_eax(edx_value());
    in_eax(eax_value() * 4);
    in_eax(eax_value() + edx_value());
    input = in_bl(rotate_current_a[eax_value()]);
    rotate_previous_a[eax_value()] = in_bl(input + 1);
    input = in_bl(rotate_current_b[eax_value()]);
    rotate_previous_b[eax_value()] = in_bl(input + 1);
    input = in_bl(rotate_current_c[eax_value()]);
    rotate_previous_c[eax_value()] = in_bl(input + 1);
    in_bx(*(const short *)((const char *)rotate_current_word + eax_value()));
    in_ebx((long)((unsigned long)ebx_value() + 1UL));
    keep_input_index(edx_value());
    in_edx(edx_value() + 1);
    *(short *)((char *)rotate_previous_word + eax_value()) = bx_value();
input_test:
    if (edx_value() < 16)
        goto reset_input;
    in_edx(0);
    /* Reset the event queue and realign all clocks to the simulation tick. */
    tick = in_eax(rotate_actor_clock);
    rotate_event_read = edx_value();
    rotate_event_state = edx_value();
    rotate_event_write = edx_value();
    rotate_saved_clock = tick;
    rotate_last_tick = eax_value();
    totalclock = eax_value();
    in_eax(1);
    in_edx(rotate_first_player);
    in_ebx(rotate_local_player);
    goto ordinal_test;
find_ordinal:
    if (ebx_value() == edx_value())
        goto message;
    in_eax(eax_value() + 1);
    in_edx(rotate_next_player[edx_value()]);
ordinal_test:
    if (edx_value() >= 0)
        goto find_ordinal;
message:
    /* The local player sees its new one-based ordinal in the lead announcement. */
    ordinal = eax_value();
    if (ordinal == 1)
        rotate_lead_message = rotate_local_lead_message;
    else
        sprintf(rotate_lead_text, rotate_remote_lead_format, ordinal);
    rotate_lead_text_length = (unsigned char)strlen(rotate_lead_text);
    in_eax((long)((unsigned long)totalclock + 120UL));
    rotate_text_deadline = eax_value();
    return;
next_candidate:
    in_edx(eax_value());
    in_eax(*(const short *)((const char *)rotate_next_player + ebx_value()));
candidate_test:
    if (eax_value() >= 0)
        goto candidate;
}
