/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern short numpalookups;
extern unsigned char palookup[], palette[], palette_lock, palette_loaded;

extern void finish_palookup(void);
#pragma aux finish_palookup aborts modify exact [];
extern void done_palookup(void);
#pragma aux done_palookup aborts modify exact [];
extern long getclosestcol(long r, long g, long b);
#pragma aux getclosestcol parm [eax] [edx] [ebx] value [eax] modify exact [eax ebx edx];
extern long engine_malloc(long length);
#pragma aux engine_malloc parm [eax] value [eax] modify exact [eax];
extern void allocache(void *slot, long length, void *lock);
#pragma aux allocache parm [eax] [edx] [ebx] modify exact [eax ebx edx];

/* Preserve the remap pointer and the low-byte tint fields in the historical frame. */
extern void begin_palookup(long slot, const unsigned char *remap, int r, int g);
#pragma aux begin_palookup = "push esi" "push edi" "push ebp" "sub esp,18h" \
    "mov ebp,eax" "mov [esp+0ch],edx" "mov [esp+14h],bl" "mov [esp+10h],cl" \
    parm [eax] [edx] [ebx] [ecx] modify exact [];
extern void prepare_palookup_slot(void);
#pragma aux prepare_palookup_slot = "mov ecx,ebp" "shl ecx,2" modify exact [ecx];
extern long palookup_slot(void);
#pragma aux palookup_slot = value [ecx] modify exact [];
extern long current_shade_count(void);
#pragma aux current_shade_count = "movsx eax,numpalookups" value [eax] modify exact [eax];
extern void prepare_palette_cache(void);
#pragma aux prepare_palette_cache = "mov eax,offset palookup" "movsx edx,numpalookups" \
    "mov ebx,offset palette_lock" "shl edx,8" "add eax,ecx" modify exact [eax ebx edx];
extern void *palette_cache_slot(void);
#pragma aux palette_cache_slot = value [eax] modify exact [];
extern long palette_cache_size(void);
#pragma aux palette_cache_size = value [edx] modify exact [];
extern void *palette_cache_lock(void);
#pragma aux palette_cache_lock = value [ebx] modify exact [];
/* The build flag is checked in place before jumping to frame cleanup. */
extern void require_palette_generation(void);
#pragma aux require_palette_generation = "cmp byte ptr [esp+2ch],0" "je done_palookup" modify exact [];
extern long tint_validity_mask(void);
#pragma aux tint_validity_mask = "movsx eax,byte ptr [esp+14h]" "movsx edx,byte ptr [esp+10h]" \
    "or eax,edx" "movsx edx,byte ptr [esp+28h]" "or eax,edx" "mov edx,eax" "or dl,3fh" \
    value [edx] modify exact [eax edx];
extern long tint_mask(void);
#pragma aux tint_mask = value [eax] modify exact [];
extern void begin_plain_remap(void);
#pragma aux begin_plain_remap = "mov [esp+8],eax" modify exact [];
extern void prepare_remap_column(void);
#pragma aux prepare_remap_column = "mov eax,[esp+0ch]" "mov edi,dword ptr [palookup]" "add eax,ecx" \
    "xor ecx,ecx" "mov esi,dword ptr [ebp*4+palookup]" "mov cl,[eax]" "mov eax,[esp+8]" \
    "add ecx,edi" "add esi,eax" "xor edi,edi" modify exact [eax ecx esi edi];
extern unsigned char read_remapped_shade(void);
#pragma aux read_remapped_shade = "inc edi" "mov al,[ecx]" "add ecx,100h" \
    value [al] modify exact [eax ecx edi];
extern unsigned char *palookup_output(void);
#pragma aux palookup_output = value [esi] modify exact [];
extern void next_remapped_shade(void);
#pragma aux next_remapped_shade = "add esi,100h" modify exact [esi];
extern long active_plain_shade(void);
#pragma aux active_plain_shade = value [edi] modify exact [];
extern void next_palookup_index(void);
#pragma aux next_palookup_index = "inc dword ptr [esp+8]" modify exact [];
extern long remap_column_index(void);
#pragma aux remap_column_index = "mov ecx,[esp+8]" value [ecx] modify exact [ecx];

extern void begin_tinted_remap(void);
#pragma aux begin_tinted_remap = "xor ebx,ebx" "mov esi,dword ptr [ebp*4+palookup]" \
    "mov [esp+8],ebx" modify exact [ebx esi];
