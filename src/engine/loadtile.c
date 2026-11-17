/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern short tilesizx[], tilesizy[];
extern unsigned char art_tile_file[], walock[], debug_tile_loads;
extern unsigned char waloff[], art_tile_offsets[];
extern long loaded_art_number, art_file_position, shutdown_art_handle;
extern char art_filename[], tile_load_message[];

extern void finish_tile_load(void);
#pragma aux finish_tile_load aborts modify exact [];
extern void shutdown_close_art(long handle);
#pragma aux shutdown_close_art parm [eax] modify exact [eax];
extern long open_tile_art(const char *file, long mode);
#pragma aux open_tile_art parm [eax] [edx] value [eax] modify exact [eax edx];
extern void seek_tile_art(long handle, long distance, long origin);
#pragma aux seek_tile_art parm [eax] [edx] [ebx] modify exact [eax edx ebx];
extern void read_tile_art(long handle, void *pixels, long bytes);
#pragma aux read_tile_art parm [eax] [edx] [ebx] modify exact [eax edx ebx];
extern void faketimerhandler(void);
#pragma aux faketimerhandler modify exact [eax];
extern void allocache(void *slot, long size, void *lock);
#pragma aux allocache parm [eax] [edx] [ebx] modify exact [eax edx ebx];
extern void printf(void);
#pragma aux printf modify exact [eax];

/* Preserve the shared return frame and reject IDs outside the tile table. */
extern void begin_tile_load(short tile);
#pragma aux begin_tile_load = "push ebx" "push ecx" "push edx" "push esi" "push edi" "push ebp" \
    "mov ecx,eax" "test ax,ax" "jl finish_tile_load" "movsx ebx,ax" "cmp ebx,4096" \
    "jge finish_tile_load" parm [ax] modify exact [ebx ecx];
extern long tile_index_in_ebx(void);
#pragma aux tile_index_in_ebx = value [ebx] modify exact [];
extern long load_tile_width(long width);
#pragma aux load_tile_width = "" parm [eax] value [eax] modify exact [];
extern long load_tile_height(long height);
#pragma aux load_tile_height = "" parm [esi] value [esi] modify exact [];
extern void validate_tile_bytes(long bytes);
#pragma aux validate_tile_bytes = "test esi,esi" "jle finish_tile_load" parm [esi] modify exact [];
extern long read_new_art_number(void);
#pragma aux read_new_art_number = "mov bl,[ebx+art_tile_file]" "mov edx,loaded_art_number" "and ebx,255" \
    value [ebx] modify exact [edx ebx];
extern long current_art_number(void);
#pragma aux current_art_number = value [edx] modify exact [];
extern long art_handle_in_edi(long handle);
#pragma aux art_handle_in_edi = "" parm [edi] value [edi] modify exact [];
extern long close_art_argument(long handle);
#pragma aux close_art_argument = "mov eax,edi" parm [edi] value [eax] modify exact [eax];
/* Build the three decimal digits in the current ART archive name. */
extern char art_ones_digit(void);
#pragma aux art_ones_digit = "mov edi,10" "mov edx,ebx" "mov eax,ebx" "sar edx,31" \
    "idiv edi" "add edx,48" value [dl] modify exact [eax edx edi];
extern char art_tens_digit(void);
#pragma aux art_tens_digit = "mov edx,ebx" "mov eax,ebx" "sar edx,31" "idiv edi" \
    "mov edx,eax" "sar edx,31" "idiv edi" "add edx,48" "mov edi,100" \
    value [dl] modify exact [eax edx edi];
extern void start_art_hundreds_digit(void);
#pragma aux start_art_hundreds_digit = "mov edx,ebx" "mov eax,ebx" "sar edx,31" "idiv edi" \
    modify exact [eax edx];
extern char art_hundreds_digit(void);
#pragma aux art_hundreds_digit = "mov edx,eax" "mov ebx,10" "sar edx,31" "idiv ebx" \
    "xor ebp,ebp" "add edx,48" "mov eax,offset art_filename" value [dl] modify exact [eax edx ebx];
extern long begin_art_open(void);
#pragma aux begin_art_open = "xor edx,edx" "mov art_file_position,ebp" value [edx] modify exact [edx];
extern const char *art_open_path(void);
#pragma aux art_open_path = value [eax] modify exact [];
extern void print_tile_request(void);
#pragma aux print_tile_request = "movsx eax,cx" "push eax" "push offset tile_load_message" "call printf" \
    "add esp,8" modify exact [eax];

