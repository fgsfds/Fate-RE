/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern unsigned char sector[], wall[];
extern unsigned short sqrtable[];

/* Preserve the frame used by the shared return and resolve the sector. */
extern void begin_combined_height(short sector_index, long x, long y, long *ceiling);
#pragma aux begin_combined_height = "push esi" "push edi" "push ebp" "sub esp,8" \
    "push edx" "push ebx" "push ecx" "cwde" "mov esi,eax" "shl esi,2" "add esi,eax" \
    "mov ebp,offset sector" "shl esi,3" "add ebp,esi" parm [ax] [edx] [ebx] [ecx] modify exact [eax esi];
extern long *initial_ceiling_output(void);
#pragma aux initial_ceiling_output = value [ecx] modify exact [];
extern long initial_ceiling_height(void);
#pragma aux initial_ceiling_height = "mov eax,[ebp+4]" value [eax] modify exact [eax];
extern long initial_floor_height(void);
#pragma aux initial_floor_height = "mov eax,[ebp+8]" value [eax] modify exact [eax];
extern long *floor_height_output(void);
#pragma aux floor_height_output = "mov edx,[esp+36]" value [edx] modify exact [edx];
extern long *ceiling_height_output(void);
#pragma aux ceiling_height_output = "mov edx,[esp]" value [edx] modify exact [edx];
extern long both_slope_flags(void);
#pragma aux both_slope_flags = "movsx edx,word ptr [ebp+12]" "movsx eax,word ptr [ebp+14]" \
    "or eax,edx" value [eax] modify exact [eax edx];
/* Measure the first wall and keep its deltas for the slope projection. */
extern void measure_combined_wall_square(void);
#pragma aux measure_combined_wall_square = "movsx eax,word ptr [ebp]" "mov esi,offset wall" \
    "shl eax,5" "add esi,eax" "movsx eax,word ptr [esi+8]" "shl eax,5" "add eax,offset wall" \
    "mov ebx,[esi]" "mov edx,[eax]" "sub edx,ebx" "mov [esp+16],edx" "imul edx,edx" \
    "mov ecx,[esi+4]" "mov edi,[eax+4]" "sub edi,ecx" "mov eax,edi" "imul eax,edi" \
    "add eax,edx" "test eax,eax" "jns square_ready" "neg eax" "square_ready:" modify exact [eax ebx ecx edx esi edi];
extern long combined_wall_squared(void);
#pragma aux combined_wall_squared = value [eax] modify exact [];
extern signed char combined_sqrt_width(long square);
#pragma aux combined_sqrt_width = "bsr ecx,eax" parm [eax] value [cl] modify exact [ecx];
extern long load_combined_sqrt(long index);
#pragma aux load_combined_sqrt = "movzx eax,word ptr [eax*2+sqrtable]" parm [eax] value [eax] modify exact [eax];
extern long shrink_combined_square(void);
#pragma aux shrink_combined_square = "sub cl,9" "and cl,0feh" "sar eax,cl" value [eax] modify exact [eax ecx];
extern long expand_combined_root(long root);
#pragma aux expand_combined_root = "sar cl,1" "shl eax,cl" parm [eax] value [eax] modify exact [eax ecx];
extern long save_combined_length(long root);
#pragma aux save_combined_length = "mov [esp+12],eax" parm [eax] value [eax] modify exact [];
/* Compute (wall_dx * point_dy - wall_dy * point_dx) >> 3 in 64 bits. */
extern void project_combined_wall_normal(void);
#pragma aux project_combined_wall_normal = "mov edx,[esp+8]" "mov eax,edi" "mov ebx,[esi]" \
    "mov ecx,[esi+4]" "neg eax" "sub edx,ebx" "mov ebx,[esp+4]" "mov edi,edx" \
    "mov esi,eax" "mov eax,[esp+16]" "sub ebx,ecx" "imul ebx" "xchg esi,eax" \
    "mov ebx,edx" "imul edi" "add eax,esi" "adc edx,ebx" "shrd eax,edx,3" modify exact [eax ebx ecx edx esi edi];
extern long combined_ceiling_flag(void);
#pragma aux combined_ceiling_flag = "mov dx,[ebp+12]" "xor dh,dh" "and dl,2" "movsx edx,dx" \
    "mov esi,eax" value [edx] modify exact [edx esi];
extern long combined_floor_flag(void);
#pragma aux combined_floor_flag = "mov ax,[ebp+14]" "xor ah,ah" "and al,2" "cwde" value [eax] modify exact [eax];
extern long ceiling_slope_offset(void);
#pragma aux ceiling_slope_offset = "mov ecx,[esp+12]" "mov dx,[ebp+18]" "mov ebx,eax" \
    "movsx eax,dx" "imul ebx" "idiv ecx" value [eax] modify exact [eax ebx ecx edx];
extern long floor_slope_offset(void);
#pragma aux floor_slope_offset = "mov ecx,[esp+12]" "mov ax,[ebp+26]" "mov ebx,esi" \
    "cwde" "imul ebx" "idiv ecx" value [eax] modify exact [eax ebx ecx edx];
extern void drop_combined_locals(void);
#pragma aux drop_combined_locals = "add esp,20" modify exact [];
extern void finish_combined_height(void);
#pragma aux finish_combined_height aborts modify exact [];
#pragma aux getzsofslope modify exact [eax ebx ecx edx esi edi];

void getzsofslope(short sector_index, long x, long y, long *ceiling, long *floor)
{
    long height, root, distance, offset;
    long *output;

    begin_combined_height(sector_index, x, y, ceiling);
    height = initial_ceiling_height();
    *initial_ceiling_output() = height;
    output = floor_height_output();
    height = initial_floor_height();
    *output = height;
    if (!(both_slope_flags() & 2))
        goto done;

    measure_combined_wall_square();
    /* The table is exact for small squares. Normalize larger squares first. */
    if (combined_sqrt_width(combined_wall_squared()) < 11)
        root = load_combined_sqrt(combined_wall_squared());
    else
        root = expand_combined_root(load_combined_sqrt(shrink_combined_square()));
    distance = save_combined_length((root >> 10) << 5);
    if (distance == 0)
        goto done;

    project_combined_wall_normal();
    if (combined_ceiling_flag()) {
        offset = ceiling_slope_offset();
        *ceiling_height_output() += offset;
    }
    if (combined_floor_flag()) {
        offset = floor_slope_offset();
        *floor_height_output() += offset;
    }
done:
    drop_combined_locals();
    finish_combined_height();
}
