/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern char art_filename[];
extern short tilesizx[], tilesizy[];
extern long picanm[], art_tile_offsets[], pow2long[];
extern unsigned char art_tile_file[], picsiz[];
extern long art_size, art_file_count, art_header_version, art_header_total_tiles;
extern long art_cache_bytes, art_tile_cache;
/* The engine calls this 512-byte tile-visibility bitmap gotpic. */
extern long art_tile_locks[];
extern long loaded_art_number, art_file_position, shutdown_art_handle;

extern char *strcpy(char *destination, const char *source);
#pragma aux strcpy parm [eax] [edx] modify exact [eax edx];
extern short open_tile_art(const char *name, long mode);
#pragma aux open_tile_art parm [eax] [edx] value [ax] modify exact [eax edx];
extern void read_tile_art(long handle, void *buffer, long size);
#pragma aux read_tile_art parm [eax] [edx] [ebx] modify exact [eax edx ebx];
extern void shutdown_close_art(long handle);
#pragma aux shutdown_close_art parm [eax] modify exact [eax];
extern long engine_malloc(long size);
#pragma aux engine_malloc parm [eax] value [eax] modify exact [eax];
extern void initcache(long address, long size);
#pragma aux initcache parm [eax] [edx] modify exact [eax edx];

extern void finish_tile_load(void);
#pragma aux finish_tile_load aborts modify exact [];

/* Register bindings preserve the original loader frame while C computes
 * filenames, ART header sizes and tile offsets. */
extern long from_ax(void);
#pragma aux from_ax = value [eax] modify exact [];

extern void in_ax(long value);
#pragma aux in_ax = "" parm [eax] modify exact [];

extern long from_bx(void);
#pragma aux from_bx = value [ebx] modify exact [];

extern void in_bx(long value);
#pragma aux in_bx = "" parm [ebx] modify exact [];

extern long from_cx(void);
#pragma aux from_cx = value [ecx] modify exact [];

extern void in_cx(long value);
#pragma aux in_cx = "" parm [ecx] modify exact [];

extern long from_dx(void);
#pragma aux from_dx = value [edx] modify exact [];

extern void in_dx(long value);
#pragma aux in_dx = "" parm [edx] modify exact [];

extern long from_di(void);
#pragma aux from_di = value [edi] modify exact [];

extern void in_di(long value);
#pragma aux in_di = "" parm [edi] modify exact [];

extern long from_si(void);
#pragma aux from_si = value [esi] modify exact [];

extern void in_si(long value);
#pragma aux in_si = "" parm [esi] modify exact [];


extern long from_bp(void);
#pragma aux from_bp = value [ebp] modify exact [];

extern void begin_art_load(void);
#pragma aux begin_art_load = "push ebx" "push ecx" "push edx" "push esi" "push edi" "push ebp" "sub esp, 0xc" modify exact [];

/* Keep the second zeroing instruction and the tile cursor increment in order. */
extern void zero_animation_value(void);
#pragma aux zero_animation_value = "xor ecx, ecx" modify exact [ecx edx];

extern void read_filename_counter(void);
#pragma aux read_filename_counter = "mov ax, word ptr [art_file_count]" "mov ecx, 0xa" modify exact [eax ecx ebx];

extern void save_file_count_word(void);
#pragma aux save_file_count_word = "mov [esp + 8], ax" modify exact [eax edx];

/* Header reads target the original stack slots. */
extern void read_first_tile_cursor(void);
#pragma aux read_first_tile_cursor = "lea edx, [esp + 4]" modify exact [edx];
extern void read_last_tile_cursor(void);
#pragma aux read_last_tile_cursor = "mov edx, esp" modify exact [edx];

extern void load_tile_width_range(void);
#pragma aux load_tile_width_range = "mov eax, [esp]" "mov ebp, [esp + 0x4]" "sub eax, ebp" modify exact [eax];

extern void load_tile_height_range(void);
#pragma aux load_tile_height_range = "mov ebx, [esp]" "mov eax, [esp + 4]" modify exact [eax ebx edx];

extern void load_tile_animation_range(void);
#pragma aux load_tile_animation_range = "mov eax, [esp]" "mov edx, [esp + 4]" modify exact [eax ebx edx];

