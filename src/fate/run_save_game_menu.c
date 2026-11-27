#include "menucall.h"
#pragma pack(push, 1)
typedef struct {
    unsigned char enabled;
    short kind;
    char *name;
    long current, maximum, reserved;
    short marker;
} SaveMenuRow;
#pragma pack(pop)

extern const char save_menu_title[], save_names_filename[], save_names_open_error[];
extern char save_names[10][17];
extern SaveMenuRow save_menu_records[];
extern MenuRecord *save_slot_menu_rows[];
extern long editing_save_slot;
extern unsigned char save_preview_lock;
extern void *save_preview_pixels;

extern int open(const char *, int, ...);
extern long lseek(int, long, int);
#pragma aux lseek parm [eax] [edx] [ebx] modify exact [eax];
extern int read(int, void *, unsigned);
#pragma aux read parm [eax] [edx] [ebx] modify exact [eax];
extern int write(int, const void *, unsigned);
#pragma aux write parm [eax] [edx] [ebx] modify exact [eax];
extern int close(int);
#pragma aux close parm [eax] modify exact [eax];
extern void report_game_error(const char *);
#pragma aux report_game_error parm [eax] modify exact [eax];
extern void allocache(void **, long, unsigned char *);
#pragma aux allocache parm [eax] [edx] [ebx] modify exact [eax];
extern void render_save_slot_preview(int);
#pragma aux render_save_slot_preview parm [eax] modify exact [eax];
extern int edit_save_slot_name(int, const char *);
#pragma aux edit_save_slot_name parm [eax] [edx] modify exact [eax edx];
extern void write_save_slot_preview(int);
#pragma aux write_save_slot_preview parm [eax] modify exact [eax];

/* Watcom pushes the three open arguments. The wrapper copies the result before cleaning up. */
extern int open_save_name_file(int, const char *, int, int);
#pragma aux open_save_name_file = "call open" "mov esi,eax" "add esp,12" "mov edi,eax" \
    parm routine [ecx] [] value [eax] modify exact [eax ecx esi edi];
extern int read_file_in_esi(void);
#pragma aux read_file_in_esi = value [esi] modify exact [];
extern int write_file_in_edi(void);
#pragma aux write_file_in_edi = value [edi] modify exact [];
extern int file_in_eax(void);
#pragma aux file_in_eax = value [eax] modify exact [];

extern int save_row_index(void);
#pragma aux save_row_index = value [edx] modify exact [];
extern SaveMenuRow *save_row_in_ebx(SaveMenuRow *);
#pragma aux save_row_in_ebx = parm [ebx] value [ebx] modify exact [];
extern SaveMenuRow *save_row_in_eax(SaveMenuRow *);
#pragma aux save_row_in_eax = parm [eax] value [eax] modify exact [];

extern int menu_running(void);
#pragma aux menu_running = value [ecx] modify exact [];

/* Stage the tile before Watcom pushes the menu's row table. */
extern void stage_save_tile(int);
#pragma aux stage_save_tile = "" parm [esi] modify exact [];
extern int staged_save_tile(void);
#pragma aux staged_save_tile = "" value [esi] modify exact [];
extern int poll_save_menu(int tile, int count, const char *title, MenuRecord **rows);
#pragma aux poll_save_menu = \
    "movsx esi,si" "mov eax,offset editing_save_slot" "mov ebx,esi" \
    "call run_menu_loop" \
    parm routine [esi] [edx] [ecx] [] value [eax] modify exact [eax ebx ecx edx esi];
extern long save_slot_index_in_esi(long);
#pragma aux save_slot_index_in_esi = parm [esi] value [esi] modify exact [];
extern char *save_name_in_esi(char *);
#pragma aux save_name_in_esi = parm [esi] value [esi] modify exact [];
extern unsigned name_offset_in_ebx(unsigned);
#pragma aux name_offset_in_ebx = parm [ebx] value [ebx] modify exact [];
/* Keep the scaled row offset live before loading the name buffer base. */
extern void keep_name_offset(unsigned);
#pragma aux keep_name_offset = "" parm [ebx] modify exact [esi];
extern void row_value_in_edx(int);
#pragma aux row_value_in_edx = "" parm [edx] modify exact [];
extern void menu_value_in_ecx(int);
#pragma aux menu_value_in_ecx = "" parm [ecx] modify exact [];
extern int save_menu_background(void);
#pragma aux save_menu_background = value [esi] modify exact [];
extern unsigned char unlock_in_dl(unsigned char);
#pragma aux unlock_in_dl = parm [dl] value [dl] modify exact [];
extern int finish_save_game_menu(int);
#pragma aux finish_save_game_menu aborts parm [eax] modify exact [eax];

extern int run_save_game_menu(void);
#pragma aux run_save_game_menu modify exact [eax];

int run_save_game_menu(void)
{
    SaveMenuRow *last;
    char *name, *names_base;
    unsigned offset;
    int selected;

    if (open_save_name_file(1, save_names_filename, 0x222, 0x180) != -1) {
        lseek(file_in_eax(), 0, 0);
        read(read_file_in_esi(), save_names, sizeof save_names);
    } else {
        report_game_error(save_names_open_error);
    }

    row_value_in_edx(0);
    do {
        save_slot_menu_rows[save_row_index()] = (MenuRecord *)save_row_in_ebx(&save_menu_records[save_row_index()]);
        offset = name_offset_in_ebx(save_row_index() * 16);
        keep_name_offset(offset);
        names_base = save_name_in_esi((char *)save_names);
        offset = name_offset_in_ebx(offset + save_row_index());
        name = save_name_in_esi(names_base + offset);
        save_row_in_ebx((SaveMenuRow *)save_slot_menu_rows[save_row_index()])->name = name;
        save_row_in_ebx((SaveMenuRow *)save_slot_menu_rows[save_row_index()])->enabled = 1;
        save_row_in_ebx((SaveMenuRow *)save_slot_menu_rows[save_row_index()])->kind = 6;
        save_row_in_ebx((SaveMenuRow *)save_slot_menu_rows[save_row_index()])->current = 0;
        save_row_in_ebx((SaveMenuRow *)save_slot_menu_rows[save_row_index()])->maximum = 0;
        last = save_row_in_eax((SaveMenuRow *)save_slot_menu_rows[save_row_index()]);
        row_value_in_edx(save_row_index() + 1);
        last->marker = 0;
    } while (save_row_index() < 10);

    save_preview_lock = 255;
    if (!save_preview_pixels)
        allocache(&save_preview_pixels, 64000, &save_preview_lock);

    render_save_slot_preview((short)editing_save_slot);
    if (editing_save_slot >= 10)
        editing_save_slot = save_slot_index_in_esi(0);
    while (menu_running()) {
        stage_save_tile(0x83d);
        selected = poll_save_menu(staged_save_tile(), 10, save_menu_title, save_slot_menu_rows);
        menu_value_in_ecx(selected);
        if (!selected)
            continue;
        if (edit_save_slot_name(save_menu_background(), save_menu_title)) {
            lseek(write_file_in_edi(), 0, 0);
            write(write_file_in_edi(), save_names, sizeof save_names);
            write_save_slot_preview(editing_save_slot);
        }
        menu_value_in_ecx(0);
    }
    close(write_file_in_edi());
    save_preview_lock = unlock_in_dl(1);
    return finish_save_game_menu(menu_running());
}
