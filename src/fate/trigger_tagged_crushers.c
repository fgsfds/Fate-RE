#pragma pack(push, 1)
typedef struct {
    unsigned char prefix[57];
    long mode, latch;
} TaggedCrusher;
typedef struct {
    long enabled, count;
    unsigned char entries[16][64];
} TaggedCrusherBank;
#pragma pack(pop)

extern TaggedCrusherBank tagged_crush_banks[];
extern short numsectors;
extern const char trigger_bad_bank[], trigger_inactive_bank[];
extern const char trigger_bad_sector[], trigger_bad_entry[];
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];
extern long find_crush_sector(long, short);
#pragma aux find_crush_sector modify exact [eax edx];
/* This caller passes the signed sector as a full register. */
extern void activate_crusher_for_sector(long, int);
#pragma aux activate_crusher_for_sector "activate_crush_sector_" modify exact [eax edx];

/* These annotations preserve the original register assignments. */
extern long hold_crusher_mode(long);
#pragma aux hold_crusher_mode = "" parm [esi] value [esi] modify exact [];

extern long hold_tagged_offset(long);
#pragma aux hold_tagged_offset = "" parm [eax] value [eax] modify exact [];
extern int hold_activate_sector(int);
#pragma aux hold_activate_sector = "" parm [edx] value [edx] modify exact [];

void trigger_tagged_crushers(long index, short sector)
{
    TaggedCrusherBank *bank;
    TaggedCrusher *crusher;
    long slot;
    long mode;
    int action_sector;
    if (index < 0 || index >= 25)
        report_game_error(trigger_bad_bank);
    bank = &tagged_crush_banks[index];
    if (!bank->enabled)
        report_game_error(trigger_inactive_bank);
    if (sector < 0 || sector >= numsectors)
        report_game_error(trigger_bad_sector);
    slot = find_crush_sector(index, sector);
    if (slot < 0 || slot >= 16)
        report_game_error(trigger_bad_entry);
    /* The original indexes from the bank header, using the entry stride. */
    crusher = (TaggedCrusher *)((unsigned char *)bank +
                               hold_tagged_offset(slot) * sizeof(bank->entries[0]));
    mode = crusher->mode;
    if (mode != 1) {
        action_sector = hold_activate_sector(sector);
    } else {
        /* Retain the original comparison of the mode with itself. */
        long prior_mode = mode;
        mode = hold_crusher_mode(mode);
        if (prior_mode != mode)
            return;
        if (crusher->latch == mode) {
            crusher->latch = 0;
            return;
        }
        action_sector = hold_activate_sector(sector);
        crusher->latch = mode;
    }
    activate_crusher_for_sector(index, action_sector);
}
