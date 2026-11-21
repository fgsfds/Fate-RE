extern char **environment_vector;
extern unsigned strlen(const char *);
#pragma intrinsic(strlen);
/* Bind the comparison inputs in the order used by the Watcom runtime. */
extern int compare_name(unsigned, const char *, const char *);
#pragma aux compare_name "strnicmp_" parm [ebx] [edx] [eax] modify exact [eax edx ebx];
extern char **vector_in_esi(char **);
#pragma aux vector_in_esi = parm [esi] value [esi] modify exact [];
extern unsigned length_in_edi(unsigned);
#pragma aux length_in_edi = parm [edi] value [edi] modify exact [];
extern const char *key_in_edi(const char *);
#pragma aux key_in_edi = parm [edi] value [edi] modify exact [];
extern char *entry_in_ecx(char *);
#pragma aux entry_in_ecx = parm [ecx] value [ecx] modify exact [];
extern unsigned offset_in_eax(unsigned);
#pragma aux offset_in_eax = parm [eax] value [eax] modify exact [];

char *getenv(const char *);
#pragma aux getenv modify exact [eax];
char *getenv(const char *name)
{
    char **entries = vector_in_esi(environment_vector);
    char *entry;
    unsigned length;

    if (!entries || !name)
        return 0;
    length = length_in_edi(strlen(key_in_edi(name)));
    goto check_entry;
    do {
        /* Require the separator so a prefix is insufficient. */
        if (!compare_name(length, name, entry) && entry[length] == '=') {
            unsigned offset = offset_in_eax(length + 1);
            return entry + offset;
        }
        entries = vector_in_esi(entries + 1);
check_entry:
        entry = entry_in_ecx(*entries);
    } while (entry);
    return 0;
}
