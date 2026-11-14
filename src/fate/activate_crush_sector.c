/* Crush-sector activation reconstructed to exact original code and relocations. */
#pragma pack(push, 1)
typedef struct {
    short sector;
    long ceiling_z, floor_z, from_ceiling_z, to_ceiling_z;
    unsigned char visibility;
    signed char initial_shade, shade;
    long state[10];
    char reserved[3];
} ActivateCrushEntry;
typedef struct { long enabled, count; ActivateCrushEntry entries[16]; } ActivateCrushBank;
typedef struct { short wallptr,wallnum; long ceiling_z,floor_z; char rest[28]; } ActivateCrushSector;
#pragma pack(pop)
extern ActivateCrushBank activate_crush_banks[];
extern ActivateCrushSector activate_crush_sectors[];
extern short activate_crush_numsectors;
extern long activate_crush_goals[],activate_crush_velocity[],activate_crush_silent;
extern char activate_bad_bank[],activate_disabled[],activate_bad_sector[],activate_bad_slot[];
extern void activate_crush_error(const char *);
extern long activate_crush_lookup(long,short);
extern long activate_find_animation(long *);
extern long activate_set_animation(long *,long,long,long);
extern void activate_crush_sound(ActivateCrushEntry *,long);

void activate_crush_sector(long index,short sector)
{
    ActivateCrushBank *bank;
    ActivateCrushEntry *entry;
    long slot,goal,animation,acceleration;
    if(index<0 || index>=25) activate_crush_error(activate_bad_bank);
    bank=&activate_crush_banks[index];
    if(bank->enabled==0) activate_crush_error(activate_disabled);
    if(sector<0 || sector>=activate_crush_numsectors) activate_crush_error(activate_bad_sector);
    slot=activate_crush_lookup(index,sector);
    if(slot<0 || slot>=16) activate_crush_error(activate_bad_slot);
    entry=&bank->entries[slot];
    animation=activate_find_animation(&activate_crush_sectors[sector].ceiling_z);
    if(animation>=0) {
        if(activate_crush_goals[animation]==activate_crush_sectors[sector].floor_z-1024)
            activate_crush_goals[animation]=entry->from_ceiling_z;
        else activate_crush_goals[animation]=activate_crush_sectors[sector].floor_z-1024;
        activate_crush_velocity[animation]=0;
        activate_crush_sound(entry,1);
        entry->state[0]=1;
    } else {
        goal=entry->floor_z-1024;
        if(goal==entry->ceiling_z) {
            goal=entry->from_ceiling_z;
            entry->state[1]=1;
        } else entry->state[1]=2;
        acceleration=entry->state[4];
        animation=activate_set_animation(&activate_crush_sectors[sector].ceiling_z,goal,
                                        entry->state[3],acceleration);
        if(animation>=0) {
            entry->state[0]=1;
            if(activate_crush_silent==0) activate_crush_sound(entry,1);
        }
    }
}
