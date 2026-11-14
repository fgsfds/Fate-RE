/* GET_TYPE diagnostic identifies the reverse lookup of a sprite-type value.
 * Field and function names are provisional, not recovered debug symbols.
 */
#pragma pack(push, 1)
typedef struct {
    char unknown[20];
    short type;
    char rest[9];
} TypeRecord;
#pragma pack(pop)
extern TypeRecord type_records[129];
extern char type_lookup_error_text[];
extern void type_lookup_error(const char *);

int lookup_type_index(short type)
{
    long index;
    short i;
    for (i = 0; (index = i) <= 128; i++)
        if (type_records[index].type == type)
            return index;
    type_lookup_error(type_lookup_error_text);
    return -1;
}
