/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern unsigned char color_neighbor_order[], occupied_palette_buckets[], pow2char[];
extern unsigned char palette_bucket_head[], palette[], lookup_palette_end[];
extern long red_color_distance[], green_color_distance[], blue_color_distance[];
extern long palette_bucket_next[], palette_neighbor_offsets[];

/* Empty bindings retain the original Watcom register assignments. */
extern long eax_value(void);
#pragma aux eax_value = value [eax] modify exact [];
extern void in_eax(long);
#pragma aux in_eax = parm [eax] modify exact [];
extern long ebx_value(void);
#pragma aux ebx_value = value [ebx] modify exact [];
extern void in_ebx(long);
#pragma aux in_ebx = parm [ebx] modify exact [];
extern long edx_value(void);
#pragma aux edx_value = value [edx] modify exact [];
extern void in_edx(long);
#pragma aux in_edx = parm [edx] modify exact [];
extern void in_bl(unsigned char);
#pragma aux in_bl = parm [bl] modify exact [];

extern long finish_color_search(void);
#pragma aux finish_color_search aborts modify exact [eax];
/* Preserve the search frame for the shared return. */
extern void begin_color_search(long red, long green, long blue);
#pragma aux begin_color_search = "push ecx" "push esi" "push edi" "push ebp" "sub esp,10h" \
    "push eax" "mov edi,edx" "mov [esp+10h],ebx" "mov edx,eax" "mov eax,edi" \
    parm [eax] [edx] [ebx] modify exact [eax edx edi];
/* A change of one bucket contributes 64 for R, 8 for G, or 1 for B. */
extern void save_query_bucket(void);
#pragma aux save_query_bucket = "mov [esp+4],eax" modify exact [];
extern void compute_red_green_bounds(void);
#pragma aux compute_red_green_bounds = "mov eax,[esp]" "and eax,7" "xor edx,edx" \
    "mov dl,[eax+color_neighbor_order]" "mov eax,edi" "and eax,7" "shl edx,2" \
    "mov al,[eax+color_neighbor_order]" "and eax,0ffh" "shl eax,2" \
    "mov ebx,[edx+red_color_distance+120h]" "mov ecx,[eax+green_color_distance+120h]" modify exact [eax ebx ecx edx];
extern long red_boundary_distance(void);
#pragma aux red_boundary_distance = value [ebx] modify exact [];
extern long green_boundary_distance(void);
#pragma aux green_boundary_distance = value [ecx] modify exact [];
extern void record_boundary_distance(long distance);
#pragma aux record_boundary_distance = "" parm [edx] modify exact [];
extern long active_boundary_distance(void);
#pragma aux active_boundary_distance = value [edx] modify exact [];
extern long blue_boundary_distance(void);
#pragma aux blue_boundary_distance = "mov eax,[esp+10h]" "and eax,7" "mov al,[eax+color_neighbor_order]" \
    "and eax,0ffh" "shl eax,2" "mov esi,[eax+blue_color_distance+120h]" value [esi] modify exact [eax esi];
extern void start_bucket_search(void);
#pragma aux start_bucket_search = "mov eax,40h" "mov ebp,[esp]" "mov ebx,-1" "sub eax,ebp" \
    "mov esi,1ah" "mov [esp],eax" "mov eax,40h" "lea ecx,[edx+1]" "sub eax,edi" \
    "mov edx,[esp+10h]" "mov edi,eax" "mov eax,40h" "mov [esp+0ch],ebx" "sub eax,edx" \
    "mov [esp+8],esi" "mov [esp+10h],eax" modify exact [eax ebx ecx edx esi edi];

extern void prepare_search_bucket(void);
#pragma aux prepare_search_bucket = "mov edx,[esp+4]" "mov ebx,[ebp*4+palette_neighbor_offsets+4]" \
    "add ebx,edx" "mov eax,ebx" "sar eax,3" "xor edx,edx" "mov dl,[eax+occupied_palette_buckets]" \
    "mov eax,ebx" "and eax,7" "mov al,[eax+pow2char]" "and eax,0ffh" modify exact [eax ebx edx];
extern long search_bucket_bitset(void);
#pragma aux search_bucket_bitset = value [edx] modify exact [];
extern long target_search_bucket_bit(void);
#pragma aux target_search_bucket_bit = value [eax] modify exact [];
extern long begin_linked_color(void);
#pragma aux begin_linked_color = "mov eax,ebx" "shl eax,2" "mov edx,offset palette" "sub eax,ebx" \
    "add edx,eax" "xor eax,eax" "mov al,[edx+1]" "add eax,edi" "mov eax,[eax*4+green_color_distance]" \
    value [eax] modify exact [eax edx];
