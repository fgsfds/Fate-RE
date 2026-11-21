typedef void (__interrupt __far *KeyboardHandler)(void);
extern KeyboardHandler previous_keyboard_vector;
extern unsigned char key_fifo_read, key_fifo_write, key_state[];
extern void keyboard_interrupt(void);
extern KeyboardHandler dos_getvect(int);
#pragma aux dos_getvect "_dos_getvect_" parm [eax] value [dx eax] modify exact [eax edx];
extern void dos_setvect(int, void (*)(void), unsigned);
#pragma aux dos_setvect "_dos_setvect_" parm [eax] [ebx] [ecx] modify exact [eax ebx ecx];
extern void disable_interrupts(void), enable_interrupts(void);
#pragma aux disable_interrupts modify exact [eax];
#pragma aux enable_interrupts modify exact [eax];

/* Read the current code selector with the original MOV ECX, CS encoding. */
extern unsigned get_code_selector(void);
#pragma aux get_code_selector = 0x8c 0xc9 value [ecx] modify exact [ecx];

/* Keep the vector number and handler offset in Watcom argument registers. */
extern void (*hold_keyboard_entry(void (*)(void)))(void);
#pragma aux hold_keyboard_entry = parm [ebx] value [ebx] modify exact [];
extern int remember_vector(int);
#pragma aux remember_vector = parm [eax] value [eax] modify exact [];

void install_keyboard_interrupt(void)
{
    int index, vector;
    KeyboardHandler previous;
    void (*handler)(void);
    unsigned selector;

    key_fifo_write = key_fifo_read = 0;
    index = 0;
    goto check_key;
    do {
        ++index;
        key_state[index - 1] = 0;
    check_key:
        ;
    } while (index < 256);

    vector = remember_vector(9);
    handler = hold_keyboard_entry(keyboard_interrupt);
    previous = dos_getvect(vector);
    selector = get_code_selector();
    previous_keyboard_vector = previous;
    disable_interrupts();
    dos_setvect(9, handler, selector);
    enable_interrupts();
}
