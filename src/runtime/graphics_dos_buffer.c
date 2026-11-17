extern unsigned char dos_extender_type;

#pragma pack(push, 1)
struct graphics_dos_buffer {
    unsigned short segment;
    unsigned long offset;
    unsigned short selector;
};
#pragma pack(pop)

/* Preserve the graphics runtime's DPMI and DOS register setup. */
extern void dpmi_free_graphics_buffer(unsigned long offset, unsigned short selector);
#pragma aux dpmi_free_graphics_buffer = "mov ebx,edx" "mov ax,101h" "int 31h" parm [eax] [dx] modify exact [eax ebx ecx edx];
extern void dos_free_graphics_buffer(unsigned short segment);
#pragma aux dos_free_graphics_buffer = "mov ax,25c1h" "int 21h" parm [cx] modify exact [eax ebx ecx edx];

void free_graphics_dos_buffer(const struct graphics_dos_buffer *buffer)
{
    if (dos_extender_type == 1)
        dpmi_free_graphics_buffer(buffer->offset, buffer->selector);
    else
        dos_free_graphics_buffer(buffer->segment);
}

/* The DPMI allocator combines the real-mode segment and selector. */
extern unsigned long dpmi_allocate_paragraphs(int paragraphs);
#pragma aux dpmi_allocate_paragraphs = "mov ebx,eax" "mov ax,100h" "int 31h" "jnc dpmi_packed" "sub ax,ax" "sub dx,dx" "dpmi_packed:" "shl eax,16" "mov ax,dx" parm [eax] value [eax] modify exact [eax ebx edx];

extern unsigned short dos_allocate_paragraphs(int paragraphs);
#pragma aux dos_allocate_paragraphs = "mov ebx,eax" "mov ax,25c0h" "int 21h" "jnc dos_segment" "sub ax,ax" "dos_segment:" parm [eax] value [ax] modify exact [eax ebx];

extern unsigned long packed_in_edx(unsigned long value);
#pragma aux packed_in_edx = "" parm [edx] value [edx] modify exact [];
extern short success_in_ax(short success);
#pragma aux success_in_ax = "" parm [ax] value [ax] modify exact [];

extern unsigned short selector_in_ax(unsigned short selector);
#pragma aux selector_in_ax = "" parm [ax] value [ax] modify exact [];

short allocate_graphics_dos_buffer(int bytes, struct graphics_dos_buffer *buffer)
{
    int paragraphs;
    unsigned long block;
    unsigned short segment, real_segment, selector;
    unsigned long address;

    paragraphs = (bytes + 15) / 16;
    if (dos_extender_type == 1) {
        block = dpmi_allocate_paragraphs(paragraphs);
        if (!block)
            goto failed;
        buffer->offset = 0;
        selector = selector_in_ax(block);
        real_segment = packed_in_edx(block) >> 16;
        buffer->selector = selector;
        buffer->segment = real_segment;
        return 1;
    }

    if (dos_extender_type < 2 || dos_extender_type > 8)
        goto failed;
    segment = dos_allocate_paragraphs(paragraphs);
    if (!segment)
        return segment;
    buffer->segment = segment;
    address = segment;
    /* Publish the DOS selector before updating the linear offset. */
    *(volatile unsigned short *)&buffer->selector = 0x34;
    buffer->offset = address << 4;
    return success_in_ax(1);

failed:
    return 0;
}

extern unsigned char extender_flags;
extern unsigned short low_memory_selector, saved_data_selector;
extern unsigned short bios_data_selector, mono_text_selector, color_text_selector, graphics_selector, video_rom_selector;
extern unsigned long bios_data_offset, mono_text_offset, color_text_offset, graphics_offset, video_rom_offset;

/* Watcom's inline assembler does not accept MOV EDX,DS. */
extern unsigned long read_data_selector(const volatile void *address_context);
#pragma aux read_data_selector = 0x8c 0xda parm [eax] value [edx] modify exact [edx];
extern unsigned long low_selector_in_ax(unsigned short selector);
#pragma aux low_selector_in_ax = "" parm [ax] value [eax] modify exact [];

extern unsigned long selector_in_eax(unsigned long selector);
#pragma aux selector_in_eax = "" parm [eax] value [eax] modify exact [];

void initialize_graphics_memory_windows(void)
{
    unsigned long selector;
    unsigned long window_selector;

    saved_data_selector = read_data_selector(&selector);
    if (dos_extender_type == 1 || dos_extender_type == 9)
        selector = read_data_selector(&bios_data_selector);
    else if (extender_flags)
        selector = low_selector_in_ax(low_memory_selector);
    else
        return;

    window_selector = selector_in_eax(selector);
    bios_data_offset = 0x400;
    mono_text_offset = 0xb0000;
    color_text_offset = 0xb8000;
    graphics_offset = 0xa0000;
    video_rom_offset = 0xc0000;
    bios_data_selector = window_selector;
    mono_text_selector = window_selector;
    color_text_selector = window_selector;
    graphics_selector = window_selector;
    video_rom_selector = window_selector;
}