extern long add_red_distance(void);
#pragma aux add_red_distance = "mov ebp,[esp]" "movzx esi,byte ptr [edx]" "add esi,ebp" \
    "add eax,[esi*4+red_color_distance]" value [eax] modify exact [esi eax];
extern long add_linked_blue_distance(void);
#pragma aux add_linked_blue_distance = "mov dl,[edx+2]" "mov esi,[esp+10h]" "and edx,0ffh" \
    "add edx,esi" "add eax,[edx*4+blue_color_distance]" value [eax] modify exact [eax edx esi];
extern long search_best_distance(void);
#pragma aux search_best_distance = value [ecx] modify exact [];
extern void remember_color_candidate(void);
#pragma aux remember_color_candidate = "mov ecx,eax" "mov [esp+0ch],ebx" modify exact [ecx];
extern void previous_search_bucket(void);
#pragma aux previous_search_bucket = "dec dword ptr [esp+8]" modify exact [];
extern long search_bucket_neighbor(void);
#pragma aux search_bucket_neighbor = "mov ebp,[esp+8]" value [ebp] modify exact [];

extern void accept_bucket_search_result(void);
#pragma aux accept_bucket_search_result = "mov eax,[esp+0ch]" "test eax,eax" "jge finish_color_search" modify exact [eax];
extern void begin_exhaustive_search(void);
#pragma aux begin_exhaustive_search = "mov ecx,7fffffffh" "mov edx,offset lookup_palette_end" "mov ebx,0ffh" \
    modify exact [ebx ecx edx];
extern long begin_linear_color(void);
#pragma aux begin_linear_color = "xor eax,eax" "mov al,[edx+1]" "add eax,edi" \
    "mov eax,[eax*4+green_color_distance]" value [eax] modify exact [eax];
extern long add_linear_blue_distance(void);
#pragma aux add_linear_blue_distance = "mov ebp,[esp+10h]" "movzx esi,byte ptr [edx+2]" "add esi,ebp" \
    "add eax,[esi*4+blue_color_distance]" value [eax] modify exact [eax esi];
extern long search_color_index(void);
#pragma aux search_color_index = value [ebx] modify exact [];
extern void load_final_color(void);
#pragma aux load_final_color = "mov eax,[esp+0ch]" modify exact [eax];
#pragma aux getclosestcol modify exact [eax ebx ecx edx esi edi];

long getclosestcol(long red, long green, long blue)
{
    long distance;

    begin_color_search(red, green, blue);
    in_edx(edx_value() >> 3);
    in_eax(eax_value() >> 3);
    in_edx((unsigned long)edx_value() << 6);
    in_eax((unsigned long)eax_value() << 3);
    in_edx((unsigned long)edx_value() + (unsigned long)eax_value());
    in_eax(ebx_value());
    in_eax(eax_value() >> 3);
    in_eax((unsigned long)eax_value() + (unsigned long)edx_value());
    in_eax((unsigned long)eax_value() + 0x49UL);
    save_query_bucket();
    /* Start with the minimum distance to leave the neighboring buckets. */
    compute_red_green_bounds();
    if (red_boundary_distance() < green_boundary_distance())
        record_boundary_distance(red_boundary_distance());
    else
        record_boundary_distance(green_boundary_distance());
    distance = blue_boundary_distance();
    if (active_boundary_distance() >= distance)
        record_boundary_distance(distance);
    start_bucket_search();

    goto check_bucket;
    do {
        prepare_search_bucket();
        if (search_bucket_bitset() & target_search_bucket_bit()) {
            in_bl(palette_bucket_head[ebx_value()]);
            in_ebx((unsigned long)ebx_value() & 255UL);
            do {
                /* Stop accumulating as soon as the partial distance cannot win. */
                if (begin_linked_color() < search_best_distance() &&
                    add_red_distance() < search_best_distance() &&
                    add_linked_blue_distance() < search_best_distance())
                    remember_color_candidate();
                in_ebx(palette_bucket_next[ebx_value()]);
            } while (ebx_value() >= 0);
        }
        previous_search_bucket();
check_bucket:;
    } while (search_bucket_neighbor() >= 0);

    accept_bucket_search_result();
    /* Search the full palette when the neighboring buckets yield no candidate. */
    begin_exhaustive_search();
    goto check_linear;
    do {
        if (begin_linear_color() < search_best_distance() &&
            add_red_distance() < search_best_distance() &&
            add_linear_blue_distance() < search_best_distance())
            remember_color_candidate();
        in_ebx((unsigned long)ebx_value() - 1UL);
        in_edx((unsigned long)edx_value() - 3UL);
check_linear:;
    } while (search_color_index() >= 0);
    load_final_color();
    return finish_color_search();
}
