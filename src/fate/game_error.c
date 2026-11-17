extern void shutdown_game(void);
#pragma aux shutdown_game modify exact [eax];
extern void log_game_message(const char *, ...);
#pragma aux log_game_message "printf_" parm caller [] modify exact [eax];
extern void exit_after_error(int);
#pragma aux exit_after_error "exit_" modify exact [eax];
extern const char error_newline[];
void report_game_error(const char *message)
{
    shutdown_game();
    log_game_message(message);
    log_game_message(error_newline);
    exit_after_error(0);
}
