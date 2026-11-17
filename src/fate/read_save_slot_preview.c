#include "dosio.h"

extern unsigned char *save_preview_pixels;
extern unsigned char save_preview_lock;
extern char save_preview_filename[];
extern const char save_preview_format[];
extern int preview_sprintf(char *destination, const char *format, ...);
#pragma aux preview_sprintf "sprintf_" parm caller [] modify exact [eax edx];
extern void *memset(void *, int, unsigned);
#pragma aux memset modify exact [eax ebx edx];
/* Return through the shared epilogue for the menu's five saved registers. */
extern void menu_restore_without_ebp(void);
#pragma aux menu_restore_without_ebp aborts modify exact [];

/* The preview buffer test and the cache lock use separate registers. */
extern unsigned long keep_preview_pixels(unsigned long);
#pragma aux keep_preview_pixels = parm [edx] value [edx] modify exact [];
extern unsigned long keep_preview_lock(unsigned long);
#pragma aux keep_preview_lock = parm [esi] value [esi] modify exact [];

void read_save_slot_preview(int slot)
{
    unsigned long available = keep_preview_pixels((unsigned long)save_preview_pixels);
    char *filename = save_preview_filename;
    unsigned char *pixels;
    int file;

    if (!available) {
        available = keep_preview_lock(save_preview_lock);
        if (available != 255)
            menu_restore_without_ebp();
    }

    pixels = save_preview_pixels;
    preview_sprintf(filename, save_preview_format, slot);
    file = dos_open(filename, 0x202);
    if (file != -1) {
        lseek(file, 0, 0);
        if (!read(file, pixels, 320 * 200U))
            memset(pixels, 0, 320 * 200U);
        close(file);
        menu_restore_without_ebp();
    }
    memset(pixels, 0, 320 * 200U);
    menu_restore_without_ebp();
}
