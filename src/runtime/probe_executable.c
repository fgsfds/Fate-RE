typedef struct DosFindResult {
    unsigned char bytes[44]; /* DOS DTA plus the original stack alignment byte. */
} DosFindResult;

/* Keep the original argument setup for the DOS find-first entry. */
extern unsigned find_with_attributes(const char *, DosFindResult *, unsigned);
#pragma aux find_with_attributes "dos_find_first_" parm [eax] [ebx] [edx] modify exact [eax ebx edx];

int probe_executable(const char *);
#pragma aux probe_executable modify exact [eax];
int probe_executable(const char *path)
{
    DosFindResult result;
    return find_with_attributes(path, &result, 7) == 0;
}
