/* Provisional names and record layout inferred from the original lookup helper. */
#pragma pack(push, 1)
typedef struct {
    short key;
    char unknown[18];
    short value;
    char rest[9];
} LookupRecord;
#pragma pack(pop)
extern LookupRecord lookup_records[129];
extern char lookup_error_text[];
extern void lookup_error(const char *);

int lookup_record_value(short key)
{
    short i;
    long index;
    for (i = 0; (index = i) <= 128; i++)
        if (lookup_records[index].key == key)
            return lookup_records[index].value;
    lookup_error(lookup_error_text);
    return -1;
}
