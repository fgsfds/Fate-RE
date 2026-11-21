extern char **environment_vector;
/* Parameter order preserves the original stack-to-register forwarding. */
extern int spawn_environment(const char *const *, const char *, int, char **);
#pragma aux spawn_environment "spawnve_" parm [ebx] [edx] [eax] [ecx] modify exact [eax ebx ecx edx];
extern int search_and_spawn(int, const char *, const char *const *, char **);
#pragma aux search_and_spawn modify exact [eax ecx];

int spawn_with_arguments(int, const char *, const char *, ...);
#pragma aux spawn_with_arguments parm caller [] modify exact [eax];
int spawn_with_arguments(int mode, const char *file, const char *first, ...)
{
    /* The variadic stack slots form the null-terminated argument vector. */
    return spawn_environment(&first, file, mode, environment_vector);
}

int spawn_with_path_search(int, const char *, const char *const *);
#pragma aux spawn_with_path_search modify exact [eax];
int spawn_with_path_search(int mode, const char *file, const char *const *arguments)
{
    return search_and_spawn(mode, file, arguments, environment_vector);
}
