extern short cursor_visible;
extern short text_rows_bios(int service, int address, int screen, int control);
#pragma aux text_rows_bios = "push bp" "int 10h" "pop bp" parm [eax] [edx] [ecx] [ebx] value [ax] modify exact [eax ebx ecx edx];
extern void restore_text_rows_mode(short service, int address, int screen, int control);
#pragma aux restore_text_rows_mode = "push bp" "int 10h" "pop bp" parm [ax] [edx] [ecx] [ebx] modify exact [eax ebx ecx edx];
/* The BIOS mode number is in the low seven bits of AL. */
extern short query_text_rows_mode(int service, int address, int screen, int control);
#pragma aux query_text_rows_mode = "push bp" "int 10h" "pop bp" "and al,7fh" "xor ah,ah" parm [eax] [edx] [ecx] [ebx] value [ax] modify exact [eax ebx ecx edx];

extern unsigned short bios_data_selector;
extern unsigned long bios_data_offset;

void set_standard_text_rows(void)
{
    short mode;
    unsigned char __far *flags;
    mode = query_text_rows_mode(0xf00, 0, 0, 0);
    restore_text_rows_mode(mode, 0, 0, 0);
    flags = (unsigned char __far *)((__segment)bios_data_selector :> (unsigned char *)(bios_data_offset + 0x87));
    *flags &= 0xfe;
    text_rows_bios(0x100, 0, 0x607, 0);
    cursor_visible = 1;
}

/* Hold the cursor shape in ESI across the BIOS calls. */
extern int cursor_in_esi(int cursor);
#pragma aux cursor_in_esi = "" parm [esi] value [esi] modify exact [];
extern void set_crtc_underline(unsigned value, unsigned port);
#pragma aux set_crtc_underline = "out dx,ax" parm [eax] [edx] modify exact [];

void configure_ega_text_font(short rows, int font_selector, int cursor_shape)
{
    short mode;
    unsigned char __far *flags;
    cursor_shape = cursor_in_esi(cursor_shape);
    text_rows_bios(0x500, 0, 0, 0);
    mode = query_text_rows_mode(0xf00, 0, 0, 0);
    restore_text_rows_mode(mode, 0, 0, 0);
    text_rows_bios(font_selector, 0, 0, 0);
    if (rows == 43) {
        flags = (unsigned char __far *)((__segment)bios_data_selector :> (unsigned char *)(bios_data_offset + 0x87));
        *flags |= 1;
    } else {
        set_crtc_underline(0x1414, 0x3d4);
    }
    text_rows_bios(0x100, 0, cursor_shape, 0);
    cursor_visible = 1;
}

extern short graphics_error, text_rows, text_columns;
extern short text_window_top, text_window_bottom, text_window_left, text_window_right;
extern short text_cursor_row, text_cursor_column, text_page_offset, active_text_page;
extern unsigned char graphics_active;
extern void ensure_graphics_initialized(void);
#pragma aux ensure_graphics_initialized "initialize_graphics_once_" modify exact [eax];
extern void configure_text_rows_in_graphics_mode(short rows);
#pragma aux configure_text_rows_in_graphics_mode modify exact [eax];
extern void configure_text_rows_in_text_mode(short rows);
#pragma aux configure_text_rows_in_text_mode modify exact [eax];
extern void reset_text_pages(void);
#pragma aux reset_text_pages "initialize_text_pages_" modify exact [eax];
extern void reset_text_display(void);
#pragma aux reset_text_display modify exact [eax];

short set_text_rows(short requested)
{
    short rows;
    unsigned char __far *bios_row_count;
    graphics_error = 0;
    ensure_graphics_initialized();
    if (graphics_active)
        configure_text_rows_in_graphics_mode(requested);
    else
        configure_text_rows_in_text_mode(requested);
    if (graphics_error)
        return 0;

    bios_row_count = (unsigned char __far *)((__segment)bios_data_selector :> (unsigned char *)(bios_data_offset + 0x84));
    rows = *bios_row_count + 1;
    if (rows == 1)
        rows = 25;
    text_rows = rows;
    if (!graphics_active)
        reset_text_pages();
    reset_text_display();
    text_window_top = 0;
    text_window_left = 0;
    text_cursor_row = 0;
    text_cursor_column = 0;
    text_page_offset = 0;
    text_window_bottom = text_rows - 1;
    text_window_right = text_columns - 1;
    active_text_page = 0;
    text_rows_bios(0x500, 0, 0, 0);
    return text_rows;
}

