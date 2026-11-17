/* Advance the active crusher bank and restart completed automatic crushers. */
#pragma pack(push, 1)
typedef struct {
    short sector;
    long ceiling_z, floor_z, open_z, last_shade_z;
    unsigned char visibility;
    signed char shade, darkest_shade;
    long active, direction, shade_interval;
    long speed, acceleration, x, y;
    long automatic, reopen, restart;
    unsigned char reserved[3];
} LevelCrusher;
typedef struct {
    long enabled, count;
    LevelCrusher entries[16];
} LevelCrusherBank;
typedef struct {
    short wall_index, wall_count;
    long ceiling_z;
    unsigned char padding[20];
    signed char floor_shade;
    unsigned char suffix[11];
} LevelCrusherSector;
#pragma pack(pop)

extern const char crusher_update_bad_bank[], crusher_update_disabled[], crusher_update_bad_sector[];
extern LevelCrusherBank update_crusher_banks[];
extern LevelCrusherSector crusher_update_sectors[];
extern long crusher_update_sector_ceiling[];
extern signed char crusher_update_floor_shade[];
extern short numsectors;
extern void report_game_error(const char *);
#pragma aux report_game_error modify exact [eax];
extern int get_animation_goal(long *);
#pragma aux get_animation_goal parm [eax] modify exact [eax];
extern void check_crushed_player(LevelCrusher *, int);
#pragma aux check_crushed_player parm [eax] [edx] modify exact [eax edx];
extern void check_crushed_sprites(LevelCrusher *, int);
#pragma aux check_crushed_sprites parm [eax] [edx] modify exact [eax];
extern void play_crusher_sound(LevelCrusher *, int);
#pragma aux play_crusher_sound parm [eax] [edx] modify exact [eax];
/* Preserve the caller registers and original bank index for the shared return. */
extern int begin_crusher_update(int);
#pragma aux begin_crusher_update = \
    "push ebx" "push ecx" "push edx" "push esi" "push edi" "push ebp" "push eax" \
    parm [eax] value [eax] modify exact [];
extern int saved_crusher_bank_in_edx(void);
#pragma aux saved_crusher_bank_in_edx = "mov edx,[esp]" value [edx] modify exact [edx];
extern void release_crusher_bank(void);
#pragma aux release_crusher_bank = "add esp,4" modify exact [];
extern void restore_crusher_registers(void);
#pragma aux restore_crusher_registers aborts modify exact [];

/* Zero-byte bindings keep the historical register assignments. */
extern int register_eax(int);
#pragma aux register_eax = "" parm [eax] value [eax] modify exact [];
extern int register_edx(int);
#pragma aux register_edx = "" parm [edx] value [edx] modify exact [];
extern int register_ecx(int);
#pragma aux register_ecx = "" parm [ecx] value [ecx] modify exact [];
extern LevelCrusher *crusher_in_ebx(LevelCrusher *);
#pragma aux crusher_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern LevelCrusherBank *bank_in_esi(LevelCrusherBank *);
#pragma aux bank_in_esi = "" parm [esi] value [esi] modify exact [];
extern signed char shade_in_dl(signed char);
#pragma aux shade_in_dl = "" parm [dl] value [dl] modify exact [];
extern signed char shade_in_dh(signed char);
#pragma aux shade_in_dh = "" parm [dh] value [dh] modify exact [];
extern signed char shade_in_ah(signed char);
#pragma aux shade_in_ah = "" parm [ah] value [ah] modify exact [];
extern long absolute_delta(long);
#pragma aux absolute_delta = "test eax,eax" "jns positive" "neg eax" "positive:" \
    parm nomemory [eax] value [eax] modify exact [eax];

extern void load_ceiling_sector(void);
#pragma aux load_ceiling_sector = "movsx ebp,di" modify exact [];
extern void load_crusher_ceiling(LevelCrusher *);
#pragma aux load_crusher_ceiling = "mov ebp,[ebx+2]" parm [ebx] modify exact [];
extern void load_crusher_automatic(LevelCrusher *);
#pragma aux load_crusher_automatic = "mov ebp,[ebx+31h]" parm [ebx] modify exact [];

extern int current_crusher_offset(void);
#pragma aux current_crusher_offset = value [ebp] modify exact [];
extern short current_crusher_di(void);
#pragma aux current_crusher_di = value [di] modify exact [];
extern int current_crusher_sector(void);
#pragma aux current_crusher_sector = value [edi] modify exact [];
extern void extend_crusher_sector(void);
#pragma aux extend_crusher_sector = "movsx edi,di" modify exact [edi];
extern void record_crusher_sector(short);
#pragma aux record_crusher_sector = parm [di] modify exact [];
extern signed char current_crusher_shade(void);
#pragma aux current_crusher_shade = value [dl] modify exact [];
extern int crusher_index(void);
#pragma aux crusher_index = value [ecx] modify exact [];
extern LevelCrusher *current_crusher(void);
#pragma aux current_crusher = value [ebx] modify exact [];
extern LevelCrusherBank *current_crusher_bank(void);
#pragma aux current_crusher_bank = value [esi] modify exact [];
extern int current_counter_edx(void);
#pragma aux current_counter_edx = value [edx] modify exact [];
extern int current_counter_eax(void);
#pragma aux current_counter_eax = value [eax] modify exact [];
extern void activate_crusher_symbol(void);
#pragma aux activate_crusher_symbol "activate_crush_sector_" modify exact [eax edx];
extern void activate_saved_crusher(LevelCrusher *);
#pragma aux activate_saved_crusher = "mov eax,[esp]" "movsx edx,word ptr [ebx]" "call activate_crusher_symbol" parm [ebx] modify exact [eax edx];

