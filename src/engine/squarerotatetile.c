/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern short tilesizx[], tilesizy[];
extern unsigned char *waloff[];
extern void restore_square_tile_rotation(void);
#pragma aux restore_square_tile_rotation aborts modify exact [eax];

/* Preserve the register frame consumed by the shared return. */
extern int square_tile_entry(short tile);
#pragma aux square_tile_entry = "push ebx" "push ecx" "push edx" "push esi" "push edi" "push ebp" \
    "sub esp,10h" "push eax" "cwde" parm [ax] value [eax] modify exact [eax];
extern int tile_width_in_edi(int width);
#pragma aux tile_width_in_edi = "" parm [edi] value [edi] modify exact [];
extern void check_square_tile(int width, int height);
#pragma aux check_square_tile = "mov dword ptr [esp+0ch],edi" "cmp eax,edi" \
    "jne restore_square_tile_rotation" parm [edi] [eax] modify exact [];
extern void prepare_tile_columns(int width);
#pragma aux prepare_tile_columns = "lea eax,[edi+edi]" "mov dword ptr [esp+8],eax" \
    "lea eax,[edi-1]" "mov dword ptr [esp+4],eax" parm [edi] modify exact [eax];
extern int tile_column(void);
#pragma aux tile_column = "mov ebx,dword ptr [esp+4]" value [ebx] modify exact [ebx];
extern int prepare_tile_column(int column);
#pragma aux prepare_tile_column = "mov ebp,dword ptr [esp+0ch]" "inc ebp" "imul ebp,ebx" \
    "movsx edi,word ptr [esp]" parm [ebx] value [edi] modify exact [edi];
extern unsigned char *tile_pixels_in_edi(unsigned char *pixels);
#pragma aux tile_pixels_in_edi = "" parm [edi] value [edi] modify exact [];
extern unsigned char tile_column_low_byte(unsigned char *pixels);
#pragma aux tile_column_low_byte = "add edi,ebp" "mov ah,byte ptr [esp+4]" "mov ebp,edi" \
    parm [edi] value [ah] modify exact [ah];
extern void exchange_unpaired_pixel(void);
#pragma aux exchange_unpaired_pixel = "mov esi,dword ptr [esp+0ch]" "dec edi" "sub ebp,esi" \
    "mov eax,edi" "mov ebx,ebp" "mov cl,[eax]" "mov ch,[ebx]" "mov [ebx],cl" "mov [eax],ch" \
    modify exact [eax ebx ecx esi edi];
/* Exchange adjacent pixels with two pixels spaced one row apart. */
extern void transpose_tile_pixel_pairs(void);
#pragma aux transpose_tile_pixel_pairs = \
    "mov eax,dword ptr [esp+4]" "sar eax,1" "dec eax" "mov dword ptr [esp+10h],eax" \
    "jmp check_pair" "swap_pair:" "mov ebx,dword ptr [esp+8]" "mov esi,dword ptr [esp+0ch]" \
    "sub edi,2" "sub ebp,ebx" "mov eax,edi" "mov ebx,ebp" "add esi,ebx" \
    "mov cx,[eax]" "mov dl,[ebx]" "mov [ebx],cl" "mov dh,[esi]" "mov [esi],ch" "mov [eax],dx" \
    "dec dword ptr [esp+10h]" "check_pair:" "cmp dword ptr [esp+10h],0" "jge swap_pair" \
    modify exact [eax ebx ecx edx esi edi];
extern void previous_tile_column(void);
#pragma aux previous_tile_column = "dec dword ptr [esp+4]" modify exact [];
#pragma aux squarerotatetile modify exact [eax ebx ecx edx esi edi];

void squarerotatetile(short tile)
{
    int index = square_tile_entry(tile);
    int width = tile_width_in_edi(tilesizx[index]);
    int height = tilesizy[index];
    int column;

    check_square_tile(width, height);
    prepare_tile_columns(width);
    /* Walk backwards across each column above the diagonal. */
    goto check_column;
    do {
        unsigned char *pixels = tile_pixels_in_edi(waloff[prepare_tile_column(column)]);
        if (tile_column_low_byte(pixels) & 1)
            exchange_unpaired_pixel();
        transpose_tile_pixel_pairs();
        previous_tile_column();
check_column:;
    } while ((column = tile_column()) >= 0);
    restore_square_tile_rotation();
}
