/* Distinguish x87 infinity semantics and load the requested control word. */
void configure_fpu(void);
#pragma aux configure_fpu aborts;

extern void push_ax(void);
#pragma aux push_ax = "db 66h, 50h" modify exact [eax];

extern void fpu_compare(void);
#pragma aux fpu_compare = "db 9bh,0dbh,0e3h,0d9h,0e8h,0d9h,0eeh,0deh,0f9h,0d9h,0c0h,0d9h,0e0h,0deh,0d9h,0dfh,0e0h,0b0h,02h,9eh" \
    "db 74h, 02h" /* marker-rel8 +1,+2 */ modify exact [eax];

extern void mov_al_3(void);
#pragma aux mov_al_3 = "db 0b0h, 03h" modify exact [eax];

extern void fpu_control(void);
#pragma aux fpu_control = "db 9bh,0dbh,0e3h,0d9h,2ch,24h,66h,87h,04h,24h,66h,58h,0c3h" modify exact [];

void configure_fpu(void)
{
    push_ax();
    fpu_compare();
    mov_al_3();
    fpu_control();
}
