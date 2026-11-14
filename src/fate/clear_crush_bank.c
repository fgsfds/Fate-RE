/* Fields not yet semantically identified remain numbered state values. */
#pragma pack(push, 1)
typedef struct {
    short sector;
    long ceiling_z, floor_z, from_ceiling_z, to_ceiling_z;
    unsigned char visibility;
    signed char initial_shade, shade;
    long state[10];
    char reserved[3];
} CrushEntry;
typedef struct { long enabled, count; CrushEntry entries[16]; } CrushBank;
#pragma pack(pop)
extern CrushBank crush_banks[];
extern char crush_invalid_bank_text[];
extern void crush_report_error(const char *);

void clear_crush_bank(long index)
{
    CrushBank *bank;
    long i;
    if (index < 0 || index >= 25)
        crush_report_error(crush_invalid_bank_text);
    bank = &crush_banks[index];
    for (i = 0; i < 16; i++) {
        bank->entries[i].sector = 0;
        bank->entries[i].ceiling_z = 0;
        bank->entries[i].from_ceiling_z = 0;
        bank->entries[i].to_ceiling_z = 0;
        bank->entries[i].floor_z = 0;
        bank->entries[i].visibility = 0;
        bank->entries[i].initial_shade = 0;
        bank->entries[i].shade = 0;
        bank->entries[i].state[2] = 0;
        bank->entries[i].state[0] = 0;
        bank->entries[i].state[1] = 0;
        bank->entries[i].state[3] = 0;
        bank->entries[i].state[4] = 0;
        bank->entries[i].state[5] = 0;
        bank->entries[i].state[6] = 0;
        bank->entries[i].state[7] = 0;
        bank->entries[i].state[8] = 0;
        bank->entries[i].state[9] = 0;
    }
    bank->count = 0;
}
