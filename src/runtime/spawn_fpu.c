/* Save and restore the x87 state around a DOS child launch. */
extern void save_fpu_state_body(void);
#pragma aux save_fpu_state_body = 0x9b 0xdd 0x30 0x9b modify exact [eax];

void save_fpu_state(void);
#pragma aux save_fpu_state modify exact [eax];
void save_fpu_state(void)
{
    save_fpu_state_body();
}

extern void restore_fpu_state_body(void);
#pragma aux restore_fpu_state_body = 0xdd 0x20 0x9b modify exact [eax];

void restore_fpu_state(void);
#pragma aux restore_fpu_state modify exact [eax];
void restore_fpu_state(void)
{
    restore_fpu_state_body();
}
