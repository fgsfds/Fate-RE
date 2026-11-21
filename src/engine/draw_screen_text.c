/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern unsigned char chainstat, textfont[], smalltextfont[], pow2char[];
extern long chainplace, draw_page_address, ylookup[], pow2long[];

/* Preserve the coordinates and colors in the frame used by the shared return. */
extern void begin_screen_text(long x, long y, long foreground, long background);
#pragma aux begin_screen_text = "push esi" "push edi" "push ebp" "sub esp,18h" \
    "push edx" "push ebx" "push ecx" "mov [esp+20h],eax" \
    parm [eax] [edx] [ebx] [ecx] modify exact [];
extern void select_screen_text_font(void);
#pragma aux select_screen_text_font = "cmp byte ptr [esp+38h],0" "jz large_font" \
    "mov ecx,offset smalltextfont" "mov esi,4" "mov [esp+14h],ecx" "mov [esp+1ch],esi" "jmp font_ready" \
    "large_font:" "mov edx,offset textfont" "mov ebx,8" "mov [esp+14h],edx" "mov [esp+1ch],ebx" "font_ready:" \
    modify exact [ebx ecx edx esi];
extern void begin_planar_text(void);
#pragma aux begin_planar_text = "mov eax,2" "mov edx,3c4h" "xor ebp,ebp" "out dx,al" \
    "mov [esp+18h],ebp" modify exact [eax edx];
extern unsigned char next_planar_character(void);
#pragma aux next_planar_character = "mov eax,[esp+34h]" "add eax,[esp+18h]" "mov bl,[eax]" \
    value [bl] modify exact [eax ebx];
extern void prepare_planar_glyph(void);
#pragma aux prepare_planar_glyph = "mov al,bl" "mov ebp,[esp+14h]" "mov edi,[esp+8]" "mov esi,7" \
    "and eax,0ffh" "mov ebx,chainplace" "shl eax,3" "mov edi,[edi*4+ylookup+1ch]" \
    "add ebp,eax" "add edi,ebx" modify exact [eax ebx esi edi];
extern void begin_glyph_columns(void);
#pragma aux begin_glyph_columns = "mov ebx,[esp+1ch]" modify exact [ebx];
extern long preceding_glyph_column(void);
#pragma aux preceding_glyph_column = "dec ebx" value [ebx] modify exact [ebx];
extern long glyph_row(void);
#pragma aux glyph_row = value [esi] modify exact [];
extern void preceding_glyph_row(void);
#pragma aux preceding_glyph_row = "mov eax,dword ptr [ylookup+4]" "dec esi" "sub edi,eax" \
    modify exact [eax esi edi];
extern void advance_screen_character(void);
#pragma aux advance_screen_character = "mov eax,[esp+1ch]" "mov ecx,[esp+20h]" \
    "mov esi,[esp+18h]" "add ecx,eax" "inc esi" "mov [esp+20h],ecx" "mov [esp+18h],esi" \
    modify exact [eax ecx esi];

extern void prepare_planar_text_pixel(void);
#pragma aux prepare_planar_text_pixel = "xor eax,eax" "mov ecx,7" "mov al,[esp+38h]" "sub ecx,eax" \
    "sub ecx,ebx" "xor edx,edx" "mov dl,[ecx+pow2char]" "mov [esp+10h],edx" \
    "xor edx,edx" "mov dl,[esi+ebp]" "mov [esp+0ch],edx" "mov edx,[esp+20h]" "add edx,ebx" \
    "sub edx,eax" "mov eax,edx" "sar eax,2" "and edx,3" "lea ecx,[edi+eax*1]" "mov eax,edx" \
    "mov edx,[esp+0ch]" "shl eax,2" modify exact [eax ecx edx];
