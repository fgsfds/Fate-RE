/* Replay recorded input and render the session until the quit key is pressed. */
extern unsigned char playback_view_key, playback_mode_key, playback_timer_enabled;
extern long playback_pending_time, playback_last_tick, playback_saved_clock;
extern short playback_listener, playback_first_player, playback_next_player[];
extern long playback_actor_clock, playback_frame_count, totalclock;
extern unsigned char playback_keys[], playback_player_mode[];
extern char playback_board_name[];
extern unsigned char recorded_input_a[], recorded_input_b[], recorded_input_c[];
extern unsigned char recorded_input_word[];
extern unsigned char playback_input_a[], playback_input_b[], playback_input_c[], playback_input_word[];

extern void prepare_loaded_board(const char *);
#pragma aux prepare_loaded_board parm [eax] modify exact [eax];
extern void initialize_board_entry(int);
#pragma aux initialize_board_entry parm [eax] modify exact [eax];
extern void reset_playback_timer(void);
#pragma aux reset_playback_timer modify exact [eax];
extern void snapshot_playback_input(void);
#pragma aux snapshot_playback_input modify exact [eax];
extern void process_playback_frame(void);
#pragma aux process_playback_frame modify exact [eax];
extern void render_playback_frame(int, long);
#pragma aux render_playback_frame parm [eax] [edx] modify exact [eax edx];

extern void uninitmultiplayers(void), shutdown_step_b(void), shutdown_step_d(void);
extern void shutdown_step_e(void), shutdown_engine(void), uninitgroupfile(void);
extern void playback_exit(int);
#pragma aux playback_exit "exit_" parm [eax] modify exact [eax];
extern unsigned char playback_quit;

/* The playback entry preserves every general register except EAX. */
extern void begin_playback(void);
#pragma aux begin_playback = "push ebx" "push ecx" "push edx" "push esi" "push edi" "push ebp" modify exact [];
extern void end_playback(void);
#pragma aux end_playback = "pop ebp" "pop edi" "pop esi" "pop edx" "pop ecx" "pop ebx" modify exact [];
extern void playback_text_mode(void);
#pragma aux playback_text_mode = "mov eax,3" "int 10h" modify exact [eax];
extern unsigned char zero_playback_timer(void);
#pragma aux zero_playback_timer = "xor ah,ah" value [ah] modify exact [eax];
extern void zero_playback_clocks(void);
#pragma aux zero_playback_clocks = "xor ebp,ebp" modify exact [];
extern long previous_playback_clock(void);
#pragma aux previous_playback_clock = value [ebp] modify exact [];
/* Keep the original Watcom register assignments without emitting instructions. */
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
extern short in_dx(short);
#pragma aux in_dx = parm [dx] value [dx] modify exact [];
extern unsigned char in_al(unsigned char);
#pragma aux in_al = parm [al] value [al] modify exact [];
extern unsigned char in_cl(unsigned char);
#pragma aux in_cl = parm [cl] value [cl] modify exact [];
extern unsigned char in_dl(unsigned char);
#pragma aux in_dl = parm [dl] value [dl] modify exact [];
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
extern short bx_value(void);
#pragma aux bx_value = value [bx] modify exact [];
extern short dx_value(void);
#pragma aux dx_value = value [dx] modify exact [];

#pragma aux uninitmultiplayers modify exact [eax ebx ecx edx];
#pragma aux shutdown_step_b modify exact [eax ebx ecx edx];
#pragma aux shutdown_step_d modify exact [eax ebx ecx edx];
#pragma aux shutdown_step_e modify exact [eax ebx ecx edx];
#pragma aux shutdown_engine modify exact [eax ebx ecx edx];
#pragma aux uninitgroupfile modify exact [eax ebx ecx edx];
extern void zero_mode_register(void);
#pragma aux zero_mode_register = "xor edx,edx" modify exact [edx];
extern void keep_incoming_edx(long);
#pragma aux keep_incoming_edx = parm [edx] modify exact [];
extern void keep_incoming_ebx(long);
#pragma aux keep_incoming_ebx = parm [ebx] modify exact [];

void run_recorded_session(void);
#pragma aux run_recorded_session modify exact [eax ebx ecx edx esi edi];

