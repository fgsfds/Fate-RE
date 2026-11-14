/* Main dispatcher and its preceding helper share the original return epilogue. */
extern long dispatch_mode, dispatch_active, dispatch_play;
extern void dispatch_set(long), dispatch_prepare(void);
extern long dispatch_poll(void), dispatch_command(void);
extern void game_loop(void);

long dispatch_menu(void)
{
    long state;
    dispatch_set(255);
    for (state = 0; ; ) {
        switch (state) {
        case 0:
            dispatch_prepare();
        case 1:
            if (dispatch_poll()) return 1;
            state++;
            break;
        default:
            state = 0;
        }
    }
}

void main_step_d(void)
{
    long state = 2;
    dispatch_mode = 1;
    dispatch_active = 1;
    while (dispatch_active) {
        switch (state) {
        case 0:
            state = dispatch_command();
            if (state != 1) state = 2;
            break;
        case 1:
            dispatch_play = 1;
            game_loop();
            state = 0;
            break;
        default:
            dispatch_menu();
            state = 0;
        }
    }
}
