/* Checked compiler contexts share the complete VESA algorithm. The default
 * supplies mode/framebuffer/page phases; VESA_PREDICATE_CONTEXT also supplies
 * widened predicates and BIOS argument/PM lookup phases. Private BIOS inputs
 * are initialized here, while unproven original calls remain assembly. */
#include "dpmiregs.h"

#pragma pack(push, 1)
typedef struct {
    char signature[4];
    unsigned short version;
    unsigned long oem_string, capabilities, mode_list;
    unsigned char remaining[512 - 18];
} VesaController;

typedef struct {
    unsigned short attributes;
    unsigned char window_a_attributes, window_b_attributes;
    unsigned short window_granularity, window_size;
    unsigned short window_a_segment, window_b_segment;
    unsigned long window_function;
    short pitch, width, height;
    unsigned char char_width, char_height, planes, bits_per_pixel;
    unsigned char banks, memory_model, bank_size, additional_pages;
    unsigned char color_fields[10];
    unsigned long physical_address;
    unsigned char remaining[256 - 44];
} VesaMode;

typedef struct {
    long quotient, remainder;
} PageDivision;

typedef struct {
    VesaMode mode;
    BiosRegisters bios;
    unsigned char bios_padding[2];
    union {
        DpmiSegments segments;
        struct {
            unsigned char padding[8];
            PageDivision division;
        } page;
    } tail;
} VesaFrame;

typedef union {
    void __far *pointer;
    struct {
        unsigned long offset;
        unsigned short selector;
    } address;
} VesaFarPointer;

typedef struct {
    unsigned short remainder, quotient;
} VesaPageOffset;
#pragma pack(pop)

typedef char VesaFrameSizeCheck[sizeof(VesaFrame) == 0x120 ? 1 : -1];
typedef void (*VesaEntry)(void);

extern const char vesa_request_signature[], vesa_reply_signature[];
extern const char vesa_not_supported_message[], vesa_mode_not_found_message[];
extern VesaController vesa_controller_info;
extern unsigned char vesa_probe_attempted;
extern short vesa_mode_list[];
extern VesaEntry vesa_pm_set_window, vesa_pm_set_display_start;
extern unsigned long mapped_video_base, video_page_size, framebuffer_offset;
extern unsigned short framebuffer_selector;
extern long video_width, video_height, video_pitch, video_page_count;
extern long skip_bank_switch, linear_framebuffer_enabled, use_software_framebuffer;
extern unsigned bank_shift;
extern void *software_framebuffer, *draw_page_address, *linear_page_addresses[];
extern VesaPageOffset page_offsets[];

extern int printf(const char *, ...);
#pragma aux printf parm caller [] modify exact [eax];
extern void runtime_exit(int);
#pragma aux runtime_exit modify exact [eax];
extern char *strncpy(char *, const char *, unsigned);
#pragma aux strncpy modify exact [eax ebx edx];
extern int strncmp(const char *, const char *, unsigned);
#pragma aux strncmp modify exact [eax ebx edx];
extern int get_vesa_mode_info(BiosRegisters *, void *, unsigned);
#pragma aux get_vesa_mode_info modify exact [eax ebx edx];
/* The callee consumes AX. Pass the sign-extended mode that was just tested. */
extern int query_vesa_mode_from_ax(int, unsigned short *);
#pragma aux query_vesa_mode_from_ax "query_vesa_mode_" parm [eax] [edx] modify exact [eax edx];
extern int dpmi_real_mode_interrupt(int, const BiosRegisters *, BiosRegisters *);
#pragma aux dpmi_real_mode_interrupt parm routine [eax] [edx] [ebx] modify exact [eax ebx edx];
extern int dpmi_real_mode_far_call(int, const BiosRegisters *, BiosRegisters *, DpmiSegments *);
#pragma aux dpmi_real_mode_far_call parm routine [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void __far *map_video_memory(unsigned long);
#pragma aux map_video_memory parm [eax] value [dx eax] modify exact [eax edx];
extern PageDivision *divide_vesa_offset(long, long, PageDivision *);
#pragma aux divide_vesa_offset parm routine [eax] [edx] [esi] value [eax] modify exact [eax edx esi];

extern long width_in_esi(long);
#pragma aux width_in_esi = parm [esi] value [esi] modify exact [];
extern long height_in_edi(long);
#pragma aux height_in_edi = parm [edi] value [edi] modify exact [];

#ifdef VESA_PREDICATE_CONTEXT
#define VESA_INIT_CONTEXT vesa_init_predicate_context
/* Compare zero-extended BIOS and mode words in the ABI's result register. */
extern unsigned vesa_value_in_eax(unsigned);
#pragma aux vesa_value_in_eax = parm [eax] value [eax] modify exact [];

/* Keep the table base available across both entry-offset reads. */
extern unsigned vesa_value_in_ebx(unsigned);
#pragma aux vesa_value_in_ebx = parm [ebx] value [ebx] modify exact [];

#pragma aux vesa_init_predicate_context parm routine [eax] [edx] modify exact [eax edx];

#else
#define VESA_INIT_CONTEXT initialize_vesa_mode
#define vesa_value_in_eax(value) (value)
#define vesa_value_in_ebx(value) (value)
#pragma aux initialize_vesa_mode parm routine [eax] [edx] modify exact [eax edx];
#endif

void VESA_INIT_CONTEXT(long, long);

