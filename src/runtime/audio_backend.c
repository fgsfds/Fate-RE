/* The driver, interrupt callbacks and mixer must remain resident in DOS. */
extern int lock_memory_region(unsigned long, unsigned long);
#pragma aux lock_memory_region parm caller [] modify exact [eax];
extern int unlock_memory_region(unsigned long, unsigned long);
#pragma aux unlock_memory_region parm caller [] modify exact [eax];

extern void timer_module_noop(void);
extern void timer_tail_noop(void);
extern void audio_init_noop(void);
extern void audio_noop_61816(void);
extern void audio_noop_6182b(void);
extern void audio_noop_62185(void);
extern void audio_noop_6219f(void);
extern void audio_noop_62414(void);
extern void audio_noop_62429(void);
extern void audio_noop_62a82(void);
extern void audio_empty_range_stub_64cfc(void);
extern void timer_vector_noop(void);
extern void audio_empty_range_stub_657ed(void);
extern void audio_empty_range_stub_65ee6(void);
extern void audio_empty_range_stub_65efb(void);
extern void audio_empty_range_stub_661b8(void);
extern void audio_empty_range_stub_661cd(void);
extern void audio_empty_range_stub_662cc(void);
extern void audio_empty_range_stub_662e1(void);
extern void audio_dispatch_noop(void);
extern void audio_backend_region_start(void);
extern void audio_helper_region_end(void);
extern void audio_empty_range_stub_66b74(void);
extern void audio_empty_range_stub_67005(void);
extern void audio_detection_noop(void);
extern void audio_detection_end(void);
extern void audio_detection_lookup_start(void);
extern void audio_detection_lookup_end(void);
extern void audio_input_region_start(void);
extern void audio_input_region_end(void);
extern void audio_output_region_start(void);
extern void audio_output_region_end(void);
extern char timer_state_start[];
extern char timer_state_end[];
extern char driver_state_start[];
extern char driver_state_end[];
extern char dpmi_state_start[];
extern char dpmi_state_end[];
extern char mixer_state_start[];
extern char mixer_state_end[];

#define APPLY_RANGE(action, first, last) \
    if (action((unsigned long)(first), (unsigned long)(last) - (unsigned long)(first)) != 0) \
        return 5;

#define AUDIO_MEMORY_RANGES(action) \
    APPLY_RANGE(action, audio_empty_range_stub_661cd, audio_empty_range_stub_662cc) \
    APPLY_RANGE(action, audio_empty_range_stub_662e1, audio_dispatch_noop) \
    APPLY_RANGE(action, audio_noop_62429, audio_noop_62a82) \
    APPLY_RANGE(action, audio_detection_noop, audio_detection_end) \
    APPLY_RANGE(action, audio_detection_lookup_start, audio_detection_lookup_end) \
    APPLY_RANGE(action, audio_noop_6182b, audio_noop_62185) \
    APPLY_RANGE(action, audio_empty_range_stub_65efb, audio_empty_range_stub_661b8) \
    APPLY_RANGE(action, audio_empty_range_stub_657ed, audio_empty_range_stub_65ee6) \
    APPLY_RANGE(action, audio_noop_6219f, audio_noop_62414) \
    APPLY_RANGE(action, audio_init_noop, audio_noop_61816) \
    APPLY_RANGE(action, timer_module_noop, timer_tail_noop) \
    APPLY_RANGE(action, audio_backend_region_start, audio_helper_region_end) \
    APPLY_RANGE(action, audio_empty_range_stub_64cfc, timer_vector_noop) \
    APPLY_RANGE(action, audio_empty_range_stub_66b74, audio_empty_range_stub_67005) \
    APPLY_RANGE(action, audio_input_region_start, audio_input_region_end) \
    APPLY_RANGE(action, audio_output_region_start, audio_output_region_end) \
    APPLY_RANGE(action, driver_state_start, driver_state_end) \
    APPLY_RANGE(action, dpmi_state_start, dpmi_state_end) \
    APPLY_RANGE(action, timer_state_start, timer_state_end) \
    APPLY_RANGE(action, mixer_state_start, mixer_state_end)

int initialize_audio_backend(void);
#pragma aux initialize_audio_backend modify exact [eax gs];
int initialize_audio_backend(void)
{
    AUDIO_MEMORY_RANGES(lock_memory_region)
    return 0;
}

int shutdown_audio_backend(void);
#pragma aux shutdown_audio_backend modify exact [eax gs];
int shutdown_audio_backend(void)
{
    AUDIO_MEMORY_RANGES(unlock_memory_region)
    return 0;
}