/* Select the VGA plane before writing an opaque or foreground pixel. */
extern void plot_planar_text_pixel(void);
#pragma aux plot_planar_text_pixel = "test [esp+10h],edx" "jz planar_background" \
    "mov edx,3c5h" "mov eax,[eax+pow2long]" "out dx,al" "mov al,[esp+4]" "jmp planar_write" \
    "planar_background:" "cmp word ptr [esp],0" "jl planar_skip" \
    "mov edx,3c5h" "mov eax,[eax+pow2long]" "out dx,al" "mov al,[esp]" \
    "planar_write:" "mov [ecx],al" "planar_skip:" modify exact [eax edx];

extern void begin_linear_text(void);
#pragma aux begin_linear_text = "xor edi,edi" "mov [esp+18h],edi" modify exact [edi];
extern unsigned char next_linear_character(void);
#pragma aux next_linear_character = "mov eax,[esp+34h]" "add eax,[esp+18h]" "mov dh,[eax]" \
    value [dh] modify exact [eax edx];
extern void prepare_linear_glyph(void);
#pragma aux prepare_linear_glyph = "mov al,dh" "mov ebp,[esp+14h]" "mov ebx,[esp+20h]" "and eax,0ffh" \
    "xor edx,edx" "shl eax,3" "mov dl,[esp+38h]" "add ebp,eax" "sub ebx,edx" "mov eax,[esp+8]" \
    "mov edx,ebx" "mov ebx,[eax*4+ylookup+1ch]" "mov edi,draw_page_address" "add edx,ebx" "mov esi,7" \
    "add edi,edx" modify exact [eax ebx edx esi edi];
extern void prepare_linear_text_pixel(void);
#pragma aux prepare_linear_text_pixel = "xor eax,eax" "mov edx,7" "mov al,[esp+38h]" \
    "sub edx,eax" "mov eax,edx" "sub eax,ebx" "xor ecx,ecx" "xor edx,edx" \
    "mov cl,[eax+pow2char]" "mov dl,[esi+ebp]" "lea eax,[edi+ebx*1]" modify exact [eax ecx edx];
/* Foreground and opaque background share a single byte store. */
extern void plot_linear_text_pixel(void);
#pragma aux plot_linear_text_pixel = "test edx,ecx" "jz linear_background" \
    "mov dl,[esp+4]" "jmp linear_write" "linear_background:" "cmp word ptr [esp],0" \
    "jl linear_skip" "mov dl,[esp]" "linear_write:" "mov [eax],dl" "linear_skip:" modify exact [edx];
extern void drop_text_frame(void);
#pragma aux drop_text_frame = "add esp,24h" modify exact [];
extern void finish_screen_text(void);
#pragma aux finish_screen_text aborts modify exact [];
#pragma aux draw_screen_text modify exact [eax ebx ecx edx esi edi];

void draw_screen_text(long x, long y, long foreground, long background,
                      const char *text, int small_font)
{
    begin_screen_text(x, y, foreground, background);
    select_screen_text_font();

    if (!chainstat)
        goto linear;
    begin_planar_text();
    goto check_planar_character;
    do {
        prepare_planar_glyph();
        goto check_planar_row;
        do {
            begin_glyph_columns();
            goto check_planar_column;
            do {
                prepare_planar_text_pixel();
                plot_planar_text_pixel();
check_planar_column:;
            } while (preceding_glyph_column() >= 0);
            preceding_glyph_row();
check_planar_row:;
        } while (glyph_row() >= 0);
        advance_screen_character();
check_planar_character:;
    } while (next_planar_character());
    goto done;

linear:
    begin_linear_text();
    goto check_linear_character;
    do {
        prepare_linear_glyph();
        goto check_linear_row;
        do {
            begin_glyph_columns();
            goto check_linear_column;
            do {
                prepare_linear_text_pixel();
                plot_linear_text_pixel();
check_linear_column:;
            } while (preceding_glyph_column() >= 0);
            preceding_glyph_row();
check_linear_row:;
        } while (glyph_row() >= 0);
        advance_screen_character();
check_linear_character:;
    } while (next_linear_character());
done:
    drop_text_frame();
    finish_screen_text();
}