extern void load_art_data_offset(void);
#pragma aux load_art_data_offset = "mov ebx, [esp]" "sub ebx, [esp + 4]" "mov edx, [esp + 4]" modify exact [eax ebx edx];

extern void read_last_tile(void);
#pragma aux read_last_tile = "mov edi, [esp]" modify exact [edi];

extern unsigned char art_file_number_byte(void);
#pragma aux art_file_number_byte = value [cl] modify exact [];
extern void read_tile_art_number(void);
#pragma aux read_tile_art_number = "mov cl, [esp + 0x8]" modify exact [ecx];

extern void load_previous_file_index(void);
#pragma aux load_previous_file_index = "movsx eax, word ptr [esp + 8]" modify exact [eax];

extern void clear_art_seen_bits(void);
#pragma aux clear_art_seen_bits = "rep stosd" modify exact [ecx edi];

extern void shrink_art_cache(void);
#pragma aux shrink_art_cache = "mov ebp, [art_cache_bytes]" "sub ebp, 0x10000" \
    "mov [art_cache_bytes], ebp" modify exact [eax];
extern unsigned char height_exponent_byte(void);
#pragma aux height_exponent_byte = value [al] modify exact [];
extern void set_height_exponent_byte(unsigned char value);
#pragma aux set_height_exponent_byte = "" parm [al] modify exact [];
extern unsigned char tile_size_byte(void);
#pragma aux tile_size_byte = value [ah] modify exact [];
extern void keep_size_byte(unsigned char value);
#pragma aux keep_size_byte = "" parm [ah] modify exact [];

extern void restore_art_loader(void);
#pragma aux restore_art_loader = "add esp, 0xc" "jmp near finish_tile_load" aborts modify exact [];

void load_art_files(void);
#pragma aux load_art_files aborts;

