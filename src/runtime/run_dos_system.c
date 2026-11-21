extern const char comspec[], default_shell[], cmd_name[], command_name[];
extern char *getenv(const char *);
#pragma aux getenv modify exact [eax];
extern char *select_shell_switch(char *, int);
#pragma aux select_shell_switch modify exact [eax edx ecx];
extern int spawnlp(int, const char *, const char *, ...);
#pragma aux spawnlp parm caller [] modify exact [eax];

extern void keep_command(const char *);
#pragma aux keep_command = parm [edx] modify exact [];
extern const char *path_in_ecx(const char *);
#pragma aux path_in_ecx = parm [ecx] value [ecx] modify exact [];
extern const char *path_in_ebx(const char *);
#pragma aux path_in_ebx = parm [ebx] value [ebx] modify exact [];
extern unsigned char in_ah(unsigned char);
#pragma aux in_ah = parm [ah] value [ah] modify exact [];
extern unsigned char in_dl(unsigned char);
#pragma aux in_dl = parm [dl] value [dl] modify exact [];
extern const char *name_in_eax(const char *);
#pragma aux name_in_eax = parm [eax] value [eax] modify exact [];

extern const char *saved_command(void);
#pragma aux saved_command = "" value [edx] modify exact [];
extern char *option_in_eax(char *);
#pragma aux option_in_eax = "" parm [eax] value [eax] modify exact [];
extern void clear_switch_argument(unsigned long zero);
#pragma aux clear_switch_argument = "" parm [edx] modify exact [];
extern int switch_argument(void);
#pragma aux switch_argument = "" value [edx] modify exact [];
extern unsigned char last_force(void);
#pragma aux last_force = "" value [dl] modify exact [];
int system(const char *);
#pragma aux system modify exact [eax];
int system(const char *command)
{
    volatile unsigned char force_slash;
    char switch_text[4], *option;
    const char *path, *environment_path;

    keep_command(command);
    environment_path = path_in_ecx(getenv(comspec));
    path = path_in_ebx(environment_path);
    if (!saved_command())
        return 1;
    force_slash = in_ah(0);
    if (!environment_path)
        path = path_in_ebx(default_shell);
    /* Watcom pushes these variadic arguments right to left. Save the command
       before setting up the switch, then reload the flag before selecting argv[0]. */
    return spawnlp(0, path, name_in_eax(last_force() ? cmd_name : command_name),
                   (clear_switch_argument(0), option = option_in_eax(switch_text),
                    in_dl(force_slash), option = select_shell_switch(option, switch_argument()),
                    in_dl(force_slash), option),
                   saved_command(), (char *)0);
}
