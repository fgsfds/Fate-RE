/* Validate a configured map basename and append its extension; no map I/O here. */
extern char main_resource[], selection_names[][20];
extern char selection_terminator[], selection_extension[];
extern signed char selection_scan, selection_current;
extern char *strcpy(char *, const char *), *strcat(char *, const char *);
extern int stricmp(const char *, const char *);

int main_load_selection(char *name)
{
    strcpy(main_resource, name);
    for (selection_scan = 0; (long)selection_scan <= 25; selection_scan++) {
        if (!stricmp(main_resource, selection_names[selection_scan])) goto found;
        if (!stricmp(selection_names[selection_scan], selection_terminator))
            return -1;
    }
    return -1;
found:
    selection_current = selection_scan;
    strcat(main_resource, selection_extension);
    return 0;
}
