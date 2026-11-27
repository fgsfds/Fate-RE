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

extern const char load_menu_title[], save_names_filename[], save_preview_format[];
extern char save_preview_filename[], save_names[10][17];
extern SaveMenuRow save_menu_records[];
extern MenuRecord *save_slot_menu_rows[];
extern long editing_save_slot;
extern unsigned char save_preview_lock, save_slot_preview_enabled;
extern void *save_preview_pixels;

extern int open(const char *, int, ...);

extern long lseek(int, long, int);
#pragma aux lseek parm [eax] [edx] [ebx] modify exact [eax];
extern int read(int, void *, unsigned);
#pragma aux read parm [eax] [edx] [ebx] modify exact [eax];
extern int close(int);
#pragma aux close parm [eax] modify exact [eax];
extern int sprintf(char *, const char *, ...);
#pragma aux sprintf parm caller [] modify exact [eax];
extern int access(const char *, int);
#pragma aux access parm [eax] [edx] modify exact [eax];
extern void allocache(void **, long, unsigned char *);
#pragma aux allocache parm [eax] [edx] [ebx] modify exact [eax];
extern void read_save_slot_preview(int);
#pragma aux read_save_slot_preview parm [eax] modify exact [eax];
extern void setviewtotile(short, long, long);
#pragma aux setviewtotile parm [eax] [edx] [ebx] modify exact [eax];
extern void setviewback(void);
#pragma aux setviewback modify exact [eax];

extern int row_index_in_edx(int);
#pragma aux row_index_in_edx = parm [edx] value [edx] modify exact [];
extern int save_row_index(void);
#pragma aux save_row_index = value [edx] modify exact [];
extern SaveMenuRow *save_row_in_ebx(SaveMenuRow *);
#pragma aux save_row_in_ebx = parm [ebx] value [ebx] modify exact [];
extern SaveMenuRow *save_row_in_eax(SaveMenuRow *);
#pragma aux save_row_in_eax = parm [eax] value [eax] modify exact [];
extern char *save_name_in_ecx(char *);
#pragma aux save_name_in_ecx = parm [ecx] value [ecx] modify exact [];
extern unsigned name_offset_in_ebx(unsigned);
#pragma aux name_offset_in_ebx = parm [ebx] value [ebx] modify exact [];
extern void keep_name_offset(unsigned);
#pragma aux keep_name_offset = "" parm [ebx] modify exact [ecx];
extern void row_value_in_edx(int);
#pragma aux row_value_in_edx = "" parm [edx] modify exact [];
extern unsigned char preview_flag_in_dl(unsigned char);
#pragma aux preview_flag_in_dl = parm [dl] value [dl] modify exact [];
extern unsigned char preview_flag_in_dh(unsigned char);
#pragma aux preview_flag_in_dh = parm [dh] value [dh] modify exact [];
extern unsigned char lock_in_cl(unsigned char);
#pragma aux lock_in_cl = parm [cl] value [cl] modify exact [];
extern long slot_in_ebx(long);
#pragma aux slot_in_ebx = parm [ebx] value [ebx] modify exact [];
extern long slot_in_ecx(long);
#pragma aux slot_in_ecx = parm [ecx] value [ecx] modify exact [];
extern int keep_slot_before_preview(long, int, long);
#pragma aux keep_slot_before_preview = "" parm [edx] [eax] [ebx] value [eax] modify exact [];
extern int load_result_in_eax(int);
#pragma aux load_result_in_eax = parm [eax] value [eax] modify exact [];

/* Keep the preview buffer and descriptor live around the variadic file open. */
extern int open_load_names(char *, const char *, int);
#pragma aux open_load_names = "call open" "mov ecx,eax" "add esp,8" \
    parm routine [esi] [] value [eax] modify exact [eax ecx esi];
extern int load_handle_in_eax(void);
#pragma aux load_handle_in_eax = value [eax] modify exact [];
extern int load_handle_in_ecx(void);
#pragma aux load_handle_in_ecx = value [ecx] modify exact [];
extern char *load_filename_buffer(void);
#pragma aux load_filename_buffer = value [esi] modify exact [];
extern const char *title_in_ecx(const char *);
#pragma aux title_in_ecx = parm [ecx] value [ecx] modify exact [];
/* Keep the initial preview tile store ahead of the menu arguments. */
extern void finish_load_preview(SaveMenuRow *);
#pragma aux finish_load_preview = "" parm [eax] modify exact [ebx];
extern void stage_load_background(int);
#pragma aux stage_load_background = "" parm [ebx] modify exact [eax];
extern int staged_load_background(void);
#pragma aux staged_load_background = "" value [ebx] modify exact [];
extern void keep_load_order(int, int);
#pragma aux keep_load_order = "" parm [ebx] [eax] modify exact [];

