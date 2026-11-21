typedef void (__interrupt __far *KeyboardHandler)(void);

extern KeyboardHandler previous_keyboard_vector;
extern void dos_setvect(int vector, KeyboardHandler handler);
#pragma aux dos_setvect "_dos_setvect_" parm [eax] [ebx ecx] modify exact [eax ebx ecx];

void restore_keyboard_interrupt(void)
{
    dos_setvect(9, previous_keyboard_vector);
    /* The BIOS keyboard flags are at linear address 0x417. */
    *(volatile unsigned short *)0x417 &= 0xfcf0;
}
