/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern unsigned char video_backend;
extern long shutdown_art_handle;
extern void *translucency_table, *art_tile_cache, *software_framebuffer;
extern void *horizon_reciprocals, *horizon_aspect;
extern unsigned char palookup[];

extern void kfree(void *buffer);
#pragma aux kfree parm [eax] modify exact [eax];
extern void shutdown_video_backend(void);
#pragma aux shutdown_video_backend modify exact [eax];
extern void shutdown_close_art(long handle);
#pragma aux shutdown_close_art parm [eax] modify exact [eax];
extern void finish_video_shutdown(void);
#pragma aux finish_video_shutdown aborts modify exact [];

/* Restore the PIT divider and preserve the frame for the shared return. */
extern void begin_video_shutdown(void);
#pragma aux begin_video_shutdown = "push ebx" "push ecx" "push edx" "push esi" \
    "push edi" "push ebp" "mov eax,36h" "mov edx,43h" "out dx,al" \
    "mov eax,0ffh" "mov edx,40h" "out dx,al" "out dx,al" modify exact [eax edx];
extern long active_video_backend(void);
#pragma aux active_video_backend = "xor eax,eax" "mov al,video_backend" value [eax] modify exact [eax];
extern long handle_in_edx(long handle);
#pragma aux handle_in_edx = "" parm [edx] value [edx] modify exact [];
extern long art_handle_for_close(long handle);
#pragma aux art_handle_for_close = "mov eax,edx" parm [edx] value [eax] modify exact [eax];
extern void load_software_framebuffer(void);
#pragma aux load_software_framebuffer = "mov ebp,software_framebuffer" modify exact [];
extern void *framebuffer_in_ebp(void);
#pragma aux framebuffer_in_ebp = value [ebp] modify exact [];
extern void *framebuffer_for_free(void);
#pragma aux framebuffer_for_free = "mov eax,ebp" value [eax] modify exact [eax];
extern void *zero_eax(void);
#pragma aux zero_eax = "xor eax,eax" value [eax] modify exact [eax];

extern void begin_palette_cleanup(void);
#pragma aux begin_palette_cleanup = "xor ebx,ebx" modify exact [ebx];
extern void prepare_palette_slot(void);
#pragma aux prepare_palette_slot = "mov edx,ebx" "shl edx,2" modify exact [edx];
extern long palette_slot_offset(void);
#pragma aux palette_slot_offset = value [edx] modify exact [];
extern void next_palette_slot(void);
#pragma aux next_palette_slot = "inc ebx" modify exact [ebx];
extern long palette_slot_index(void);
#pragma aux palette_slot_index = value [ebx] modify exact [];
extern void *palette_release_argument(void *pointer);
#pragma aux palette_release_argument = "mov eax,edi" "xor ebp,ebp" parm [edi] value [eax] modify exact [eax];
extern void *palette_null(void);
#pragma aux palette_null = value [ebp] modify exact [];

#pragma aux shutdown_video_engine modify exact [eax ebx ecx edx esi edi];

extern void *translucency_pointer(void *pointer);
#pragma aux translucency_pointer = "" parm [ebx] value [ebx] modify exact [];
extern void *translucency_release_argument(void *pointer);
#pragma aux translucency_release_argument = "mov eax,ebx" "xor ecx,ecx" parm [ebx] value [eax] modify exact [eax ecx];
extern void *translucency_null(void);
#pragma aux translucency_null = value [ecx] modify exact [];
extern void *tile_cache_pointer(void *pointer);
#pragma aux tile_cache_pointer = "" parm [esi] value [esi] modify exact [];
extern void *tile_cache_release_argument(void *pointer);
#pragma aux tile_cache_release_argument = "mov eax,esi" "xor edi,edi" parm [esi] value [eax] modify exact [eax edi];
extern void *tile_cache_null(void);
#pragma aux tile_cache_null = value [edi] modify exact [];
extern void *reciprocals_pointer(void *pointer);
#pragma aux reciprocals_pointer = "" parm [edx] value [edx] modify exact [];
extern void *reciprocals_release_argument(void *pointer);
#pragma aux reciprocals_release_argument = "mov eax,edx" "xor ebx,ebx" parm [edx] value [eax] modify exact [eax ebx];
extern void *reciprocals_null(void);
#pragma aux reciprocals_null = value [ebx] modify exact [];
extern void *aspect_pointer(void *pointer);
#pragma aux aspect_pointer = "" parm [ecx] value [ecx] modify exact [];
extern void *aspect_release_argument(void *pointer);
#pragma aux aspect_release_argument = "mov eax,ecx" "xor esi,esi" parm [ecx] value [eax] modify exact [eax esi];
extern void *aspect_null(void);
#pragma aux aspect_null = value [esi] modify exact [];
extern void *palette_pointer(void *pointer);
#pragma aux palette_pointer = "" parm [edi] value [edi] modify exact [];

void shutdown_video_engine(void)
{
    long handle;
    void *buffer;

    begin_video_shutdown();
    if (active_video_backend() == 1)
        shutdown_video_backend();
    handle = handle_in_edx(shutdown_art_handle);
    if (handle != -1)
        shutdown_close_art(art_handle_for_close(handle));

    buffer = translucency_pointer(translucency_table);
    if (buffer) {
        kfree(translucency_release_argument(buffer));
        translucency_table = translucency_null();
    }
    buffer = tile_cache_pointer(art_tile_cache);
    if (buffer) {
        kfree(tile_cache_release_argument(buffer));
        art_tile_cache = tile_cache_null();
    }
    load_software_framebuffer();
    if (framebuffer_in_ebp()) {
        kfree(framebuffer_for_free());
        software_framebuffer = zero_eax();
    }
    buffer = reciprocals_pointer(horizon_reciprocals);
    if (buffer) {
        kfree(reciprocals_release_argument(buffer));
        horizon_reciprocals = reciprocals_null();
    }
    buffer = aspect_pointer(horizon_aspect);
    if (buffer) {
        kfree(aspect_release_argument(buffer));
        horizon_aspect = aspect_null();
    }

    /* Palette banks are allocated and released separately. */
    begin_palette_cleanup();
    goto check_palette;
    do {
        prepare_palette_slot();
        buffer = palette_pointer(*(void **)(palookup + palette_slot_offset()));
        if (buffer) {
            kfree(palette_release_argument(buffer));
            *(void **)(palookup + palette_slot_offset()) = palette_null();
        }
        next_palette_slot();
check_palette:;
    } while (palette_slot_index() < 256);
    finish_video_shutdown();
}
