/* Resume the palette fade after the presentation is initialized. */
extern long fade_in_active, fade_out_active, fade_speed;
extern void start_fade_in(long);
#pragma aux start_fade_in modify exact [eax];
extern void start_fade_out(long);
#pragma aux start_fade_out modify exact [eax];
extern int presentation_input(void);
#pragma aux presentation_input modify exact [eax];
extern void check_fade_out(void);
#pragma aux check_fade_out modify exact [];

/* The short transfers land in adjacent routines in the linked image. */
extern void return_if_inactive(void);
#pragma aux return_if_inactive = "cmp dword ptr [fade_in_active],0" "db 74h,0f6h" modify exact [];
extern void check_input_result(int);
#pragma aux check_input_result = "test eax,eax" "je check_fade_out" parm [eax] modify exact [];
extern void return_if_finished(void);
#pragma aux return_if_finished = "cmp dword ptr [fade_in_active],0" "db 74h,0c6h" modify exact [];
extern void tail_fade_out(long);
#pragma aux tail_fade_out = "db 0ebh,10h" parm [eax] aborts modify exact [];
extern void tail_fade_in(long);
#pragma aux tail_fade_in = "db 0ebh,3bh" parm [eax] aborts modify exact [];
extern void tail_reset(void);
#pragma aux tail_reset = "db 0ebh,3ch" aborts modify exact [];

void run_palette_fade(void);
#pragma aux run_palette_fade aborts modify exact [eax];
void run_palette_fade(void)
{
    return_if_inactive();
    start_fade_in(fade_speed);
    check_input_result(presentation_input());
    if (fade_out_active)
        tail_fade_out(255);

    return_if_finished();
    tail_fade_in(255);
}

void palette_fade_out_entry(long speed);
#pragma aux palette_fade_out_entry aborts modify exact [eax];
void palette_fade_out_entry(long speed)
{
    start_fade_out(speed);
    tail_reset();
}
