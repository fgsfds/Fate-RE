/* DOS function 3700h returns the configured switch character in DL. */
extern unsigned char dos_switch_character(void);
#pragma aux dos_switch_character = "push edx" "mov ah,37h" "mov al,0" "int 21h" "mov al,dl" "mov ah,0" "pop edx" value [al] modify exact [eax ecx];
extern void save_option(char *);
#pragma aux save_option = parm [ebx] modify exact [];
extern char *saved_option(void);
#pragma aux saved_option = value [ebx] modify exact [];
extern void release_command_register(void);
#pragma aux release_command_register = modify exact [eax];
extern char *command_result(char *);
#pragma aux command_result = parm [eax] value [eax] modify exact [];
extern unsigned char slash_in_dl(unsigned char);
#pragma aux slash_in_dl = parm [dl] value [dl] modify exact [];
extern char *current_option(void);
#pragma aux current_option = value [eax] modify exact [];
char *select_shell_switch(char *, int);
#pragma aux select_shell_switch modify exact [eax edx ecx];
char *select_shell_switch(char *option, int force_slash)
{
    char *return_option;

    save_option(option);
    if (slash_in_dl((unsigned char)force_slash)) {
        *current_option() = '/';
        release_command_register();
    } else {
        unsigned char value = dos_switch_character();
        *saved_option() = value;
    }
    ((volatile char *)saved_option())[1] = 'c';
    release_command_register();
    return_option = command_result(saved_option());
    saved_option()[2] = 0;
    return return_option;
}
