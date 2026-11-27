extern unsigned char audio_enabled;
extern int audio_device_id, audio_timer_handle, audio_driver;
extern int audio_sample_rate, audio_driver_buffer_size;
extern int audio_driver_configuration[];
extern void (*audio_timer_callback)(void);
extern const char audio_system_init_error[], audio_driver_init_error[];
extern const char audio_callback_error[], audio_configuration_error[];

extern int read_audio_configuration(void);
#pragma aux read_audio_configuration modify exact [eax];
extern int audio_system_init(int, int);
#pragma aux audio_system_init modify exact [eax edx];
extern void audio_system_shutdown(void);
#pragma aux audio_system_shutdown modify exact [eax];
extern int audio_driver_init(int *, int *);
#pragma aux audio_driver_init modify exact [eax edx ebx];
extern int timer_register_callback(int, void (*)(void), int *);
#pragma aux timer_register_callback modify exact [eax ebx edx];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];

/* Preserve the audio enable byte in the low byte of EDX. */
extern unsigned char hold_audio_enable(unsigned char);
#pragma aux hold_audio_enable = "" parm [dl] value [dl] modify exact [];

void initialize_game_audio(void)
{
    if (read_audio_configuration()) {
        int device = audio_device_id;
        if (device >= -1 && device <= 0) {
            audio_enabled = hold_audio_enable(0);
            return;
        }
        if (audio_system_init(0, 0))
            report_game_error(audio_system_init_error);
        audio_sample_rate = 11025;
        audio_driver_buffer_size = 8192;
        if (audio_driver_init(audio_driver_configuration, &audio_driver)) {
            audio_system_shutdown();
            report_game_error(audio_driver_init_error);
        }
        if (timer_register_callback(40, audio_timer_callback, &audio_timer_handle))
            report_game_error(audio_callback_error);
        audio_enabled = 1;
    } else {
        audio_enabled = 0;
        report_game_error(audio_configuration_error);
    }
}
