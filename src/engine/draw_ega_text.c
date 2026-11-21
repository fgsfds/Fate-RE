/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern unsigned char pow2char[], textfont[], smalltextfont[];
extern void begin_ega_frame(long x, long y, long foreground, long background);
#pragma aux begin_ega_frame = "push esi" "push edi" "push ebp" "sub esp,24h" \
    "push edx" "push ebx" "mov esi,ecx" "mov edx,3ceh" "mov [esp+20h],eax" \
    parm [eax] [edx] [ebx] [ecx] modify exact [esi edx];
extern void write_ega_controller(long value);
#pragma aux write_ega_controller = "out dx,al" parm [eax] modify exact [];
extern long read_ega_controller(void);
#pragma aux read_ega_controller = "mov edx,3cfh" "in al,dx" value [eax] modify exact [eax edx];
extern void select_ega_controller(long index);
#pragma aux select_ega_controller = "mov edx,3ceh" "out dx,al" parm [eax] modify exact [edx];
extern void restore_ega_text_frame(void);
#pragma aux restore_ega_text_frame = "add esp,2ch" modify exact [];
extern void finish_ega_text(void);
#pragma aux finish_ega_text aborts modify exact [];
extern void split_ega_row_check(void);
#pragma aux split_ega_row_check aborts modify exact [];
extern void split_ega_row_start(void);
#pragma aux split_ega_row_start aborts modify exact [];
#pragma aux draw_ega_text modify exact [eax ebx ecx edx esi edi];

extern long ega_font_type(void);
#pragma aux ega_font_type = "xor eax,eax" "mov al,[esp+40h]" value [eax] modify exact [eax];
extern void select_small_ega_font(void);
#pragma aux select_small_ega_font = "mov ecx, offset smalltextfont" "mov edi, 4h" "mov [esp + 1ch], ecx" "mov [esp + 0ch], edi" modify exact [ecx edi];
extern void select_regular_ega_font(void);
#pragma aux select_regular_ega_font = "mov edx, offset textfont" "mov ebx, 8h" "mov [esp + 1ch], edx" "mov [esp + 0ch], ebx" modify exact [edx ebx];
extern void start_ega_characters(void);
#pragma aux start_ega_characters = "xor ebp, ebp" "mov [esp + 18h], ebp" modify exact [];
extern unsigned char get_ega_character(void);
#pragma aux get_ega_character = "mov eax, [esp + 3ch]" "add eax, [esp + 18h]" "mov dl, [eax]" value [dl] modify exact [eax edx];
extern void position_ega_glyph(void);
#pragma aux position_ega_glyph = "mov eax, [esp + 20h]" "mov [esp + 28h], dl" "mov edx, 8h" "and eax, 7h" \
    "sub edx, eax" "mov ch, [edx + pow2char]" "mov edx, [esp + 4h]" "mov ebx, [esp + 18h]" \
    "mov eax, edx" "inc ebx" "shl eax, 2h" "mov [esp + 18h], ebx" \
    "add eax, edx" "mov edx, [esp + 20h]" "shl eax, 4h" "sar edx, 3h" \
    "dec ch" "add eax, edx" "mov dh, [esp + 20h]" "lea ebx, [eax + 0a0000h]" modify exact [eax ebx ecx edx];
extern unsigned char ega_glyph_alignment(void);
#pragma aux ega_glyph_alignment = value [dh] modify exact [];
extern short ega_background(void);
#pragma aux ega_background = value [si] modify exact [];
/* Keep the byte-aligned row loop and its short, stack-relative test together. */
extern void draw_aligned_ega_glyph(void);
#pragma aux draw_aligned_ega_glyph = "xor ebp, ebp" "mov ecx, [esp + 1ch]" "jmp check_aligned_row" "aligned_row:" \
    "test si, si" "jl aligned_foreground" "mov eax, 0ffh" "mov edx, 3cfh" \
    "out dx, al" "cmp dword ptr [esp + 0ch], 4h" "jnz aligned_background_write" "mov eax, 7ch" \
    "out dx, al" "aligned_background_write:" "mov edi, ebx" "mov al, [edi]" \
    "movsx eax, si" "mov [edi], al" "aligned_foreground:" "movzx ebp, byte ptr [esp + 28h]" \
    "mov edx, [esp + 14h]" "shl ebp, 3h" "add ebp, edx" "add ebp, ecx" \
    "mov al, [ebp + 00h]" "mov edx, 3cfh" "and eax, 0ffh" "mov edi, [esp + 0ch]" \
    "out dx, al" "cmp edi, 4h" "jnz aligned_foreground_write" "mov al, [ebp + 00h]" \
    "and al, 7ch" "and eax, 0ffh" "out dx, al" "aligned_foreground_write:" \
    "mov edi, ebx" "mov al, [edi]" "movsx eax, word ptr [esp]" "mov ebp, [esp + 14h]" \
    "mov [edi], al" "inc ebp" "add ebx, 50h" "check_aligned_row:" \
    "mov [esp + 14h], ebp" "cmp dword ptr [esp + 14h], 8h" "jl aligned_row" modify exact [eax ebx ecx edx edi];