extern short rounded_in_dx(short count);
#pragma aux rounded_in_dx = "" parm [dx] value [dx] modify exact [];
extern short block_count_in_cx(short count);
#pragma aux block_count_in_cx = "" parm [cx] value [cx] modify exact [];
extern short text_page_count, video_memory_kib;

void initialize_text_pages(void)
{
    short characters, padded, blocks, pages;
    unsigned short __far *page_size;
    characters = text_rows * text_columns;
    /* Clear the low nine bits in the original register order. */
    padded = rounded_in_dx(characters & 0xfeff) & 0xff00;
    if (padded < characters)
        padded += 0x200;
    page_size = (unsigned short __far *)((__segment)bios_data_selector :> (unsigned short *)(bios_data_offset + 0x4c));
    *page_size = 2 * padded;
    if (video_memory_kib == 0x40)
        blocks = 0x10;
    else
        blocks = 0x20;
    pages = block_count_in_cx(blocks) / (rounded_in_dx(padded) >> 9);
    if (pages > 8)
        pages = 8;
    text_page_count = pages;
}

/* Keep the detected adapter class in DX through the memory lookup. */
extern short adapter_in_dx(short adapter);
#pragma aux adapter_in_dx = "" parm [dx] value [dx] modify exact [];
extern short pixel_width, pixel_height, bitmap_bits_per_pixel, bitmap_layout_flags;
extern short palette_size, video_mode;
extern short adapter_class, monitor_class, cursor_shape;
extern short adapter_class_table[], monitor_class_table[], video_memory_table[];
extern short detect_display_adapters(void);
#pragma aux detect_display_adapters modify exact [eax];
extern short query_ega_memory(int address, int screen, int control, int service);
#pragma aux query_ega_memory = "push bp" "int 10h" "pop bp" parm [edx] [ecx] [ebx] [eax] value [bx] modify exact [eax ebx ecx edx];

void read_graphics_mode_state(void)
{
    unsigned char __far *bios_row_count;
    unsigned short __far *bios_columns;
    unsigned short __far *bios_cursor;
    short rows, adapter, display_class;
    pixel_width = 0;
    pixel_height = 0;
    bitmap_bits_per_pixel = 0;
    bitmap_layout_flags = 0;

    bios_row_count = (unsigned char __far *)((__segment)bios_data_selector :> (unsigned char *)(bios_data_offset + 0x84));
    rows = *bios_row_count + 1;
    if (rows == 1)
        rows = 25;
    text_rows = rows;
    bios_columns = (unsigned short __far *)((__segment)bios_data_selector :> (unsigned short *)(bios_data_offset + 0x4a));
    text_columns = *bios_columns;
    palette_size = 0x20;
    video_mode = query_text_rows_mode(0xf00, 0, 0, 0);

    adapter = detect_display_adapters() & 0xff;
    display_class = adapter_in_dx(adapter_class_table[adapter]);
    monitor_class = monitor_class_table[adapter];
    video_memory_kib = video_memory_table[display_class];
    adapter_class = display_class;
    if (video_memory_kib == -1)
        video_memory_kib = ((query_ega_memory(0, 0, 0x10, 0x1200) & 0xff) + 1) << 6;
    if (graphics_active || adapter_class < 4)
        text_page_count = 8;
    else
        reset_text_pages();
    bios_cursor = (unsigned short __far *)((__segment)bios_data_selector :> (unsigned short *)(bios_data_offset + 0x60));
    cursor_shape = *bios_cursor;
}

extern unsigned char graphics_init_pending;
extern short initial_video_mode, initial_text_rows;
extern void initialize_graphics_memory_windows(void);
#pragma aux initialize_graphics_memory_windows modify exact [eax];
extern void read_initial_graphics_state(void);
#pragma aux read_initial_graphics_state "read_graphics_mode_state_" modify exact [eax];

