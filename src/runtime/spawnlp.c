/* Match the original order when forwarding stack arguments to registers. */
extern int spawn_search(const char *const *, const char *, int);
#pragma aux spawn_search "spawn_with_path_search_" parm [ebx] [edx] [eax] modify exact [eax ebx edx];

int spawnlp(int, const char *, const char *, ...);
#pragma aux spawnlp parm caller [] modify exact [eax];
int spawnlp(int mode, const char *file, const char *first, ...)
{
    /* The remaining Watcom stack slots follow the first argument. */
    return spawn_search(&first, file, mode);
}