/* The split path writes each scanline across two adjacent EGA bytes. */
extern void setup_split_ega_glyph(void);
#pragma aux setup_split_ega_glyph = "xor edi,edi" "jmp split_ega_row_check" modify exact [edi];
extern long prepare_split_ega_background(void);
#pragma aux prepare_split_ega_background = "mov edx, [esp + 0ch]" "lea ebp, [ebx + 1h]" value [edx] modify exact [edx];
extern void draw_split_ega_large_background(void);
#pragma aux draw_split_ega_large_background = "xor eax, eax" "mov edx, 3cfh" "mov al, ch" "mov edi, ebx" \
    "out dx, al" "mov al, [edi]" "movsx eax, si" "mov [edi], al" \
    "xor eax, eax" "mov al, ch" "not eax" modify exact [eax edx edi];
extern void draw_split_ega_small_background(void);
#pragma aux draw_split_ega_small_background = "mov eax, [esp + 20h]" "and eax, 7h" "mov [esp + 8h], eax" "mov cl, [esp + 8h]" \
    "mov eax, 7ch" "mov edx, 3cfh" "sar eax, cl" "mov edi, ebx" \
    "out dx, al" "mov al, [edi]" "movsx eax, si" "mov [edi], al" \
    "mov eax, 8h" "sub eax, [esp + 8h]" "mov cl, al" "mov eax, 7ch" \
    "shl eax, cl" modify exact [eax ecx edx edi];
extern void finish_split_ega_background(void);
#pragma aux finish_split_ega_background = "mov edi, ebp" "out dx, al" "mov al, [edi]" "movsx eax, si" "mov [edi], al" modify exact [eax edi];
extern long prepare_split_ega_foreground(void);
#pragma aux prepare_split_ega_foreground = "xor eax, eax" "mov al, [esp + 28h]" "mov ebp, [esp + 14h]" "shl eax, 3h" \
    "mov edx, [esp + 1ch]" "add eax, ebp" "add eax, edx" "mov dl, [eax]" \
    "mov eax, [esp + 20h]" "mov edi, 8h" "and eax, 7h" "sub edi, eax" \
    "mov [esp + 24h], edi" "mov edi, [esp + 0ch]" "lea ebp, [ebx + 1h]" value [edi] modify exact [eax edx edi];
extern void draw_split_ega_large_foreground(void);
#pragma aux draw_split_ega_large_foreground = "and edx, 0ffh" "mov cl, al" "mov [esp + 8h], edx" "mov eax, edx" \
    "xor edx, edx" "mov edi, ebx" "mov dl, ch" "sar eax, cl" \
    "mov [esp + 10h], edx" "and eax, edx" "mov edx, 3cfh" "mov cl, [esp + 24h]" \
    "out dx, al" "mov al, [edi]" "movsx eax, word ptr [esp]" "mov edx, [esp + 8h]" \
    "mov [edi], al" "mov eax, [esp + 10h]" "shl edx, cl" "not eax" \
    "and eax, edx" "mov edx, 3cfh" modify exact [eax ecx edx edi];
extern void draw_split_ega_small_foreground(void);
#pragma aux draw_split_ega_small_foreground = "mov ah, dl" "and ah, 7ch" "xor edx, edx" "mov dl, ah" \
    "mov cl, al" "mov [esp + 10h], edx" "mov eax, edx" "mov edx, 3cfh" \
    "sar eax, cl" "mov edi, ebx" "out dx, al" "mov al, [edi]" \
    "movsx eax, word ptr [esp]" "mov cl, [esp + 24h]" "mov [edi], al" "mov eax, [esp + 10h]" \
    "shl eax, cl" modify exact [eax ecx edx edi];
extern void finish_split_ega_foreground(void);
#pragma aux finish_split_ega_foreground = "mov edi, ebp" "out dx, al" "mov al, [edi]" "movsx eax, word ptr [esp]" \
    "mov [edi], al" "mov edi, [esp + 14h]" "inc edi" "add ebx, 50h" modify exact [eax ebx edi];
extern void check_split_ega_row(void);
#pragma aux check_split_ega_row = "mov [esp+14h],edi" "cmp dword ptr [esp+14h],8" "jl split_ega_row_start" modify exact [];
extern void advance_ega_character(void);
#pragma aux advance_ega_character = "mov eax, [esp + 0ch]" "add [esp + 20h], eax" modify exact [eax];

void draw_ega_text(long x, long y, long foreground, long background,
                   const char *text, int small_font)
{
    /* Switch the controller to write mode 2 until the text ends. */
    begin_ega_frame(x, y, foreground, background);
    write_ega_controller(5);
    write_ega_controller((read_ega_controller() & 0xfc) + 2);
    select_ega_controller(8);
    if (ega_font_type() == 1)
        select_small_ega_font();
    else
        select_regular_ega_font();
    start_ega_characters();

next_character:
    if (!get_ega_character())
        goto done;
    position_ega_glyph();
    if (ega_glyph_alignment() & 7)
        goto split;
    draw_aligned_ega_glyph();
    goto advance;

split:
    setup_split_ega_glyph();
    if (ega_background() >= 0) {
        if (prepare_split_ega_background() == 8)
            draw_split_ega_large_background();
        else
            draw_split_ega_small_background();
        finish_split_ega_background();
    }
    if (prepare_split_ega_foreground() == 8)
        draw_split_ega_large_foreground();
    else
        draw_split_ega_small_foreground();
    finish_split_ega_foreground();
    check_split_ega_row();

advance:
    advance_ega_character();
    goto next_character;

done:
    select_ega_controller(5);
    write_ega_controller(read_ega_controller() & 0xfc);
    restore_ega_text_frame();
    finish_ega_text();
}