/* Match the register assignment for the text window dimensions and BIOS cursor. */
extern short rows_in_bx(short rows);
#pragma aux rows_in_bx = "" parm [bx] value [bx] modify exact [];
extern unsigned short cursor_in_dx(unsigned short cursor);
#pragma aux cursor_in_dx = "" parm [dx] value [dx] modify exact [];

void initialize_graphics_once(void)
{
    unsigned short cursor;
    volatile unsigned short __far *bios_cursor;
    short mode, rows, bottom;
    if (!graphics_init_pending)
        return;
    graphics_init_pending = 0;
    initialize_graphics_memory_windows();
    read_initial_graphics_state();
    mode = video_mode;
    rows = rows_in_bx(*(volatile short *)&text_rows);
    initial_video_mode = mode;
    initial_text_rows = rows;
    bottom = rows - 1;
    bios_cursor = (volatile unsigned short __far *)((__segment)bios_data_selector :> (volatile unsigned short *)(bios_data_offset + 0x50));
    cursor = cursor_in_dx(*bios_cursor);

    text_window_top = 0;
    text_window_left = 0;
    text_cursor_row = (int)cursor >> 8;
    text_window_bottom = bottom;
    text_cursor_column = cursor & 0xff;
    text_window_right = text_columns - 1;
}

extern void cursor_bios(int service, short shape, int address, int page);
#pragma aux cursor_bios = "push bp" "int 10h" "pop bp" parm [eax] [cx] [edx] [ebx] modify exact [eax ebx ecx edx];

void set_bios_cursor_visible(short visible)
{
    unsigned short shape = cursor_shape;
    if (!visible)
        shape |= 0x2000;
    cursor_bios(0x100, shape, 0, 0);
}

extern void write_bios_cursor_visibility(short visible);
#pragma aux write_bios_cursor_visibility "set_bios_cursor_visible_" modify exact [eax];
extern void toggle_graphics_cursor_line(void);
#pragma aux toggle_graphics_cursor_line modify exact [eax];
extern short bios_cursor_in_bx(short cursor);
#pragma aux bios_cursor_in_bx = "" parm [bx] value [bx] modify exact [];
extern unsigned long offset_in_dx(unsigned long offset);
#pragma aux offset_in_dx = "" parm [edx] value [edx] modify exact [];

void hide_graphics_cursor(void)
{
    if (!cursor_visible)
        return;
    if (!graphics_active) {
        write_bios_cursor_visibility(0);
    } else {
        short __far *bios_cursor;
        short cursor;
        int page, row, column;

        page = active_text_page;
        bios_cursor = (short __far *)((__segment)bios_data_selector :> (short *)(2 * page + offset_in_dx(bios_data_offset) + 0x50));
        cursor = bios_cursor_in_bx(*bios_cursor);
        row = text_cursor_row;
        column = text_cursor_column;
        if (cursor == row * 256 + column)
            toggle_graphics_cursor_line();
    }
    cursor_visible = 0;
}

extern unsigned long mode_buffer_offset, current_buffer_offset;
extern short mode_buffer_selector, mode_buffer_stride, current_buffer_stride;

extern int stride_in_edx(int stride);
#pragma aux stride_in_edx = "" parm [edx] value [edx] modify exact [];

/* Keep the selector reload between the mode buffer offset and page count writes. */
void apply_graphics_mode_state(short width, short height, short colors, short bits,
                               int pages, int stride, unsigned long offset,
                               volatile int selector, int flags)
{
    unsigned long start;
    int count, buffer_stride;
    int active_selector;

    graphics_active = 1;
    read_initial_graphics_state();
    start = offset;
    pixel_width = width;
    pixel_height = height;
    palette_size = colors;
    bitmap_bits_per_pixel = bits;
    count = pages;
    mode_buffer_offset = start;
    active_selector = selector;
    text_page_count = count;
    buffer_stride = stride_in_edx(stride);
    mode_buffer_selector = active_selector;
    mode_buffer_stride = buffer_stride;
    bitmap_layout_flags |= flags;
    start = offset;
    current_buffer_stride = buffer_stride;
    current_buffer_offset = start;
}

