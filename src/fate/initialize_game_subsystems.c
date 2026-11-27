extern unsigned char shutdown_network, shutdown_b, shutdown_c, shutdown_d, shutdown_e, shutdown_video, shutdown_h;
extern unsigned char network_enabled, network_settings;
extern short engine_1ed1a0, engine_1ed1a2, engine_289150;
extern const char art_archive_filename[], slime_allocation_error[];

extern void load_sound_archive(void), initialize_sound_slots(void), reset_mouse_driver(void);
#pragma aux load_sound_archive modify exact [eax];
#pragma aux initialize_sound_slots modify exact [eax];
#pragma aux reset_mouse_driver modify exact [eax];

extern void initialize_video_console(void), print_video_settings_help(void), restore_text_video_mode(void);
#pragma aux initialize_video_console modify exact [eax];
#pragma aux print_video_settings_help modify exact [eax];
#pragma aux restore_text_video_mode modify exact [eax edx ecx];

extern int load_default_video_settings(int);
#pragma aux load_default_video_settings "load_video_settings_" parm [eax] modify exact [eax edx];
extern int save_default_video_settings(int);
#pragma aux save_default_video_settings "save_video_settings_" parm [eax] modify exact [eax];
extern void install_keyboard_interrupt(void), initialize_game_timer(void);
#pragma aux install_keyboard_interrupt modify exact [eax];
#pragma aux initialize_game_timer modify exact [eax ecx];

extern void initialize_network(unsigned, unsigned, unsigned);
#pragma aux initialize_network parm [eax] [edx] [ecx] modify exact [eax ebx edx];
extern void initialize_game_audio(int);
#pragma aux initialize_game_audio parm [edx] modify exact [eax];
extern void load_art_files(const char *);
#pragma aux load_art_files modify exact [eax ebx];
extern int allocate_permanent_tile(int, int, int);
#pragma aux allocate_permanent_tile modify exact [eax];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];
extern void open_text_archive(void), initialize_ripple_tables(void);
#pragma aux open_text_archive modify exact [eax];
#pragma aux initialize_ripple_tables modify exact [eax];

/* These identities control the original Watcom register assignments. */
extern unsigned char keep_video_flag(unsigned char);
#pragma aux keep_video_flag = "" parm [ah] value [ah] modify exact [];
extern unsigned char keep_art_flag(unsigned char);
#pragma aux keep_art_flag = "" parm [bl] value [bl] modify exact [];
extern unsigned char keep_text_flag(unsigned char);
#pragma aux keep_text_flag = "" parm [ch] value [ch] modify exact [];
extern unsigned char keep_zero_text(unsigned char);
#pragma aux keep_zero_text = "" parm [cl] value [cl] modify exact [];

extern int hold_eax_entry(int);
#pragma aux hold_eax_entry = "" parm [eax] value [eax] modify exact [];
extern unsigned keep_network_mode(unsigned);
#pragma aux keep_network_mode = "" parm [eax] value [eax] modify exact [ecx];
extern int prepare_save_call(int, unsigned char);
#pragma aux prepare_save_call = "" parm [eax] [dl] value [eax] modify exact [];
extern void prepare_start_ebx(unsigned);
#pragma aux prepare_start_ebx = "" parm [ebx] modify exact [];
/* The original startup stores the bytes left by these register calls. */
extern unsigned char keyboard_timer_status(void);
#pragma aux keyboard_timer_status = "" value [dl] modify exact [];
extern short initial_video_art_state(void);
#pragma aux initial_video_art_state = "" value [cx] modify exact [];
extern short initial_sound_art_state(void);
#pragma aux initial_sound_art_state = "" value [dx] modify exact [];
extern const char *keep_art_filename(const char *);
#pragma aux keep_art_filename = "" parm [eax] value [eax] modify exact [];
void initialize_game_subsystems(void);
#pragma aux initialize_game_subsystems modify exact [eax];

void initialize_game_subsystems(void)
{
    unsigned char video, art, text;
    int descriptor;
    const char *archive;

    load_sound_archive();
    initialize_sound_slots();
    reset_mouse_driver();
    initialize_video_console();
    load_default_video_settings(0);
    descriptor = hold_eax_entry(0);
    save_default_video_settings(prepare_save_call(descriptor, 1));
    print_video_settings_help();
    restore_text_video_mode();

    video = keep_video_flag(1);
    prepare_start_ebx(0);
    shutdown_video = video;
    install_keyboard_interrupt();
    shutdown_e = keyboard_timer_status();
    initialize_game_timer();
    shutdown_d = keyboard_timer_status();

    initialize_network(keep_network_mode(network_enabled), network_settings, 1);
    art = keep_art_flag(1);
    shutdown_network = art;
    initialize_game_audio(0);
    archive = keep_art_filename(art_archive_filename);
    shutdown_b = art;
    engine_1ed1a0 = initial_sound_art_state();
    engine_1ed1a2 = initial_sound_art_state();
    engine_289150 = initial_video_art_state();
    load_art_files(archive);

    if (!allocate_permanent_tile(0x122, 0x80, 0x80))
        report_game_error(slime_allocation_error);

    shutdown_c = keep_zero_text(0);
    text = keep_text_flag(1);
    open_text_archive();
    shutdown_h = text;
    initialize_ripple_tables();
}
