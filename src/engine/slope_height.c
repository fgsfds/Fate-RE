/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern int sector_wallptr, wall_point2;
extern long wall_x, wall_y;
extern short ceiling_flags, ceiling_heinum;
extern long ceiling_z;
extern short floor_flags, floor_heinum;
extern long floor_z;
extern unsigned short sqrtable[];

extern void slope_frame(int sector, long x, long y);
#pragma aux slope_frame = \
    "push ecx" "push esi" "push edi" "push ebp" "sub esp,4" "push edx" "push ebx" \
    "cwde" "mov ebp,eax" "shl ebp,2" "add ebp,eax" "shl ebp,3" \
    parm [eax] [edx] [ebx] modify exact [eax];

extern int ceiling_is_sloped(void);
#pragma aux ceiling_is_sloped = "mov ax,[ebp+ceiling_flags]" "xor ah,ah" "and al,2" "cwde" \
    value [eax] modify exact [eax];

extern long base_ceiling_height(void);
#pragma aux base_ceiling_height = "mov eax,[ebp+ceiling_z]" value [eax] modify exact [eax];

/* Preserve signed wall deltas in the original scratch slots and calculate dx^2 + dy^2. */
extern long first_wall_length_squared(void);
#pragma aux first_wall_length_squared = \
    "movsx esi,word ptr [ebp+sector_wallptr]" "shl esi,5" \
    "movsx eax,word ptr [esi+wall_point2]" "shl eax,5" \
    "mov edx,[esi+wall_x]" "mov edi,[eax+wall_x]" "sub edi,edx" "mov [esp+8],edi" \
    "mov edi,[eax+wall_y]" "mov eax,[esp+8]" "imul eax,eax" "mov ebx,[esi+wall_y]" \
    "sub edi,ebx" "mov edx,edi" "imul edx,edi" "add eax,edx" \
    value [eax] modify exact [eax ebx edx esi edi];

/* The same table-based square-root sequence as ksqrt(). */
extern long slope_wall_length(long squared_length);
#pragma aux slope_wall_length = \
    "test eax,eax" "jns sqrt" "neg eax" "sqrt: bsr ecx,eax" "cmp cl,11" "jge scaled" \
    "movzx eax,word ptr sqrtable[eax*2]" "jmp end_sqrt" \
    "scaled: sub cl,9" "and cl,0feh" "sar eax,cl" \
    "movzx eax,word ptr sqrtable[eax*2]" "sar cl,1" "shl eax,cl" "end_sqrt: sar eax,10" \
    parm [eax] value [eax] modify exact [eax ecx];

/* The sector coefficient is normalized by the measured wall length in 15 fractional bits. */
extern long normalize_ceiling_coefficient(long length);
#pragma aux normalize_ceiling_coefficient = \
    "mov dx,[ebp+ceiling_heinum]" "mov ebx,eax" "movsx eax,dx" \
    "mov edx,eax" "sar edx,17" "shl eax,15" "idiv ebx" \
    parm [eax] value [eax] modify exact [eax ebx edx];

/* Project the location relative to the wall onto its signed normal. */
extern long slope_height_offset(long coefficient);
#pragma aux slope_height_offset = \
    "imul edi,eax" "mov edx,[esp+8]" "imul edx,eax" "mov ebx,[esp]" "mov [esp+8],edx" \
    "mov eax,[esi+wall_x]" "mov edx,[esp+4]" "mov ecx,[esi+wall_y]" "sub edx,eax" \
    "mov eax,edi" "sub ebx,ecx" "neg eax" "mov edi,edx" "mov esi,eax" "mov eax,[esp+8]" \
    "imul ebx" "xchg esi,eax" "mov ebx,edx" "imul edi" "add eax,esi" "adc edx,ebx" \
    "shrd eax,edx,23" parm [eax] value [eax] modify exact [eax ebx ecx edx esi edi];
extern long add_base_ceiling_height(long offset);
#pragma aux add_base_ceiling_height = "add eax,[ebp+ceiling_z]" parm [eax] value [eax] modify exact [eax];

extern long finish_slope_height(long height);
#pragma aux finish_slope_height aborts parm [eax] modify exact [eax];
extern long getceilzofslope(int, long, long);
#pragma aux getceilzofslope parm [eax] [edx] [ebx] modify exact [eax ebx ecx edx esi edi];

long getceilzofslope(int sector, long x, long y)
{
    long length;
    slope_frame(sector, x, y);
    if (ceiling_is_sloped())
        goto measure;
flat:
    return finish_slope_height(base_ceiling_height());
measure:
    length = slope_wall_length(first_wall_length_squared());
    if (length == 0)
        goto flat;
    return finish_slope_height(add_base_ceiling_height(slope_height_offset(normalize_ceiling_coefficient(length))));
}

extern int floor_is_sloped(void);
#pragma aux floor_is_sloped = "mov ax,[ebp+floor_flags]" "xor ah,ah" "and al,2" "cwde" \
    value [eax] modify exact [eax];

extern long base_floor_height(void);
#pragma aux base_floor_height = "mov eax,[ebp+floor_z]" value [eax] modify exact [eax];

extern long normalize_floor_coefficient(long length);
#pragma aux normalize_floor_coefficient = \
    "mov dx,[ebp+floor_heinum]" "mov ebx,eax" "movsx eax,dx" \
    "mov edx,eax" "sar edx,17" "shl eax,15" "idiv ebx" \
    parm [eax] value [eax] modify exact [eax ebx edx];

extern long add_base_floor_height(long offset);
#pragma aux add_base_floor_height = "add eax,[ebp+floor_z]" parm [eax] value [eax] modify exact [eax];

extern long getflorzofslope(int, long, long);
#pragma aux getflorzofslope parm [eax] [edx] [ebx] modify exact [eax ebx ecx edx esi edi];

long getflorzofslope(int sector, long x, long y)
{
    long length;
    slope_frame(sector, x, y);
    if (floor_is_sloped())
        goto measure;
flat:
    return finish_slope_height(base_floor_height());
measure:
    length = slope_wall_length(first_wall_length_squared());
    if (length == 0)
        goto flat;
    return finish_slope_height(add_base_floor_height(slope_height_offset(normalize_floor_coefficient(length))));
}