void run_recorded_session(void)
{
    short next;
    unsigned char timer, field;

    begin_playback();
    in_ebx(playback_frame_count);
    timer = zero_playback_timer();
    keep_incoming_edx(edx_value());
    in_edx(0);
    playback_timer_enabled = timer;
    playback_pending_time = edx_value();

check_quit:
    if (playback_quit)
        goto shutdown;
check_clock:
    /* Replay one input frame per three elapsed simulation ticks. */
    if (in_eax(playback_actor_clock + 3) > totalclock)
        goto draw_frame;
    if (ebx_value() < playback_frame_count)
        goto start_inputs;
    prepare_loaded_board(playback_board_name);
    in_ebx(playback_first_player);
    goto check_player;
initialize_player:
    initialize_board_entry(in_eax(bx_value()));
    in_ebx(playback_next_player[ebx_value()]);
check_player:
    if (ebx_value() >= 0)
        goto initialize_player;
    reset_playback_timer();
    zero_playback_clocks();
    keep_incoming_ebx(ebx_value());
    in_ebx(0);
    playback_last_tick = previous_playback_clock();
    playback_saved_clock = previous_playback_clock();
start_inputs:
    in_esi(playback_first_player);
    in_edi(0);
    goto check_input;
copy_input:
    /* Records are five bytes per player. Each recorded frame reserves two records. */
    in_ecx(ebx_value());
    in_eax(edi_value());
    in_ecx(ecx_value() * 4);
    in_eax(eax_value() * 4);
    in_ecx(ecx_value() + ebx_value());
    in_eax(eax_value() + edi_value());
    in_ecx(ecx_value() * 2);
    in_edx(ecx_value() + eax_value());
    in_eax((in_eax(esi_value()) * 4 + esi_value()));
    field = in_cl(recorded_input_a[edx_value()]);
    playback_input_a[eax_value()] = field;
    field = in_cl(recorded_input_b[edx_value()]);
    in_edi(edi_value() + 1);
    playback_input_b[eax_value()] = field;
    field = in_cl(recorded_input_c[edx_value()]);
    next = in_dx(*(const short *)(recorded_input_word + edx_value()));
    playback_input_c[eax_value()] = field;
    in_esi(playback_next_player[esi_value()]);
    *(short *)(playback_input_word + eax_value()) = dx_value();
check_input:
    if (esi_value() >= 0)
        goto copy_input;
    snapshot_playback_input();
    process_playback_frame();
    in_ebx(ebx_value() + 1);
    goto check_clock;
draw_frame:
    /* 5 * 17 * 257 scales each tick to one third of a 16-bit interpolation step. */
    in_edx(totalclock);
    in_esi(playback_actor_clock);
    in_edx(edx_value() - esi_value());
    in_eax(in_eax(edx_value()) * 4 + edx_value());
    in_edx(eax_value());
    in_eax(eax_value() * 16 + edx_value());
    in_edx(eax_value());
    in_eax(eax_value() * 256);
    in_edx(edx_value() + eax_value());
    render_playback_frame(in_eax(playback_listener), edx_value());

    in_eax(0);
    in_al(playback_view_key);
    if (playback_keys[eax_value()] > 0) {
        field = in_cl(0);
        playback_keys[eax_value()] = field;
        next = in_ax(playback_next_player[in_eax(playback_listener)]);
        playback_listener = next;
        if (next < 0)
            playback_listener = in_ax(playback_first_player);
    }
    in_eax(0);
    in_al(playback_mode_key);
    if (playback_keys[eax_value()] <= 0)
        goto check_quit;
    field = in_dl(0);
    playback_keys[eax_value()] = field;
    in_eax(playback_listener);
    ++playback_player_mode[eax_value()];
    zero_mode_register();
    in_dl(playback_player_mode[eax_value()]);
    if (edx_value() <= 3)
        goto check_quit;
    playback_player_mode[eax_value()] = 1;
    goto check_quit;
shutdown:
    uninitmultiplayers();
    shutdown_step_b();
    shutdown_step_d();
    shutdown_step_e();
    shutdown_engine();
    uninitgroupfile();
    playback_text_mode();
    playback_exit(0);
    end_playback();
}