void VESA_INIT_CONTEXT(long requested_width, long requested_height)
{
    VesaFrame frame;
    short *mode;
    int mode_number;
    unsigned long page_address;
    long page, page_count;
    VesaFarPointer mapping;
    long width = width_in_esi(requested_width);
    long height = height_in_edi(requested_height);

    if (!vesa_probe_attempted) {
        const short *source_modes;
        short *destination_modes;
        unsigned long far_list;

        vesa_probe_attempted = 1;
        strncpy(vesa_controller_info.signature, vesa_request_signature, 4);
        frame.bios.ax = 0x4f00;
        frame.bios.bx = frame.bios.cx = frame.bios.dx = 0;
        frame.bios.si = frame.bios.di = 0;
        get_vesa_mode_info(&frame.bios, &vesa_controller_info, 512);
        if (vesa_value_in_eax(frame.bios.ax) != 0x004f ||
            strncmp(vesa_controller_info.signature, vesa_reply_signature, 4) != 0) {
            printf(vesa_not_supported_message);
            return;
        }
        far_list = vesa_controller_info.mode_list;
        source_modes = (const short *)(((far_list & 0xffff0000UL) >> 12) +
                                      (far_list & 0xffffUL));
        destination_modes = vesa_mode_list;
        while (*source_modes != -1)
            *destination_modes++ = *source_modes++;
        *destination_modes = -1;
    }

    video_width = width;
    video_height = height;
    mode = vesa_mode_list;
    goto check_mode;
    do {
        if (!query_vesa_mode_from_ax(mode_number, &frame.mode.attributes) ||
            vesa_value_in_eax(frame.mode.memory_model) != 4 || vesa_value_in_eax(frame.mode.bits_per_pixel) != 8 ||
            vesa_value_in_eax(frame.mode.planes) != 1 || frame.mode.width != width ||
            frame.mode.height != height)
            goto next_mode;
        video_pitch = frame.mode.pitch;
        page_count = frame.mode.additional_pages + 1;
        if (page_count >= 64)
            page_count = 64;
        video_page_count = page_count;

        frame.bios.ax = 0x4f02;
        frame.bios.bx = (unsigned short)*mode | ((frame.mode.attributes & 0x80) << 7);
        /* Define all input words the DPMI wrapper reads in this C context. */
        frame.bios.cx = frame.bios.dx = frame.bios.si = frame.bios.di = 0;
        dpmi_real_mode_interrupt(0x10, &frame.bios, &frame.bios);
        frame.bios.ax = 0x4f0a;
        frame.bios.bx = frame.bios.cx = frame.bios.dx = 0;
        frame.tail.segments.es = frame.tail.segments.ds = 0;
        dpmi_real_mode_far_call(0x10, &frame.bios, &frame.bios, &frame.tail.segments);
        if (vesa_value_in_eax(frame.bios.ax) == 0x004f) {
            unsigned long table_address = vesa_value_in_ebx(
                ((unsigned long)vesa_value_in_eax(frame.tail.segments.es) << 4)
                + vesa_value_in_ebx(frame.bios.di));
            const short *table = (const short *)table_address;
            vesa_pm_set_window = (VesaEntry)vesa_value_in_eax(
                table_address + vesa_value_in_eax((unsigned long)(long)table[0]));
            vesa_pm_set_display_start = (VesaEntry)vesa_value_in_eax(
                table_address + vesa_value_in_eax((unsigned long)(long)table[1]));
        }

        if (frame.mode.attributes & 0x80) {
            mapping.pointer = map_video_memory(frame.mode.physical_address);
            framebuffer_selector = mapping.address.selector;
            framebuffer_offset = mapping.address.offset;
            linear_framebuffer_enabled = 1;
            use_software_framebuffer = video_page_count <= 1;
            video_page_size = (unsigned long)video_pitch * (unsigned long)video_height;
            draw_page_address = (void *)mapped_video_base;
            page_address = 0;
            for (page = 0; page < video_page_count; ++page) {
                linear_page_addresses[page] = (void *)(mapped_video_base + page_address);
                page_address += video_page_size;
            }
        } else {
            switch (frame.mode.window_granularity) {
            case 0x40: bank_shift = 0; break;
            case 0x20: bank_shift = 1; break;
            case 0x10: bank_shift = 2; break;
            case 0x08: bank_shift = 3; break;
            case 0x04: bank_shift = 4; break;
            case 0x02: bank_shift = 5; break;
            case 0x01: bank_shift = 6; break;
            }

            linear_framebuffer_enabled = 0;
            if (width == 320 && height == 200 && video_page_count >= 2) {
                use_software_framebuffer = 0;
                video_page_size = 0x10000;
                draw_page_address = (void *)0xa0000;
            } else {
                video_page_size = (unsigned long)video_pitch * (unsigned long)video_height;
                use_software_framebuffer = 1;
                draw_page_address = software_framebuffer;
            }
            video_page_count = 1;
        }

        skip_bank_switch = use_software_framebuffer;
        page_address = 0;
        for (page = 0; page < video_page_count; ) {
            divide_vesa_offset((long)page_address, video_pitch, &frame.tail.page.division);
            ++page;
            page_offsets[page].remainder = (unsigned short)frame.tail.page.division.remainder;
            page_address += video_page_size;
            page_offsets[page].quotient = (unsigned short)frame.tail.page.division.quotient;
        }
        goto finished;

    next_mode:
        ++mode;
    check_mode:
        ;
    } while ((mode_number = *mode) != -1);
    printf(vesa_mode_not_found_message, width, height);
    runtime_exit(0);

finished:
    return;
}