extern unsigned short preserve_display;

extern short bios_mode_supported(int mode);
#pragma aux bios_mode_supported modify exact [eax];
extern void preserve_bios_pixels(void);
#pragma aux preserve_bios_pixels = "or bl,80h" modify exact [ebx];
/* The monochrome path addresses the same BIOS byte through FS. */
extern unsigned long setup_bios_equipment(unsigned char __far *address);
#pragma aux setup_bios_equipment = "push es" "pop fs" "mov edx,eax" "and byte ptr es:[eax],0cfh" parm [es eax] value [eax] modify exact [edx es fs];
extern void enable_bios_monochrome(void);
#pragma aux enable_bios_monochrome = "or byte ptr fs:[edx],30h" modify exact [];
extern void enable_bios_color(unsigned long equipment);
#pragma aux enable_bios_color = "or byte ptr es:[eax],20h" parm [eax] modify exact [];

extern short query_bios_video_mode(void);
#pragma aux query_bios_video_mode = "mov eax,0f00h" "xor ebx,ebx" "xor ecx,ecx" "xor edx,edx" "push bp" "int 10h" "pop bp" "and al,7fh" "xor ah,ah" value [ax] modify exact [eax ebx ecx edx];

extern void set_bios_video_mode(int mode);
#pragma aux set_bios_video_mode = "mov eax,ebx" "xor ecx,ecx" "xor edx,edx" "xor ebx,ebx" "push bp" "int 10h" "pop bp" parm [ebx] modify exact [eax ebx ecx edx];

/* Pass the signed mode to the support check and retain its original register value. */
extern int save_mode_for_bios(int mode);
#pragma aux save_mode_for_bios = "mov ebx,eax" "cwde" parm [eax] value [eax] modify exact [ebx];
extern int video_mode_from_ebx(void);
#pragma aux video_mode_from_ebx = value [ebx] modify exact [];

short set_and_query_bios_mode(int mode)
{
    unsigned long equipment;
    unsigned char __far *bios_equipment;

    if (bios_mode_supported(save_mode_for_bios(mode))) {
        bios_equipment = (unsigned char __far *)((__segment)bios_data_selector :> (unsigned char *)(bios_data_offset + 0x10));
        equipment = setup_bios_equipment(bios_equipment);
        if ((short)video_mode_from_ebx() == 7 || (short)video_mode_from_ebx() == 0xf)
            enable_bios_monochrome();
        else
            enable_bios_color(equipment);
        if (preserve_display)
            preserve_bios_pixels();
        set_bios_video_mode(video_mode_from_ebx());
    }
    return query_bios_video_mode();
}

/* BIOS function 1Ah returns the supported display combination in BX. */
extern short bios_display_service(void);
#pragma aux bios_display_service = "mov eax,1a00h" "xor ebx,ebx" "xor ecx,ecx" "xor edx,edx" "push bp" "int 10h" "pop bp" "xor ah,ah" value [ax] modify exact [eax ebx ecx edx];
extern unsigned char bios_display_combination(void);
#pragma aux bios_display_combination = "mov eax,1a00h" "xor ebx,ebx" "xor ecx,ecx" "xor edx,edx" "push bp" "int 10h" "pop bp" "movsx eax,bx" "sar eax,8" "mov dl,bl" "mov dh,al" value [bl] modify exact [eax ebx ecx edx];
/* Keep the BIOS results in BL and AL until their subsequent checks. */
extern unsigned char primary_bios_code(void);
#pragma aux primary_bios_code = value [bl] modify exact [];
extern unsigned char ega_display_code(void);
#pragma aux ega_display_code = value [al] modify exact [];
extern void use_ega_secondary_code(void);
#pragma aux use_ega_secondary_code = "mov dh,al" modify exact [edx];
/* The packed primary and secondary adapter codes occupy DL and DH. */
extern unsigned char primary_display(void);
#pragma aux primary_display = value [dl] modify exact [];
extern unsigned char secondary_display(void);
#pragma aux secondary_display = value [dh] modify exact [];
extern void update_primary_display(unsigned char code);
#pragma aux update_primary_display = "mov dl,al" parm [al] modify exact [edx];
extern void update_secondary_display(unsigned char code);
#pragma aux update_secondary_display = "mov dh,al" parm [al] modify exact [edx];
extern void set_ega_primary(void);
#pragma aux set_ega_primary = "mov dl,3" modify exact [edx];
extern void set_secondary_vga(void);
#pragma aux set_secondary_vga = "mov dh,9" modify exact [edx];
extern void set_primary_vga(void);
#pragma aux set_primary_vga = "add dl,9" modify exact [edx];
extern short combined_display_codes(void);
#pragma aux combined_display_codes = "movzx ax,dh" "shl eax,8" "movzx dx,dl" "add eax,edx" value [ax] modify exact [eax edx];
extern unsigned char read_ega_display_flags(unsigned char __far *address);
#pragma aux read_ega_display_flags = "mov al,byte ptr es:[eax]" "and al,0fh" parm [es eax] value [al] modify exact [eax es];