void load_art_files(void)
{
    begin_art_load();
    strcpy(art_filename, (const char *)from_ax());
    /* Clear dimensions and animation before scanning the numbered files. */
    in_dx(0);
    goto test_clear_tile;
clear_tile_record:
    in_cx(0);
    tilesizx[from_bx()] = (short)from_cx();
    tilesizy[from_bx()] = (short)from_cx();
    zero_animation_value();
    in_dx(from_dx() + 1);
    picanm[from_bx()] = from_cx();
test_clear_tile:
    in_bx((short)from_dx());
    if (from_bx() < 4096)
        goto clear_tile_record;
    in_dx(0);
    art_size = from_dx();
    art_file_count = from_dx();
    /* Patch the three-digit sequential ART suffix. */
next_art_file:
    read_filename_counter();
    in_bx((short)from_ax());
    save_file_count_word();
    in_dx(from_bx() % from_cx());
    in_dx(from_dx() + '0');
    art_filename[7] = (char)from_dx();
    in_ax(from_bx() / from_cx());
    in_dx(from_ax() % from_cx());
    in_dx(from_dx() + '0');
    in_cx(100);
    art_filename[6] = (char)from_dx();
    in_ax(from_bx() / from_cx());
    in_bx(10);
    in_dx(from_ax() % from_bx());
    in_dx(from_dx() + '0');
    in_ax((long)art_filename);
    art_filename[5] = (char)from_dx();
    in_dx(0);
    open_tile_art((const char *)from_ax(), from_dx());
    in_cx((short)from_ax());
    in_si(from_ax());
    if (from_cx() == -1)
        goto test_next_art_file;
    read_tile_art(from_cx(), &art_header_version, 4);
    if (art_header_version != 1) {
art_failed:
        in_ax(-1);
        goto art_done;
    }
    read_tile_art(from_cx(), &art_header_total_tiles, 4);
    /* The two local header bounds are followed by width, height and animation arrays. */
    in_bx(4);
    read_first_tile_cursor();
    read_tile_art(from_cx(), (void *)from_dx(), from_bx());
    in_bx(4);
    read_last_tile_cursor();
    read_tile_art(from_cx(), (void *)from_dx(), from_bx());
    load_tile_width_range();
    in_ax(from_ax() * 2);
    in_dx(from_bp() * 2);
    in_bx(from_ax() + 2);
    in_dx(from_dx() + (long)tilesizx);
    read_tile_art(from_cx(), (void *)from_dx(), from_bx());
    load_tile_height_range();
    in_bx((from_bx() - from_ax()) * 2);
    in_dx(from_ax() * 2);
    in_bx(from_bx() + 2);
    in_dx(from_dx() + (long)tilesizy);
    read_tile_art(from_cx(), (void *)from_dx(), from_bx());
    load_tile_animation_range();
    in_ax((from_ax() - from_dx()) << 2);
    in_dx(from_dx() << 2);
    in_bx(from_ax() + 4);
    in_dx(from_dx() + (long)picanm);
    read_tile_art(from_cx(), (void *)from_dx(), from_bx());
    load_art_data_offset();
    in_bx(from_bx() << 3);
    read_last_tile();
    in_bx(from_bx() + 24);
    goto test_tile_range;
load_tile_metadata:
    /* Advance the file offset by this tile's signed width times height. */
    read_tile_art_number();
    art_tile_offsets[from_ax()] = from_bx();
    art_tile_file[from_ax()] = art_file_number_byte();
    in_cx(tilesizx[from_ax()]);
    in_ax(tilesizy[from_ax()]);
    in_ax(from_ax() * from_cx());
    in_cx(art_size);
    in_dx(from_dx() + 1);
    in_cx(from_cx() + from_ax());
    in_bx(from_bx() + from_ax());
    art_size = from_cx();
test_tile_range:
    in_ax((short)from_dx());
    if (from_ax() <= from_di())
        goto load_tile_metadata;
    shutdown_close_art((short)from_si());
    ++art_file_count;
test_next_art_file:
    load_previous_file_index();
    in_si(art_file_count);
    if (from_ax() != from_si())
        goto next_art_file;
    /* Clear the bitset of tiles seen by the renderer. */
    in_cx(128);
    in_di((long)art_tile_locks);
    in_ax(from_ax() ^ from_si());
    clear_art_seen_bits();
    /* Start at the larger of the ART data size and 1 MiB. */
    in_di(art_size);
    if (from_di() > 1048576)
        in_ax(from_di());
    else
        in_ax(1048576);
    art_cache_bytes = from_ax();
retry_cache:
    /* Retry with 64 KiB less until the cache fits. */
    in_ax(engine_malloc(art_cache_bytes));
    art_tile_cache = from_ax();
    if (!from_ax()) {
        shrink_art_cache();
        if (from_bp() >= 65536)
            goto retry_cache;
        goto art_failed;
    }
    initcache(from_ax(), art_cache_bytes);
    in_dx(0);
    goto test_size_range;
compute_tile_size:
    /* Pack the base-2 width and height exponents into the low and high nibbles. */
    in_ax(15);
    for (;;) {
        in_cx((short)from_ax());
        if (from_cx() <= 1)
            break;
        in_bx((short)from_dx());
        in_si(pow2long[from_cx()]);
        in_bx(tilesizx[from_bx()]);
        if (from_bx() >= from_si())
            break;
        in_ax(from_ax() - 1);
    }
    in_bx((short)from_dx());
    picsiz[from_bx()] = (unsigned char)from_ax();
    in_ax(15);
    for (;;) {
        in_bx((short)from_ax());
        if (from_bx() <= 1)
            break;
        in_cx((short)from_dx());
        in_di(pow2long[from_bx()]);
        in_cx(tilesizy[from_cx()]);
        if (from_cx() >= from_di())
            break;
        in_ax(from_ax() - 1);
    }
    in_bx((short)from_dx());
    set_height_exponent_byte(height_exponent_byte() << 4);
    keep_size_byte(picsiz[from_bx()]);
    keep_size_byte(tile_size_byte() + height_exponent_byte());
    in_dx(from_dx() + 1);
    picsiz[from_bx()] = tile_size_byte();
test_size_range:
    in_ax((short)from_dx());
    if (from_ax() < 4096)
        goto compute_tile_size;
    in_dx(-1);
    in_cx(0);
    in_ax(0);
    shutdown_art_handle = from_dx();
    loaded_art_number = from_dx();
    art_file_position = from_cx();
art_done:
    restore_art_loader();
}
