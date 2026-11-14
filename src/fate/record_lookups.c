/* Joint reconstruction of the contiguous GET_ICON / GET_TYPE lookup pair.
 * This packed view starts at the icon-key field, not necessarily at the start
 * of the game's full logical record. Names are provisional.
 */
#pragma pack(push, 1)
typedef struct {
    short icon_key;
    char unknown[18];
    short sprite_type;
    char rest[9];
} RecordLookupView;
#pragma pack(pop)
extern RecordLookupView record_lookup_entries[129];
extern char record_icon_error[], record_type_error[];
extern void record_lookup_error(const char *);

int lookup_record_value(short key)
{
    short i;
    long index;
    for (i = 0; (index = i) <= 128; i++)
        if (record_lookup_entries[index].icon_key == key)
            return record_lookup_entries[index].sprite_type;
    record_lookup_error(record_icon_error);
    return -1;
}

int lookup_type_index(short type)
{
    long index;
    short i;
    for (i = 0; (index = i) <= 128; i++)
        if (record_lookup_entries[index].sprite_type == type)
            return index;
    record_lookup_error(record_type_error);
    return -1;
}