extern unsigned char detect_mono_display(void);
#pragma aux detect_mono_display "detect_mono_adapter_" modify exact [eax];
extern short detect_legacy_display_adapters(void);
#pragma aux detect_legacy_display_adapters modify exact [eax];
extern short probe_video_adapter(void);
#pragma aux probe_video_adapter modify exact [eax];

short detect_display_adapters(void)
{
    unsigned char __far *equipment;

    if (bios_display_service() != 0x1a)
        goto fallback;
    if (bios_display_combination() > 0xc)
        goto fallback;
    if (primary_bios_code() == 1)
        update_primary_display(detect_mono_display());
    if (secondary_display() == 1)
        update_secondary_display(detect_mono_display());
    if (primary_display() == 4 || secondary_display() == 4) {
        equipment = (unsigned char __far *)((__segment)bios_data_selector :> (unsigned char *)(bios_data_offset + 0x88));
        if (read_ega_display_flags(equipment) == 3)
            use_ega_secondary_code();
        if (ega_display_code() == 9)
            set_ega_primary();
    }
    if (primary_display() == 7 || primary_display() == 8) {
        if (probe_video_adapter())
            set_primary_vga();
    } else if (secondary_display() == 7 || secondary_display() == 8) {
        if (probe_video_adapter())
            set_secondary_vga();
    }
    return combined_display_codes();

fallback:
    return detect_legacy_display_adapters();
}

/* Keep the separate BIOS and legacy fallback probe paths. */
extern void preserve_ega_probe_order(void);
#pragma aux preserve_ega_probe_order = "" modify exact [];
extern unsigned char detect_legacy_color_display(void);
#pragma aux detect_legacy_color_display "detect_color_adapter_" modify exact [eax];

extern short bios_ega_switches(void);
#pragma aux bios_ega_switches = "mov eax,1200h" "mov ebx,10h" "xor ecx,ecx" "xor edx,edx" "push bp" "int 10h" "pop bp" "xor ch,ch" value [cx] modify exact [eax ebx ecx edx];
extern short bios_ega_configuration(void);
#pragma aux bios_ega_configuration = "mov eax,1200h" "mov ebx,10h" "xor cl,cl" "xor edx,edx" "push bp" "int 10h" "pop bp" "movsx eax,bx" "sar eax,8" "xor bh,bh" value [ax] modify exact [eax ebx ecx edx];
extern short bios_ega_memory(void);
#pragma aux bios_ega_memory = value [bx] modify exact [];
extern unsigned char bios_legacy_active_mode(void);
#pragma aux bios_legacy_active_mode = "mov eax,0f00h" "xor ebx,ebx" "xor ecx,ecx" "xor edx,edx" "push bp" "int 10h" "pop bp" "and al,7fh" value [al] modify exact [eax ebx ecx edx];
extern short pack_legacy_adapter_codes(unsigned short secondary, unsigned short primary);
#pragma aux pack_legacy_adapter_codes = "shl eax,8" "add eax,ebx" parm [ax] [bx] value [ax] modify exact [eax];

