extern signed char dispatch_actor_enabled[], current_level;
extern unsigned char dispatch_actor_board[];
extern short player_sector;
extern long player_x, player_y, player_z;
extern void update_actor(int actor, int flags, long x, long y, long z, int sector);
#pragma aux update_actor parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];

extern short index_in_si(short);
#pragma aux index_in_si = "" parm [si] value [si] modify exact [];
extern int index_in_eax(int);
#pragma aux index_in_eax = "" parm [eax] value [eax] modify exact [];
extern int actor_number_in_eax(void);
#pragma aux actor_number_in_eax = value [eax] modify exact [];
extern int keep_board_in_ebx(int);
#pragma aux keep_board_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern int keep_level_in_ecx(int);
#pragma aux keep_level_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern void update_board_1_script(void);
#pragma aux update_board_1_script modify exact [eax];
extern void update_board_2_script(void);
#pragma aux update_board_2_script modify exact [eax];
extern void update_board_3_script(void);
#pragma aux update_board_3_script modify exact [eax];
extern void update_board_4_script(void);
#pragma aux update_board_4_script modify exact [eax];
extern void update_board_5_script(void);
#pragma aux update_board_5_script modify exact [eax];
extern void update_board_6_script(void);
#pragma aux update_board_6_script modify exact [eax];
extern void update_board_7_script(void);
#pragma aux update_board_7_script modify exact [eax];
extern void update_board_8_script(void);
#pragma aux update_board_8_script modify exact [eax];
extern void update_board_9_script(void);
#pragma aux update_board_9_script modify exact [eax];
extern void update_board_10_script(void);
#pragma aux update_board_10_script modify exact [eax];
extern void update_board_11_script(void);
#pragma aux update_board_11_script modify exact [eax];
extern void update_board_12_script(void);
#pragma aux update_board_12_script modify exact [eax];
extern void update_board_13_script(void);
#pragma aux update_board_13_script modify exact [eax];
extern void update_board_14_script(void);
#pragma aux update_board_14_script modify exact [eax];
extern void update_board_15_script(void);
#pragma aux update_board_15_script modify exact [eax];
extern void update_board_16_script(void);
#pragma aux update_board_16_script modify exact [eax];
extern void update_board_17_script(void);
#pragma aux update_board_17_script modify exact [eax];
extern void update_board_18_script(void);
#pragma aux update_board_18_script modify exact [eax];
extern void update_board_19_script(void);
#pragma aux update_board_19_script modify exact [eax];
extern void update_board_20_script(void);
#pragma aux update_board_20_script modify exact [eax];
extern void update_board_21_script(void);
#pragma aux update_board_21_script modify exact [eax];
extern void update_board_22_script(void);
#pragma aux update_board_22_script modify exact [eax];
extern void update_board_23_script(void);
#pragma aux update_board_23_script modify exact [eax];
extern void update_board_24_script(void);
#pragma aux update_board_24_script modify exact [eax];
extern void update_board_25_script(void);
#pragma aux update_board_25_script modify exact [eax];

extern void update_board_actors_and_script(void);
#pragma aux update_board_actors_and_script modify exact [eax];

void update_board_actors_and_script(void)
{
    int level;
    short short_slot;
    union { unsigned number; unsigned char low; } split_board;

    short_slot = index_in_si(0);
    goto actor_count;
actor:
    if (keep_board_in_ebx(dispatch_actor_enabled[actor_number_in_eax()]) == -1)
        goto advance;
    /* The actor board is an unsigned byte. Zero its upper bytes before comparing it. */
    split_board.number = keep_board_in_ebx(0);
    level = keep_level_in_ecx(current_level);
    split_board.low = dispatch_actor_board[actor_number_in_eax()];
    if (split_board.number != level)
        goto advance;
    update_actor(actor_number_in_eax(), 0, player_x, player_y, player_z, player_sector);
advance:
    short_slot = index_in_si(short_slot + 1);
actor_count:
    if (index_in_eax(short_slot) <= 500)
        goto actor;

    /* Return after one board script. Invalid board numbers fall through. */
    switch (current_level) {
    case 1: update_board_1_script(); return;
    case 2: update_board_2_script(); return;
    case 3: update_board_3_script(); return;
    case 4: update_board_4_script(); return;
    case 5: update_board_5_script(); return;
    case 6: update_board_6_script(); return;
    case 7: update_board_7_script(); return;
    case 8: update_board_8_script(); return;
    case 9: update_board_9_script(); return;
    case 10: update_board_10_script(); return;
    case 11: update_board_11_script(); return;
    case 12: update_board_12_script(); return;
    case 13: update_board_13_script(); return;
    case 14: update_board_14_script(); return;
    case 15: update_board_15_script(); return;
    case 16: update_board_16_script(); return;
    case 17: update_board_17_script(); return;
    case 18: update_board_18_script(); return;
    case 19: update_board_19_script(); return;
    case 20: update_board_20_script(); return;
    case 21: update_board_21_script(); return;
    case 22: update_board_22_script(); return;
    case 23: update_board_23_script(); return;
    case 24: update_board_24_script(); return;
    case 25: update_board_25_script(); return;
    }
}