extern void select_tile_cache_slot(void);
#pragma aux select_tile_cache_slot = "movsx edx,cx" "mov ebx,edx" "shl ebx,2" modify exact [edx ebx];
extern long tile_cache_byte_offset(void);
#pragma aux tile_cache_byte_offset = value [ebx] modify exact [];
extern void lock_current_art_tile(void);
#pragma aux lock_current_art_tile = "mov byte ptr [edx+walock],199" modify exact [];
extern void prepare_tile_allocation(void);
#pragma aux prepare_tile_allocation = "mov eax,offset waloff" "add edx,offset walock" "add eax,ebx" \
    "mov ebx,edx" "mov edx,esi" modify exact [eax ebx edx];
extern void *tile_address_slot(void);
#pragma aux tile_address_slot = value [eax] modify exact [];
extern void *tile_lock_slot(void);
#pragma aux tile_lock_slot = value [ebx] modify exact [];
extern long tile_allocation_bytes(void);
#pragma aux tile_allocation_bytes = value [edx] modify exact [];

extern long load_tile_offsets(void);
#pragma aux load_tile_offsets = "movsx edx,cx" "shl edx,2" "mov eax,art_file_position" \
    "mov ebx,dword ptr [edx+art_tile_offsets]" value [eax] modify exact [eax edx ebx];
extern long tile_file_offset(void);
#pragma aux tile_file_offset = value [ebx] modify exact [];
extern void prepare_art_seek(void);
#pragma aux prepare_art_seek = "mov edx,ebx" "mov ebx,1" "sub edx,eax" "mov eax,shutdown_art_handle" \
    modify exact [eax ebx edx];
extern long current_art_handle(void);
#pragma aux current_art_handle = value [eax] modify exact [];
extern long art_seek_distance(void);
#pragma aux art_seek_distance = value [edx] modify exact [];
extern long art_seek_origin(void);
#pragma aux art_seek_origin = value [ebx] modify exact [];
extern void setup_tile_read(void);
#pragma aux setup_tile_read = "mov eax,shutdown_art_handle" "movsx ecx,cx" "mov ebx,esi" \
    "mov edx,dword ptr [ecx*4+waloff]" modify exact [eax ebx ecx edx];
extern void *tile_read_destination(void);
#pragma aux tile_read_destination = value [edx] modify exact [];
extern long tile_read_bytes(void);
#pragma aux tile_read_bytes = value [ebx] modify exact [];
extern long tile_read_start(void);
#pragma aux tile_read_start = "mov eax,dword ptr [ecx*4+art_tile_offsets]" value [eax] modify exact [eax];
extern long tile_size_bytes(void);
#pragma aux tile_size_bytes = value [esi] modify exact [];
extern long art_position_in_eax(long position);
#pragma aux art_position_in_eax = "" parm [eax] value [eax] modify exact [];
#pragma aux loadtile modify exact [eax ebx ecx edx esi edi];

void loadtile(short tile)
{
    long width, height, old_handle;

    begin_tile_load(tile);
    width = load_tile_width(tilesizx[tile_index_in_ebx()]);
    height = load_tile_height(tilesizy[tile_index_in_ebx()]);
    validate_tile_bytes(height * width);
    if (read_new_art_number() != current_art_number()) {
        old_handle = art_handle_in_edi(shutdown_art_handle);
        if (old_handle != -1)
            shutdown_close_art(close_art_argument(old_handle));
        art_filename[7] = art_ones_digit();
        art_filename[6] = art_tens_digit();
        start_art_hundreds_digit();
        loaded_art_number = tile_index_in_ebx();
        art_filename[5] = art_hundreds_digit();
        shutdown_art_handle = open_tile_art(art_open_path(), begin_art_open());
        faketimerhandler();
    }
    if (debug_tile_loads)
        print_tile_request();

    select_tile_cache_slot();
    if (!*(long *)(waloff + tile_cache_byte_offset())) {
        lock_current_art_tile();
        prepare_tile_allocation();
        allocache(tile_address_slot(), tile_allocation_bytes(), tile_lock_slot());
    }
    /* The open ART handle keeps a cached position for consecutive reads. */
    if (load_tile_offsets() != tile_file_offset()) {
        prepare_art_seek();
        seek_tile_art(current_art_handle(), art_seek_distance(), art_seek_origin());
        faketimerhandler();
    }
    setup_tile_read();
    read_tile_art(current_art_handle(), tile_read_destination(), tile_read_bytes());
    faketimerhandler();
    art_file_position = art_position_in_eax(tile_read_start() + tile_size_bytes());
    finish_tile_load();
}