short detect_legacy_display_adapters(void)
{
    volatile unsigned char mono, color;
    short ega;
    unsigned char flags, mode;
    unsigned char __far *equipment;
    unsigned short primary, secondary;

    if (bios_ega_switches() >= 0xc)
        goto fallback_color;

    ega = bios_ega_configuration();
    if (ega > 1 || bios_ega_memory() > 3) {
        color = detect_legacy_color_display();
        goto probe_mono;
    }
    if (ega == 0) {
        equipment = (unsigned char __far *)((__segment)bios_data_selector :> (unsigned char *)(bios_data_offset + 0x88));
        flags = read_ega_display_flags(equipment);
        if (flags == 3 || flags == 9)
            color = 3;
        else
            color = 4;
        goto probe_mono;
    }

    flags = detect_legacy_color_display();
    mono = 5;
    color = flags;
    goto query_current_mode;

fallback_color:
    color = detect_legacy_color_display();
    preserve_ega_probe_order();
probe_mono:
    mono = detect_mono_display();

query_current_mode:
    mode = bios_legacy_active_mode();
    if (mode == 7 || mode == 0xb || mode == 0xf) {
        secondary = color;
        primary = mono;
    } else {
        secondary = mono;
        primary = color;
    }
    return pack_legacy_adapter_codes(secondary, primary);
}

extern const unsigned char hercules_crtc_registers[];
extern unsigned long mono_video_offset;
extern unsigned short mono_video_selector;

/* Select the Hercules graphics aperture and leave the display blank. */
extern short start_hercules_graphics(unsigned char __far *equipment);
#pragma aux start_hercules_graphics = "mov edx,3bfh" "or byte ptr es:[eax],30h" "mov al,1" "out dx,al" "mov edx,3b8h" "mov al,2" "xor edi,edi" "out dx,al" parm [es eax] value [di] modify exact [eax edx edi es];

extern short write_hercules_crtc(int index_value, short index);
#pragma aux write_hercules_crtc = "mov edx,3b4h" "inc edi" "out dx,ax" parm [eax] [di] value [di] modify exact [edx edi];
extern void clear_hercules_buffer(int count, unsigned long address, unsigned short selector);
#pragma aux clear_hercules_buffer = "xor al,al" "push es" "push edi" "mov es,dx" "mov ah,al" "shr ecx,1" "repne stosw" "adc ecx,ecx" "repne stosb" "pop edi" "pop es" parm [ecx] [edi] [dx] modify exact [eax ecx edi];

extern void enable_hercules_display(void);
#pragma aux enable_hercules_display = "mov edx,3b8h" "mov al,0ah" "out dx,al" modify exact [eax edx];

/* Record the mode, columns, last row, and display offset in the BIOS data area. */
extern void update_hercules_bios(unsigned char __far *bios);
#pragma aux update_hercules_bios = "lea edx,[eax+49h]" "mov byte ptr es:[edx],0bh" "lea edx,[eax+4ah]" "push es" "pop fs" "mov byte ptr es:[edx],5ah" "lea edx,[eax+84h]" "add eax,50h" "mov byte ptr fs:[edx],18h" "mov word ptr es:[eax],0" parm [es eax] modify exact [eax edx es fs];

void program_hercules_graphics(void)
{
    unsigned long address;
    unsigned short selector;
    short index = start_hercules_graphics((unsigned char __far *)
        ((__segment)bios_data_selector :> (unsigned char *)(bios_data_offset + 0x10)));

    do {
        int command = index + ((int)hercules_crtc_registers[index] << 8);
        index = write_hercules_crtc(command, index);
    } while (index < 12);

    address = mono_video_offset;
    selector = mono_video_selector;
    clear_hercules_buffer(0x8000, address, selector);
    enable_hercules_display();
    update_hercules_bios((unsigned char __far *)
        ((__segment)bios_data_selector :> (unsigned char *)bios_data_offset));
}

extern short current_text_row(void);
#pragma aux current_text_row = value [si] modify exact [];
extern unsigned char text_attribute;
extern unsigned short mono_text_selector, color_text_selector;
extern unsigned long mono_text_offset, color_text_offset;