/* The menu consumes its row-table argument from the stack. */
extern int select_load_row(int tile, int slot, int count, MenuRecord **rows);
#pragma aux select_load_row = \
    "mov eax,[eax*4+save_slot_menu_rows]" "movsx ebx,bx" "mov dword ptr [eax+0bh],6000h" \
    "mov eax,offset editing_save_slot" "call run_menu_loop" \
    parm routine [ebx] [eax] [edx] [] value [eax] modify exact [eax ebx ecx edx];
extern int preview_slot_in_eax(int);
#pragma aux preview_slot_in_eax = "" parm [eax] value [eax] modify exact [];
extern long preview_width_in_ebx(long);
#pragma aux preview_width_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern void keep_row_index_after_kind(int);
#pragma aux keep_row_index_after_kind = "" parm [edx] modify exact [ebx];
extern int run_load_game_menu(void);
#pragma aux run_load_game_menu modify exact [eax];

int run_load_game_menu(void)
{
    SaveMenuRow *last, *row;
    char *name, *names_base;
    unsigned offset;
    int slot, result;
    const char *title;
    long width;
    unsigned char enabled, unlocked;

    if (open_load_names(save_preview_filename, save_names_filename, 0x202) != -1) {
        lseek(load_handle_in_eax(), 0, 0);
        read(load_handle_in_ecx(), save_names, sizeof save_names);
        close(load_handle_in_ecx());
    }

    row_value_in_edx(0);
    do {
        save_slot_menu_rows[save_row_index()] = (MenuRecord *)save_row_in_ebx(&save_menu_records[save_row_index()]);
        offset = name_offset_in_ebx(save_row_index() * 16);
        keep_name_offset(offset);
        names_base = save_name_in_ecx((char *)save_names);
        offset = name_offset_in_ebx(offset + save_row_index());
        name = save_name_in_ecx(names_base + offset);
        save_row_in_ebx((SaveMenuRow *)save_slot_menu_rows[save_row_index()])->name = name;
        save_row_in_ebx((SaveMenuRow *)save_slot_menu_rows[save_row_index()])->enabled = 1;
        save_row_in_ebx((SaveMenuRow *)save_slot_menu_rows[save_row_index()])->kind = 6;
        keep_row_index_after_kind(save_row_index());
        row = save_row_in_ebx((SaveMenuRow *)save_slot_menu_rows[row_index_in_edx(save_row_index())]);
        row->current = 0;
        save_row_in_ebx((SaveMenuRow *)save_slot_menu_rows[save_row_index()])->maximum = 0;
        last = save_row_in_eax((SaveMenuRow *)save_slot_menu_rows[save_row_index()]);
        row_value_in_edx(save_row_index() + 1);
        last->marker = 0;
    } while (save_row_index() < 10);

    save_preview_lock = 255;
    if (!save_preview_pixels)
        allocache(&save_preview_pixels, 64000, &save_preview_lock);

    enabled = preview_flag_in_dl(1);
    slot = slot_in_ebx(editing_save_slot);
    save_slot_preview_enabled = enabled;
    if (slot >= 10)
        editing_save_slot = slot_in_ecx(0);

    width = preview_width_in_ebx(320);
    slot = preview_slot_in_eax(editing_save_slot);
    read_save_slot_preview(keep_slot_before_preview(200, slot, width));
    setviewtotile(0xffe, 200, 320);
    setviewback();

    row = save_row_in_eax((SaveMenuRow *)save_slot_menu_rows[editing_save_slot]);
    title = title_in_ecx(load_menu_title);
    row->current = 0xffe;
    finish_load_preview(row);
    stage_load_background(0x83d);
    slot = preview_slot_in_eax(editing_save_slot);
    keep_load_order(staged_load_background(), slot);
    if (select_load_row(staged_load_background(), slot, 10, save_slot_menu_rows)) {
        slot = slot_in_ebx(editing_save_slot);
        sprintf(load_filename_buffer(), save_preview_format, slot);
        result = slot;
        if (access(load_filename_buffer(), 0) == -1)
            result = slot_in_ebx(-1);
    } else {
        result = slot_in_ebx(-1);
    }

    unlocked = lock_in_cl(1);
    enabled = preview_flag_in_dh(0);
    result = load_result_in_eax(result);
    save_slot_preview_enabled = enabled;
    save_preview_lock = unlocked;
    return result;
}
