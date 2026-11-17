/* Install the hardware x87 callbacks used around a DOS child launch. */
typedef void (*FpuStateAction)(void *);

extern void save_fpu_state(void *);
extern void restore_fpu_state(void *);
extern unsigned char fpu_present;
extern unsigned short fpu_control_word;
extern FpuStateAction save_spawn_state, restore_spawn_state;

extern void configure_fpu(unsigned);
#pragma aux configure_fpu parm [eax] modify exact [eax];

void init_fpu_callbacks(void)
{
    if (fpu_present != 0) {
        FpuStateAction save = save_fpu_state;
        FpuStateAction restore = restore_fpu_state;
        save_spawn_state = save;
        restore_spawn_state = restore;
    }
    configure_fpu(fpu_control_word);
}

void check_fpu_callbacks(void)
{
    if (fpu_present != 0)
        init_fpu_callbacks();
}