extern long tinted_shade_index(void);
#pragma aux tinted_shade_index = "mov edi,[esp+8]" value [edi] modify exact [edi];
extern void begin_tinted_shade(void);
#pragma aux begin_tinted_shade = "mov ax,numpalookups" "movsx ebx,ax" "mov eax,edi" "mov edx,eax" \
    "sar edx,10h" "shl eax,10h" "idiv ebx" "mov ebp,eax" "xor edi,edi" modify exact [eax ebx edx edi];
extern long tinted_color_index(void);
#pragma aux tinted_color_index = value [edi] modify exact [];
extern void prepare_tint_color(void);
#pragma aux prepare_tint_color = "mov eax,[esp+0ch]" "mov al,[edi+eax*1]" "and eax,0ffh" \
    "mov ecx,eax" "shl ecx,2" "sub ecx,eax" "add ecx,offset palette" modify exact [eax ecx];
extern void blend_blue_channel(void);
#pragma aux blend_blue_channel = "xor eax,eax" "mov al,[ecx+2]" "mov [esp],eax" "movsx eax,byte ptr [esp+28h]" \
    "mov edx,[esp]" "mov ebx,ebp" "sub eax,edx" "imul ebx" "shrd eax,edx,10h" \
    "mov edx,[esp]" "add edx,eax" modify exact [eax ebx edx];
extern void blend_green_channel(void);
#pragma aux blend_green_channel = "xor eax,eax" "mov al,[ecx+1]" "mov [esp+4],eax" "movsx eax,byte ptr [esp+10h]" \
    "sub eax,[esp+4]" "mov ebx,ebp" "mov [esp],edx" "imul ebx" "shrd eax,edx,10h" \
    "mov edx,[esp+4]" "add edx,eax" modify exact [eax ebx edx];
extern void blend_red_channel(void);
#pragma aux blend_red_channel = "mov cl,[ecx]" "mov [esp+4],edx" "movsx eax,byte ptr [esp+14h]" "and ecx,0ffh" \
    "sub eax,ecx" "imul ebx" "shrd eax,edx,10h" "mov ebx,[esp]" "mov edx,[esp+4]" "add eax,ecx" "inc edi" \
    modify exact [eax ebx ecx edx edi];
extern long tinted_red(void);
#pragma aux tinted_red = value [eax] modify exact [];
extern long tinted_green(void);
#pragma aux tinted_green = value [edx] modify exact [];
extern long tinted_blue(void);
#pragma aux tinted_blue = value [ebx] modify exact [];
extern void next_tinted_output(void);
#pragma aux next_tinted_output = "inc esi" modify exact [esi];
extern void discard_palette_frame(void);
#pragma aux discard_palette_frame = "add esp,18h" modify exact [];
#pragma aux makepalookup modify exact [eax ebx ecx edx esi edi];

void makepalookup(long slot, const unsigned char *remap, int r, int g, int b, int build)
{
    long value, shade;
    unsigned char pixel;

    begin_palookup(slot, remap, r, g);
    if (!palette_loaded)
        goto done;
    prepare_palookup_slot();
    if (!*(long *)(palookup + palookup_slot())) {
        value = engine_malloc(current_shade_count() << 8);
        *(long *)(palookup + palookup_slot()) = value;
        if (!value) {
            prepare_palette_cache();
            allocache(palette_cache_slot(), palette_cache_size(), palette_cache_lock());
        }
    }
    require_palette_generation();
    if (tint_validity_mask() != 63)
        goto done;
    if (tint_mask())
        goto tinted;

    /* An untinted remap copies the matching columns from the base shade table. */
    begin_plain_remap();
    goto check_remap_column;
    do {
        prepare_remap_column();
        goto check_remap_shade;
        do {
            pixel = read_remapped_shade();
            *palookup_output() = pixel;
            next_remapped_shade();
check_remap_shade:;
        } while (active_plain_shade() < current_shade_count());
        next_palookup_index();
check_remap_column:;
    } while (remap_column_index() < 256);
    goto done;

tinted:
    /* Each shade interpolates the remapped color toward the tint in 16.16. */
    begin_tinted_remap();
    goto check_tinted_shade;
    do {
        begin_tinted_shade();
        goto check_tinted_color;
        do {
            prepare_tint_color();
            blend_blue_channel();
            blend_green_channel();
            blend_red_channel();
            pixel = (unsigned char)getclosestcol(tinted_red(), tinted_green(), tinted_blue());
            *palookup_output() = pixel;
            next_tinted_output();
check_tinted_color:;
        } while (tinted_color_index() < 256);
        next_palookup_index();
check_tinted_shade:
        shade = tinted_shade_index();
    } while (current_shade_count() > shade);
done:
    discard_palette_frame();
    finish_palookup();
}