/* Use FS for the video buffer and ES for each row of character cells. */
extern void text_screen_segment(unsigned short selector);
#pragma aux text_screen_segment = "" parm [fs] modify exact [fs];
extern unsigned long text_base_in_eax(unsigned long address);
#pragma aux text_base_in_eax = "" parm [eax] value [eax] modify exact [];
extern int text_page_cell_row(short row, int columns);
#pragma aux text_page_cell_row = "movsx ecx,si" "imul ecx,ebx" parm [si] [ebx] value [ecx] modify exact [ecx];
extern void address_text_page_size(short __far *records);
#pragma aux address_text_page_size = "" parm [es edx] modify exact [es edx];
extern int add_text_column_and_read_page(int row, int left);
#pragma aux add_text_column_and_read_page = "movsx edx,word ptr es:[edx]" "add ecx,ebx" parm [ecx] [ebx] value [edx] modify exact [edx ecx];
extern unsigned long add_text_page_offset(unsigned long base, int page_bytes, int page);
#pragma aux add_text_page_offset = "imul edx,ebx" "add ecx,ecx" "add edx,ecx" "add eax,edx" parm [eax] [edx] [ebx] value [eax] modify exact [eax edx ecx];
extern void load_blank_attribute(void);
#pragma aux load_blank_attribute = "movzx cx,byte ptr [text_attribute]" modify exact [ecx];
extern int compose_blank_cell(int width);
#pragma aux compose_blank_cell = "shl ecx,8" parm [edx] value [edx] modify exact [ecx];
extern void put_space_in_blank_cell(void);
#pragma aux put_space_in_blank_cell = "add ecx,20h" modify exact [ecx];
extern void text_row_offset(unsigned long offset);
#pragma aux text_row_offset = "push fs" "pop es" "mov edx,eax" "xor ebx,ebx" parm [eax] modify exact [es edx ebx];
extern short draw_blank_text_cell(void);
#pragma aux draw_blank_text_cell = "inc ebx" "mov word ptr es:[edx],cx" "inc edx" "inc edx" value [bx] modify exact [ebx edx];
extern short text_cell_column(void);
#pragma aux text_cell_column = value [bx] modify exact [];
extern void clear_text_row_in_esi(int row);
#pragma aux clear_text_row_in_esi = "mov esi,eax" parm [eax] modify exact [esi];
extern short next_text_row(unsigned long address, int stride);
#pragma aux next_text_row = "add edx,edx" "inc esi" "add eax,edx" parm [eax] [edx] value [si] modify exact [eax edx esi];
extern unsigned long text_row_address(void);
#pragma aux text_row_address = value [eax] modify exact [];
extern int clear_text_width(int width);
#pragma aux clear_text_width = "" parm [edx] value [edx] modify exact [];

void clear_text_region(int top, int left, int bottom, int right)
{
    volatile struct {
        int last_column, width, last_row, first_column;
    } region;
    short column;
    int row_cells, page_bytes, width;

    clear_text_row_in_esi(top);
    region.first_column = left;
    region.last_row = bottom;
    region.last_column = right;
    if (video_mode == 7) {
        text_screen_segment(mono_text_selector);
        text_base_in_eax(mono_text_offset);
    } else {
        text_screen_segment(color_text_selector);
        text_base_in_eax(color_text_offset);
    }
    row_cells = text_page_cell_row(current_text_row(), text_columns);
    address_text_page_size((short __far *)((__segment)bios_data_selector :> (short *)(bios_data_offset + 0x4c)));
    page_bytes = add_text_column_and_read_page(row_cells, (short)region.first_column);
    add_text_page_offset(text_row_address(), page_bytes, active_text_page);

    width = clear_text_width(region.last_column);
    load_blank_attribute();
    width = clear_text_width(width - region.first_column);
    width = compose_blank_cell(width);
    width = clear_text_width(width + 1);
    put_space_in_blank_cell();
    region.width = width;

    /* Both loop conditions use the original signed 16-bit counters. */
    goto check_row;
    do {
        text_row_offset(text_row_address());
        column = text_cell_column();
        goto check_column;
        do {
            column = draw_blank_text_cell();
        check_column:
            ;
        } while (column < (short)region.width);
        next_text_row(text_row_address(), text_columns);

    check_row:
        ;
    } while (current_text_row() <= (short)region.last_row);
}
