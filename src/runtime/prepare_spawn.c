extern void tail_arguments(const char *, const char *const *, char *, int);
#pragma aux tail_arguments "build_command_tail_" parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern int dos_exec(int, const char *, char *, void *, const char *const *);
#pragma aux dos_exec parm caller [] modify exact [eax];
/* Forward EDX to the tail builder before loading its argument vector. */
extern const char *incoming_path(void);
#pragma aux incoming_path = "" value [edx] modify exact [];
extern const char *path_in_esi(const char *);
#pragma aux path_in_esi = parm [esi] value [esi] modify exact [];
extern char *tail_in_edi(char *);
#pragma aux tail_in_edi = parm [edi] value [edi] modify exact [];

int prepare_spawn(int, const char *, char *, void *, const char *const *);
#pragma aux prepare_spawn parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
int prepare_spawn(int mode, const char *path, char *tail, void *environment, const char *const *arguments)
{
    path = path_in_esi(path);
    tail = tail_in_edi(tail);
    tail_arguments(incoming_path(), arguments, tail, 0);
    return dos_exec(mode, path, tail, environment, arguments);
}
