/* Step the planar cursor with the original instruction sequences. */
extern void step_planar_right_body(void);
#pragma aux step_planar_right_body = 0x05 0xd0 0xc5 0x83 0xdf 0x00 modify exact [eax];

void step_planar_right(void);
#pragma aux step_planar_right modify exact [eax];
void step_planar_right(void)
{
    step_planar_right_body();
}

extern void step_planar_left_body(void);
#pragma aux step_planar_left_body = 0x05 0xd0 0xcd 0x83 0xd7 0x00 modify exact [eax];

void step_planar_left(void);
#pragma aux step_planar_left modify exact [eax];
void step_planar_left(void)
{
    step_planar_left_body();
}
