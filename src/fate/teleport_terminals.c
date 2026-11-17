extern signed char current_level;
extern char terminal_y[];
extern long terminal_x, terminal_destination_x, terminal_destination_y;
extern unsigned char terminal_destination_level, destination_level, terminal_special_case;
extern short terminal_destination_entry, destination_entry;
extern short terminal_projectiles[], projectile_count, moving_sprite_count, float_sprite_count;
extern short active_sequence_count;
extern long player_x, player_y, destination_x, destination_y;
extern long status_right_tenths, terminal_special_counter;
extern char terminal_table_error[];

extern long absolute_long(long);
extern void remove_engine_sprite(int), apply_terminal_special_case(void);
extern void report_game_error(const char *);
#pragma aux report_game_error parm [eax] modify exact [eax];

/* The original loop retains its table index and special-case status across calls. */
extern void begin_terminal_scan(int);
#pragma aux begin_terminal_scan = "push ebx" "push ecx" "push edx" "push esi" "push edi" \
    "push ebp" "mov ebp,100" parm [ebx] modify exact [];
extern void end_terminal_scan(void);
#pragma aux end_terminal_scan = "pop ebp" "pop edi" "pop esi" "pop edx" "pop ecx" "pop ebx" modify exact [];
extern long terminal_location(void);
#pragma aux terminal_location = \
    "movsx ecx,byte ptr [current_level]" "mov eax,ecx" "shl eax,3" "add ecx,eax" \
    "mov eax,edx" "shl eax,2" "sub eax,edx" "shl ecx,4" "shl eax,3" "add eax,ecx" \
    "mov edx,[eax+terminal_x]" value [edx] modify exact [eax ecx edx];
extern void prepare_terminal_destination(void);
#pragma aux prepare_terminal_destination = \
    "movsx ecx,byte ptr [current_level]" "movsx esi,bx" "mov edi,ecx" "mov eax,esi" \
    "shl edi,3" "shl eax,2" "add edi,ecx" "sub eax,esi" "shl edi,4" modify exact [eax ecx esi edi];
extern void save_terminal_destination(void);
#pragma aux save_terminal_destination = \
    "mov edx,[edi+eax*8+terminal_destination_x]" "mov [destination_x],edx" \
    "mov edx,[edi+eax*8+terminal_destination_y]" "mov [destination_y],edx" \
    "mov dl,[edi+eax*8+terminal_destination_level]" "mov ax,[edi+eax*8+terminal_destination_entry]" \
    "mov [destination_level],dl" "mov [destination_entry],ax" modify exact [eax edx];
extern int terminal_level_in_ecx(void);
#pragma aux terminal_level_in_ecx = value [ecx] modify exact [];
extern int terminal_index_in_esi(void);
#pragma aux terminal_index_in_esi = value [esi] modify exact [];

extern int index_in_eax(int);
#pragma aux index_in_eax = "" parm [eax] value [eax] modify exact [];
extern int number_in_edx(int);
#pragma aux number_in_edx = "" parm [edx] value [edx] modify exact [];
extern short index_in_bx(short);
#pragma aux index_in_bx = "" parm [bx] value [bx] modify exact [];
extern long number_in_edi(long);
#pragma aux number_in_edi = "" parm [edi] value [edi] modify exact [];
extern long number_in_esi(long);
#pragma aux number_in_esi = "" parm [esi] value [esi] modify exact [];
extern long read_saved_status(void);
#pragma aux read_saved_status = value [ebp] modify exact [];
extern long zero_in_eax(long);
#pragma aux zero_in_eax = "" parm [eax] value [eax] modify exact [];
#pragma aux absolute_long parm [eax] modify exact [eax];

#pragma aux apply_terminal_special_case modify exact [eax];
extern int incoming_ebx(void);
#pragma aux incoming_ebx = "" value [ebx] modify exact [];
extern long terminal_x_in_edx(void);
#pragma aux terminal_x_in_edx = value [edx] modify exact [];
extern long terminal_y_after_load(long);
#pragma aux terminal_y_after_load = parm [ecx] value [ecx] modify exact [];
extern unsigned terminal_row_offset(void);
#pragma aux terminal_row_offset = value [eax] modify exact [];

extern short projectile_cursor_in_dx(short);
#pragma aux projectile_cursor_in_dx = parm [dx] value [dx] modify exact [];
#pragma aux remove_engine_sprite parm [eax] modify exact [eax];
extern void check_teleport_terminals(void);
#pragma aux check_teleport_terminals modify exact [eax ebx ecx edx esi edi];

void check_teleport_terminals(void)
{
    int effects, floating, moving;
    short terminal, projectile;
    long zero, terminal_y_position, player_x_position;

    begin_terminal_scan(incoming_ebx());
    terminal = index_in_bx(0);
    goto count;
check_terminal:
    /* A level's terminal list ends at the first record with X equal to -1. */
    if (terminal_location() == -1)
        goto done;
    player_x_position = number_in_esi(player_x);
    terminal_y_position = terminal_y_after_load(*(const long *)(terminal_y + terminal_row_offset()));
    if (absolute_long((long)((unsigned long)terminal_x_in_edx() -
                             (unsigned long)player_x_position)) >= 256 ||
        absolute_long((long)((unsigned long)terminal_y_position -
                             (unsigned long)number_in_edi(player_y))) >= 256)
        goto advance;
    /* The active projectile list starts at slot one. */
    projectile = projectile_cursor_in_dx(1);
    goto projectiles;
remove_projectile:
    remove_engine_sprite(index_in_eax(terminal_projectiles[index_in_eax(projectile)]));
    projectile = projectile_cursor_in_dx(projectile + 1);
projectiles:
    if (projectile <= projectile_count)
        goto remove_projectile;

    /* Reset the projectile list even when another active sprite prevents a teleport. */
    moving = number_in_edx(moving_sprite_count);
    floating = index_in_eax(float_sprite_count);
    zero = number_in_esi(0);
    moving = number_in_edx(moving + floating);
    effects = index_in_eax(active_sequence_count);
    projectile_count = (short)zero;
    if (effects + moving)
        goto advance;
    prepare_terminal_destination();
    save_terminal_destination();
    if (terminal_level_in_ecx() != 5 || terminal_index_in_esi() != 1)
        goto advance;
    terminal_special_case = 1;
    zero = zero_in_eax(0);
    status_right_tenths = read_saved_status();
    terminal_special_counter = zero;
    apply_terminal_special_case();
advance:
    terminal = index_in_bx(terminal + 1);
count:
    if (number_in_edx(terminal) < 5)
        goto check_terminal;
    report_game_error(terminal_table_error);
done:
    end_terminal_scan();
}
