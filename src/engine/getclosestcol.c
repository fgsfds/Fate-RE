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

extern long edi_value(void);
#pragma aux edi_value = value [edi] modify exact [];
extern long ebp_value(void);
#pragma aux ebp_value = value [ebp] modify exact [];
extern long esi_value(void);
#pragma aux esi_value = value [esi] modify exact [];
extern void in_esi(long);
#pragma aux in_esi = parm [esi] modify exact [];
extern void in_ecx(long);
#pragma aux in_ecx = parm [ecx] modify exact [];
extern void in_al(unsigned char);
#pragma aux in_al = parm [al] modify exact [];
extern void in_dl(unsigned char);
#pragma aux in_dl = parm [dl] modify exact [];
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
extern void load_query_red(void);
#pragma aux load_query_red = "mov eax,[esp]" modify exact [eax];
extern long red_boundary_distance(void);
#pragma aux red_boundary_distance = value [ebx] modify exact [];
extern long green_boundary_distance(void);
#pragma aux green_boundary_distance = value [ecx] modify exact [];
extern void record_boundary_distance(long distance);
#pragma aux record_boundary_distance = "" parm [edx] modify exact [];
extern long active_boundary_distance(void);
#pragma aux active_boundary_distance = value [edx] modify exact [];
extern void load_query_blue(void);
#pragma aux load_query_blue = "mov eax,[esp+10h]" modify exact [eax];
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
/* The previous EDX value is dead before selecting the palette triplet. */
extern void in_eax_for_palette(long index);
#pragma aux in_eax_for_palette = "" parm [eax] modify exact [edx];
extern void load_red_query_offset(void);
#pragma aux load_red_query_offset = "mov ebp,[esp]" modify exact [];
/* Shared red-distance accumulation retains the original saved query offset. */
extern void load_linked_blue_offset(void);
#pragma aux load_linked_blue_offset = "mov esi,[esp+10h]" modify exact [esi];
extern void save_color_candidate(void);
#pragma aux save_color_candidate = "mov [esp+0ch],ebx" modify exact [];
extern long search_best_distance(void);
#pragma aux search_best_distance = value [ecx] modify exact [];
extern void previous_search_bucket(void);
#pragma aux previous_search_bucket = "dec dword ptr [esp+8]" modify exact [];
extern long search_bucket_neighbor(void);
#pragma aux search_bucket_neighbor = "mov ebp,[esp+8]" value [ebp] modify exact [];

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
    load_query_red();
    in_eax((unsigned long)eax_value() & 7UL);
    in_edx(0);
    in_dl(color_neighbor_order[eax_value()]);
    in_eax(edi_value());
    in_eax((unsigned long)eax_value() & 7UL);
    in_edx((unsigned long)edx_value() << 2);
    in_al(color_neighbor_order[eax_value()]);
    in_eax((unsigned long)eax_value() & 255UL);
    in_eax((unsigned long)eax_value() << 2);
    in_ebx(*(const long *)((const char *)red_color_distance + edx_value() + 0x120));
    in_ecx(*(const long *)((const char *)green_color_distance + eax_value() + 0x120));
    if (red_boundary_distance() < green_boundary_distance())
        record_boundary_distance(red_boundary_distance());
    else
        record_boundary_distance(green_boundary_distance());
    load_query_blue();
    in_eax((unsigned long)eax_value() & 7UL);
    in_al(color_neighbor_order[eax_value()]);
    in_eax((unsigned long)eax_value() & 255UL);
    in_eax((unsigned long)eax_value() << 2);
    in_esi(*(const long *)((const char *)blue_color_distance + eax_value() + 0x120));
    distance = esi_value();
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
                in_eax(ebx_value());
                in_eax_for_palette((unsigned long)eax_value() << 2);
                in_edx((long)palette);
                in_eax((unsigned long)eax_value() - (unsigned long)ebx_value());
                in_edx((unsigned long)edx_value() + (unsigned long)eax_value());
                in_eax(0);
                in_al(*(const unsigned char *)(edx_value() + 1));
                in_eax((unsigned long)eax_value() + (unsigned long)edi_value());
                in_eax(green_color_distance[eax_value()]);
                if (eax_value() < search_best_distance()) {
                    load_red_query_offset();
                    in_esi(*(const unsigned char *)edx_value());
                    in_esi((unsigned long)esi_value() + (unsigned long)ebp_value());
                    in_eax((unsigned long)eax_value() + (unsigned long)red_color_distance[esi_value()]);
                    if (eax_value() < search_best_distance()) {
                        in_dl(*(const unsigned char *)(edx_value() + 2));
                        load_linked_blue_offset();
                        in_edx((unsigned long)edx_value() & 255UL);
                        in_edx((unsigned long)edx_value() + (unsigned long)esi_value());
                        in_eax((unsigned long)eax_value() + (unsigned long)blue_color_distance[edx_value()]);
                        if (eax_value() < search_best_distance()) {
                            in_ecx(eax_value());
                            save_color_candidate();
                        }
                    }
                }
                in_ebx(palette_bucket_next[ebx_value()]);
            } while (ebx_value() >= 0);
        }
        previous_search_bucket();
check_bucket:;
    } while (search_bucket_neighbor() >= 0);

    load_final_color();
    if (eax_value() >= 0)
        return finish_color_search();
    /* Search the full palette when the neighboring buckets yield no candidate. */
    in_ecx(0x7fffffffL);
    in_edx((long)lookup_palette_end);
    in_ebx(255);
    goto check_linear;
    do {
        if (begin_linear_color() < search_best_distance()) {
            load_red_query_offset();
            in_esi(*(const unsigned char *)edx_value());
            in_esi((unsigned long)esi_value() + (unsigned long)ebp_value());
            in_eax((unsigned long)eax_value() + (unsigned long)red_color_distance[esi_value()]);
            if (eax_value() < search_best_distance() &&
                add_linear_blue_distance() < search_best_distance()) {
                in_ecx(eax_value());
                save_color_candidate();
            }
        }
        in_ebx((unsigned long)ebx_value() - 1UL);
        in_edx((unsigned long)edx_value() - 3UL);
check_linear:;
    } while (search_color_index() >= 0);
    load_final_color();
    return finish_color_search();
}
