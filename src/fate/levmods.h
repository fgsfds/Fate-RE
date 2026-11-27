#ifndef FATE_LEVEL_MODIFICATIONS_H
#define FATE_LEVEL_MODIFICATIONS_H

typedef struct { char text[6]; } Prefix;
extern const Prefix save_copy_prefix, restore_copy_prefix;
extern const char save_extension[], restore_extension[];
extern const char save_mod_extension_and_space[], restore_mod_extension[], restore_space[];
extern const char save_copy_options[], restore_copy_options[];
extern const char save_copy_error[], restore_copy_error[];
extern char error_buffer[];
extern const char level_names[][20];
extern unsigned char modified_levels[];
extern signed char current_level;
extern int read_game_data(int), write_game_data(int);
#pragma aux read_game_data modify exact [eax];
#pragma aux write_game_data modify exact [eax];
extern int format_command(char *, const char *, ...);
#pragma aux format_command "sprintf_" parm caller [] modify exact [eax];
extern char *strcat(char *, const char *);
#pragma aux strcat modify exact [eax];
extern int system(const char *);
#pragma aux system modify exact [eax];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];

#endif
