/* Automatic crush-bank activation and sector-to-record lookup. */
#pragma pack(push, 1)
typedef struct {
    short sector;
    char state[47];
    long automatic, initially_active;
    char remaining[7];
} DispatchCrushEntry;
typedef struct {
    long enabled, count;
    DispatchCrushEntry entries[16];
} DispatchCrushBank;
#pragma pack(pop)
extern DispatchCrushBank dispatch_crush_banks[];
extern long dispatch_crush_silent;
extern char dispatch_invalid_bank[], dispatch_disabled_bank[];
extern char lookup_invalid_bank[], lookup_disabled_bank[];
extern void dispatch_crush_error(const char *);
extern void dispatch_crush_activate(long, short);
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];
extern void activate_crush_sector(long, short);
#pragma aux activate_crush_sector modify exact [eax];
extern long lookup_trigger_sector(long, short);
#pragma aux lookup_trigger_sector "find_crush_sector_" modify exact [eax];
extern short numsectors;
extern const char crusher_index_error[], crusher_inactive_error[];
extern const char crusher_sector_error[], crusher_lookup_error[];

void activate_initial_crushers(long index)
{
    DispatchCrushBank *bank;
    long i;
    if (index < 0 || index >= 25) dispatch_crush_error(dispatch_invalid_bank);
    bank = &dispatch_crush_banks[index];
    if (bank->enabled == 0) dispatch_crush_error(dispatch_disabled_bank);
    for (i = 0; i < bank->count; i++) {
        if (bank->entries[i].automatic == 1 && bank->entries[i].initially_active == 1) {
            dispatch_crush_silent = 1;
            dispatch_crush_activate(index, bank->entries[i].sector);
        }
    }
}

long find_crush_sector(long index, short sector)
{
    DispatchCrushBank *bank;
    long i;
    if (index < 0 || index >= 25) dispatch_crush_error(lookup_invalid_bank);
    bank = &dispatch_crush_banks[index];
    if (bank->enabled == 0) dispatch_crush_error(lookup_disabled_bank);
    for (i = 0; i < bank->count; i++)
        if (bank->entries[i].sector == sector) return i;
    return -1;
}

void trigger_crusher_on_entry(long index, short sector)
{
    DispatchCrushBank *bank;
    long entry;

    if (index < 0 || index >= 25)
        report_game_error(crusher_index_error);
    bank = &dispatch_crush_banks[index];
    if (!bank->enabled)
        report_game_error(crusher_inactive_error);
    if (sector < 0 || sector >= numsectors)
        report_game_error(crusher_sector_error);
    entry = lookup_trigger_sector(index, sector);
    if (entry < 0 || entry >= 16)
        report_game_error(crusher_lookup_error);
    if (bank->entries[entry].automatic != 1)
        activate_crush_sector(index, sector);
}