extern int crusher_stop_sound(void);
#pragma aux crusher_stop_sound = "xor edx,edx" value [edx] modify exact [edx];
extern void update_level_effects(int);
#pragma aux update_level_effects parm [eax] modify exact [eax ebx ecx edx esi edi];

void update_level_effects(int bank_index)
{
    int direction, sound_mode;
    LevelCrusher *sound_crusher;
    long ceiling, opening, delta;
    signed char shade, minimum;

    bank_index = begin_crusher_update(bank_index);
    if (bank_index < 0 || bank_index >= 25)
        report_game_error(crusher_update_bad_bank);
    bank_in_esi(&update_crusher_banks[saved_crusher_bank_in_edx()]);
    if (!current_crusher_bank()->enabled)
        report_game_error(crusher_update_disabled);

    /* Update active crusher motion, shading, and collision. */
    register_ecx(0);
    goto check_first;
first:
    crusher_in_ebx(&current_crusher_bank()->entries[register_eax(crusher_index())]);
    record_crusher_sector(current_crusher()->sector);
    if (current_crusher_di() < 0 || current_crusher_di() >= numsectors)
        report_game_error(crusher_update_bad_sector);
    if (current_crusher()->active != 1)
        goto advance_first;

    load_ceiling_sector();
    ceiling = register_eax(crusher_update_sector_ceiling[
        (register_eax(current_crusher_offset()) * 4 + current_crusher_offset()) * 2]);
    opening = register_edx(current_crusher()->open_z);
    current_crusher()->ceiling_z = ceiling;
    if (ceiling <= opening)
        goto check_animation;

    ceiling = register_eax(current_crusher()->floor_z);
    load_crusher_ceiling(current_crusher());
    if (ceiling - 1024 == current_crusher_offset())
        goto check_animation;
    delta = absolute_delta(current_crusher_offset() - current_crusher()->last_shade_z);
    if (delta >= current_crusher()->shade_interval) {
        if (current_crusher()->last_shade_z > current_crusher()->ceiling_z) {
            shade = shade_in_dl(current_crusher()->shade - 1);
            current_crusher()->shade = shade;
            minimum = shade_in_dh(current_crusher()->darkest_shade);
            if (shade < minimum)
                current_crusher()->shade = minimum;
        } else {
            shade = shade_in_ah(current_crusher()->shade + 1);
            current_crusher()->shade = shade;
            if (register_eax(shade) > 32)
                current_crusher()->shade = 32;
        }
        current_crusher()->last_shade_z = current_crusher()->ceiling_z;
    }
    /* EBP receives the validated signed-short sector; five times any such
       value fits int. The byte-indexed shade store below scales it by eight. */
    load_ceiling_sector();
    register_eax(current_crusher_offset());
    register_eax(current_counter_eax() * 4);
    register_eax(current_counter_eax() + current_crusher_offset());
    shade_in_dl(current_crusher()->shade);
    crusher_update_floor_shade[current_counter_eax() * 8] = current_crusher_shade();
    direction = register_eax(current_crusher()->direction);
    if (direction == 2) {
        check_crushed_player(current_crusher(), current_crusher_offset());
        check_crushed_sprites(current_crusher(), current_crusher_offset());
    }

check_animation:
    extend_crusher_sector();
    if (get_animation_goal(&crusher_update_sectors[current_crusher_sector()].ceiling_z) >= 0)
        goto advance_first;
    direction = register_eax(current_crusher()->direction);
    current_crusher()->active = 0;
    if (direction == 2) {
        check_crushed_player(current_crusher(), current_crusher_sector());
        check_crushed_sprites(current_crusher(), current_crusher_sector());
        current_crusher()->ceiling_z = current_crusher()->floor_z - 1024;
    }
    sound_crusher = (LevelCrusher *)register_eax((int)current_crusher());
    sound_mode = crusher_stop_sound();
    current_crusher()->direction = 0;
    play_crusher_sound(sound_crusher, sound_mode);

    register_edx(current_crusher()->automatic);
    if (current_counter_edx() == 1 &&
        current_counter_edx() == current_crusher()->reopen) {
        current_crusher()->restart = current_counter_edx();
        goto advance_first;
    }
    load_crusher_automatic(current_crusher());
    if (current_crusher_offset() != 1 || current_crusher()->reopen != 0)
        goto advance_first;
    opening = register_eax(current_crusher()->floor_z);
    ceiling = register_edx(current_crusher()->ceiling_z);
    if (opening - 1024 == ceiling)
        current_crusher()->restart = current_crusher_offset();
advance_first:
    register_ecx(crusher_index() + 1);
check_first:
    if (crusher_index() < current_crusher_bank()->count)
        goto first;

    /* Reactivate queued crushers after the first pass. */
    register_ecx(0);
    goto check_second;
second:
    crusher_in_ebx(&current_crusher_bank()->entries[register_eax(crusher_index())]);
    if (current_crusher()->restart == 1) {
        activate_saved_crusher(current_crusher());
        current_crusher()->restart = 0;
    }
    register_ecx(crusher_index() + 1);
check_second:
    if (crusher_index() < current_crusher_bank()->count)
        goto second;
    release_crusher_bank();
    restore_crusher_registers();
}
