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

/* Step the interleaved plane cursor with the original instruction sequences. */
extern void step_interleaved_up_body(void);
#pragma aux step_interleaved_up_body = 0x10 0x66 0x81 0xc7 0x00 0x60 0x79 0x05 0x66 0x81 0xef 0xa6 0x7f 0x66 0x83 0xef 0x5a modify exact [eax];

void step_interleaved_up(void);
#pragma aux step_interleaved_up modify exact [eax];
void step_interleaved_up(void)
{
    step_interleaved_up_body();
}

extern void step_interleaved_down_body(void);
#pragma aux step_interleaved_down_body = 0x10 0x66 0x81 0xef 0x00 0x60 0x79 0x05 0x66 0x81 0xc7 0xa6 0x7f 0x66 0x83 0xc7 0x5a modify exact [eax];

void step_interleaved_down(void);
#pragma aux step_interleaved_down modify exact [eax];
void step_interleaved_down(void)
{
    step_interleaved_down_body();
}
