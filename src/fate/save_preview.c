#include "dosio.h"

extern long presentation_width, presentation_height;
extern unsigned char *save_preview_pixels;
extern unsigned char save_preview_lock;
extern char save_preview_filename[];
extern const char save_preview_format[];
extern int preview_sprintf(char *destination, const char *format, ...);
#pragma aux preview_sprintf "sprintf_" parm caller [] modify exact [eax edx];
extern void rotatesprite(long, long, long, short, short, signed char, unsigned char,
                         unsigned char, long, long, long, long);

void draw_save_slot_preview(void)
{
    if (save_preview_pixels)
        rotatesprite(14L << 16, 24L << 16, 28000, 512, 4094, 0, 0, 22,
                     0, 0, presentation_width - 1, presentation_height - 1);
}

void write_save_slot_preview(int slot)
{
    unsigned long available = (unsigned long)save_preview_pixels;
    char *filename = save_preview_filename;
    int file;

    if (!available) {
        available = save_preview_lock;
        if (available != 255)
            return;
    }

    preview_sprintf(filename, save_preview_format, slot);
    file = dos_open(filename, 0x222, 0x180);
    if (file != -1) {
        lseek(file, 0, 0);
        write(file, save_preview_pixels, 320 * 200U);
        close(file);
    }
}
