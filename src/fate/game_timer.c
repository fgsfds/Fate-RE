extern const char timer_init_error[], timer_callback_error[], remove_timer_error[], shutdown_timer_error[];
extern int report_timer_error(const char *);
#pragma aux report_timer_error modify exact [eax];
extern int timer_initialize(int, int);
#pragma aux timer_initialize modify exact [eax edx];
extern int timer_register_callback(int, void (*)(void), int *);
#pragma aux timer_register_callback modify exact [eax ebx edx];
extern int timer_remove_callback(int);
#pragma aux timer_remove_callback modify exact [eax];
extern int timer_shutdown(int);
#pragma aux timer_shutdown modify exact [eax];
extern void advance_timer_clock(void);
extern int timer_callback_handle;
extern short timer_error;

void initialize_game_timer(void)
{
    timer_error = timer_initialize(0xff00, 0);
    if (timer_error)
        report_timer_error(timer_init_error);
    timer_error = timer_register_callback(120, advance_timer_clock, &timer_callback_handle);
    if (timer_error)
        report_timer_error(timer_callback_error);
}

int shutdown_game_timer(void)
{
    int outcome = timer_remove_callback(timer_callback_handle);
    if (outcome)
        report_timer_error(remove_timer_error);
    outcome = timer_shutdown(0);
    if (outcome)
        return report_timer_error(shutdown_timer_error);
    return outcome;
}
