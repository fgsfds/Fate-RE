extern long fade_out_active, fade_speed;

extern void start_fade_in(long);
#pragma aux start_fade_in modify exact [eax];
extern void start_fade_out(long);
#pragma aux start_fade_out modify exact [eax];
extern void presentation_reset(void);
#pragma aux presentation_reset modify exact [eax];

/* Continue through the existing palette fade loop after setup. */
extern void run_palette_fade(void);
#pragma aux run_palette_fade aborts modify exact [eax];
extern void check_palette_fade_input(void);
#pragma aux check_palette_fade_input aborts modify exact [eax];

void palette_fade_in_entry(long speed)
{
    start_fade_in(speed);
    presentation_reset();
    if (!fade_out_active)
        run_palette_fade();
    start_fade_out(fade_speed);
    check_palette_fade_input();
}
