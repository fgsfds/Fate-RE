/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern long red_color_distance[], green_color_distance[], blue_color_distance[];
extern long palette_bucket_next[], palette_neighbor_offsets[];
extern unsigned char occupied_palette_buckets[], palette_bucket_head[], lookup_palette_end[];
extern unsigned char pow2char[];

/* Preserve the three channel weights and the frame for the shared return. */
extern void begin_palette_lookup(long red_weight, long green_weight, long blue_weight);
#pragma aux begin_palette_lookup = "push ecx" "push esi" "push edi" "push ebp" "push eax" \
    "mov esi,edx" "mov ebp,ebx" "mov edx,40h" "xor edi,edi" \
    parm [eax] [edx] [ebx] modify exact [edx esi edi];
extern long distance_index(void);
#pragma aux distance_index = value [edx] modify exact [];
extern void load_red_weight(void);
#pragma aux load_red_weight = "mov ebx,[esp]" modify exact [ebx];
extern unsigned long red_product_input(void);
#pragma aux red_product_input = value [ebx] modify exact [];
extern unsigned long squared_distance_value(void);
#pragma aux squared_distance_value = value [edi] modify exact [];
extern unsigned long retain_red_product(unsigned long value);
#pragma aux retain_red_product = "" parm [ebx] value [ebx] modify exact [];
extern long green_distance_value(void);
#pragma aux green_distance_value = "mov ecx,edi" "imul ecx,esi" value [ecx] modify exact [ecx];
extern long blue_distance_value(void);
#pragma aux blue_distance_value = "mov ecx,edi" "imul ecx,ebp" value [ecx] modify exact [ecx];
extern void prepare_mirror_distance_index(void);
#pragma aux prepare_mirror_distance_index = "mov eax,80h" "sub eax,edx" modify exact [eax];
extern long active_mirror_distance_index(void);
#pragma aux active_mirror_distance_index = value [eax] modify exact [];

/* Register-only contracts for the finite-difference square recurrence. */
extern unsigned long distance_step(void);
#pragma aux distance_step = value [ebx] modify exact [];
extern void keep_distance_step(unsigned long);
#pragma aux keep_distance_step = parm [ebx] modify exact [];
extern void keep_distance_index(long);
#pragma aux keep_distance_index = parm [edx] modify exact [];
extern void keep_squared_distance(unsigned long);
#pragma aux keep_squared_distance = parm [edi] modify exact [];
extern void keep_doubled_distance_index(long);
#pragma aux keep_doubled_distance_index = parm [eax] modify exact [];

extern void prepare_bucket_bitset(void);
#pragma aux prepare_bucket_bitset = "mov ecx,7dh" "mov edi,offset occupied_palette_buckets" \
    "xor eax,eax" modify exact [eax ecx edi];
extern void prepare_bucket_heads(void);
#pragma aux prepare_bucket_heads = "mov ecx,3e8h" "mov edi,offset palette_bucket_head" \
    "xor eax,eax" "mov edx,0ffh" modify exact [eax ecx edx edi];
/* C chooses the small-count, bulk and tail paths; alignment blocks and
   string stores remain instructions. Prepare helpers supply EAX=0 and ECX count.
   Addresses use unsigned integers so their final advances are not C pointers.
   Raw EAX inputs are valid only while the generated C control preserves EAX. */
extern unsigned long palette_clear_count(void);
#pragma aux palette_clear_count = value [ecx] modify exact [];
extern void keep_palette_clear_count(unsigned long);
#pragma aux keep_palette_clear_count = "" parm [ecx] modify exact [];
extern unsigned long palette_clear_address(void);
#pragma aux palette_clear_address = value [edi] modify exact [];
extern unsigned long palette_clear_tail(void);
#pragma aux palette_clear_tail = value [ebx] modify exact [];
extern void keep_palette_clear_tail(unsigned long);
#pragma aux keep_palette_clear_tail = "" parm [ebx] modify exact [];
extern unsigned long palette_clear_value(void);
#pragma aux palette_clear_value = value [eax] modify exact [];
extern void palette_store_byte(unsigned long value, unsigned long address);
#pragma aux palette_store_byte = "stosb" parm [eax] [edi] modify exact [edi];
extern void palette_store_word(unsigned long value, unsigned long address);
#pragma aux palette_store_word = "stosw" parm [eax] [edi] modify exact [edi];
extern void palette_store_words(unsigned long value, unsigned long address, unsigned long count);
#pragma aux palette_store_words = 0xf3 "stosw" parm [eax] [edi] [ecx] modify exact [ecx edi];
extern void palette_store_dwords(unsigned long value, unsigned long address, unsigned long count);
#pragma aux palette_store_dwords = "rep stosd" parm [eax] [edi] [ecx] modify exact [ecx edi];

/* Preserve the full-EDI alignment tests. The rejected C byte-test lowering
   copied EDI into EAX, destroying the fill value. These are original blocks. */
extern void align_palette_to_word(unsigned long value, unsigned long address, unsigned long count);
#pragma aux align_palette_to_word = "test edi,1" "jz aligned" "stosb" "dec ecx" "aligned:" \
    parm [eax] [edi] [ecx] modify exact [ecx edi];
extern void align_palette_to_dword(unsigned long value, unsigned long address, unsigned long count);
#pragma aux align_palette_to_dword = "test edi,2" "jz aligned" "stosw" "sub ecx,2" "aligned:" \
    parm [eax] [edi] [ecx] modify exact [ecx edi];

#define CLEAR_PALETTE_MEMORY(prefix) do { \
    if (palette_clear_count() >= 4UL) goto prefix##_bulk; \
    if (!((unsigned char)palette_clear_count() & 1)) goto prefix##_small_words; \
    palette_store_byte(palette_clear_value(), palette_clear_address()); \
    prefix##_small_words: \
    keep_palette_clear_count(palette_clear_count() >> 1); \
    palette_store_words(palette_clear_value(), palette_clear_address(), palette_clear_count()); \
    goto prefix##_done; \
    prefix##_bulk: \
    align_palette_to_word(palette_clear_value(), palette_clear_address(), palette_clear_count()); \
    align_palette_to_dword(palette_clear_value(), palette_clear_address(), palette_clear_count()); \
    keep_palette_clear_tail(palette_clear_count()); \
    keep_palette_clear_count(palette_clear_count() >> 2); \
    palette_store_dwords(palette_clear_value(), palette_clear_address(), palette_clear_count()); \
    if (!((unsigned char)palette_clear_tail() & 2)) goto prefix##_last_byte; \
    palette_store_word(palette_clear_value(), palette_clear_address()); \
    prefix##_last_byte: \
    if (!((unsigned char)palette_clear_tail() & 1)) goto prefix##_done; \
    palette_store_byte(palette_clear_value(), palette_clear_address()); \
    prefix##_done:; \
} while (0)

extern void begin_palette_buckets(void);
#pragma aux begin_palette_buckets = "mov eax,offset lookup_palette_end" modify exact [eax];
extern long palette_color_index(void);
#pragma aux palette_color_index = value [edx] modify exact [];
/* Register-only contracts for the bucket phase; these emit no instructions. */
extern const unsigned char *current_palette_rgb(void);
#pragma aux current_palette_rgb = value [eax] modify exact [];
/* Preserve the original three-input LEA encoding; preceding arithmetic is C. */
extern void finish_color_bucket(long green_red, long blue);
#pragma aux finish_color_bucket = "lea edi,[ecx+ebx*1+49h]" parm [ecx] [ebx] modify exact [edi];
extern long bucket_channel_ebx(long);
#pragma aux bucket_channel_ebx = parm [ebx] value [ebx] modify exact [];
extern long bucket_green_ecx(long);
#pragma aux bucket_green_ecx = parm [ecx] value [ecx] modify exact [];

extern void prepare_color_bucket(void);
#pragma aux prepare_color_bucket = "mov ebx,edi" "sar ebx,3" "xor ecx,ecx" \
    "mov cl,[ebx+occupied_palette_buckets]" "mov ebx,edi" "and ebx,7" \
    "movzx esi,byte ptr [ebx+pow2char]" "mov ebx,edx" "shl ebx,2" modify exact [ebx ecx esi];
extern long occupied_bucket_byte(void);
#pragma aux occupied_bucket_byte = value [ecx] modify exact [];
extern long current_bucket_bit(void);
#pragma aux current_bucket_bit = value [esi] modify exact [];
extern long current_bucket_link_slot(void);
#pragma aux current_bucket_link_slot = value [ebx] modify exact [];
extern long current_bucket_head(void);
#pragma aux current_bucket_head = "xor ecx,ecx" "mov cl,[edi+palette_bucket_head]" \
    value [ecx] modify exact [ecx];
extern void mark_palette_bucket_end(void);
#pragma aux mark_palette_bucket_end = "mov dword ptr [ebx+palette_bucket_next],-1" modify exact [];
extern void advance_palette_bucket(void);
#pragma aux advance_palette_bucket = "mov ebx,edi" "mov [edi+palette_bucket_head],dl" "and edi,7" \
    "sar ebx,3" "mov cl,[edi+pow2char]" "mov ch,[ebx+occupied_palette_buckets]" \
    "sub eax,3" "or ch,cl" "dec edx" "mov [ebx+occupied_palette_buckets],ch" modify exact [eax ebx ecx edx edi];

/* Empty auxiliaries keep the neighbor counters and sum in the original registers. */
extern void set_blue_neighbor(long);
#pragma aux set_blue_neighbor = parm [eax] modify exact [];
extern long red_green_sum(void);
#pragma aux red_green_sum = value [ebx] modify exact [];
extern void set_red_green_sum(long);
#pragma aux set_red_green_sum = parm [ebx] modify exact [];
extern long neighbor_offset(void);
#pragma aux neighbor_offset = value [ecx] modify exact [];
extern long neighbor_slot(void);
#pragma aux neighbor_slot = value [edx] modify exact [];
extern void set_neighbor_slot(long);
#pragma aux set_neighbor_slot = parm [edx] modify exact [];
extern void set_green_neighbor(long);
#pragma aux set_green_neighbor = parm [esi] modify exact [];
extern void set_red_neighbor(long);
#pragma aux set_red_neighbor = parm [edi] modify exact [];

extern long red_neighbor(void);
#pragma aux red_neighbor = value [edi] modify exact [];
extern long green_neighbor(void);
#pragma aux green_neighbor = value [esi] modify exact [];
extern long blue_neighbor(void);
#pragma aux blue_neighbor = value [eax] modify exact [];
extern void keep_last_neighbor_offset(long offset);
#pragma aux keep_last_neighbor_offset = "" parm [eax] modify exact [];
extern void keep_center_neighbor_offset(long offset);
#pragma aux keep_center_neighbor_offset = "" parm [edx] modify exact [];
extern long last_neighbor_offset(void);
#pragma aux last_neighbor_offset = value [eax] modify exact [];
extern long center_neighbor_offset(void);
#pragma aux center_neighbor_offset = value [edx] modify exact [];
/* Retain the original LEA operand encoding for the neighbor sum. */
extern long neighbor_sum(long, long);
#pragma aux neighbor_sum = "lea ecx,[ebx+eax]" parm [ebx] [eax] value [ecx] modify exact [ecx];
extern void finish_palette_lookup(void);
#pragma aux finish_palette_lookup aborts modify exact [];
#pragma aux initialize_color_lookup modify exact [eax ebx ecx edx esi edi];

void initialize_color_lookup(long red_weight, long green_weight, long blue_weight)
{
    long red, green, blue, slot;

    /* The weighted square is symmetric about color-distance index 64. */
    begin_palette_lookup(red_weight, green_weight, blue_weight);
    goto check_distance;
    do {
        /* Use the low 32 bits of the product, as with the original IMUL. */
        load_red_weight();
        red = (long)retain_red_product(red_product_input() * squared_distance_value());
        green = green_distance_value();
        prepare_mirror_distance_index();
        green_color_distance[active_mirror_distance_index()] = green;
        green_color_distance[distance_index()] = green;
        blue = blue_distance_value();
        red_color_distance[active_mirror_distance_index()] = red;
        red_color_distance[distance_index()] = red;
        keep_distance_step(129UL);
        blue_color_distance[active_mirror_distance_index()] = blue;
        /* EAX now holds 2*i rather than the mirror index used above. */
        keep_doubled_distance_index(distance_index() + distance_index());
        blue_color_distance[distance_index()] = blue;
        keep_distance_step(distance_step() - (unsigned long)active_mirror_distance_index());
        keep_distance_index(distance_index() - 1);
        keep_squared_distance(squared_distance_value() + distance_step());
check_distance:;
    } while (distance_index() >= 0);

    prepare_bucket_bitset();
    CLEAR_PALETTE_MEMORY(bitset);
    prepare_bucket_heads();
    CLEAR_PALETTE_MEMORY(heads);
    /* Walk backward so each occupied bucket links to the previous palette entry. */
    begin_palette_buckets();
    goto check_bucket;
    do {
        {
            long green_channel = bucket_green_ecx(bucket_channel_ebx(current_palette_rgb()[1]));
            long red_channel = bucket_channel_ebx(current_palette_rgb()[0]);
            long blue_channel;
            green_channel = bucket_green_ecx(green_channel >> 3);
            red_channel = bucket_channel_ebx(red_channel >> 3);
            green_channel = bucket_green_ecx(green_channel << 3);
            red_channel = bucket_channel_ebx(red_channel << 6);
            green_channel = bucket_green_ecx(green_channel + red_channel);
            blue_channel = bucket_channel_ebx(current_palette_rgb()[2]);
            blue_channel = bucket_channel_ebx(blue_channel >> 3);
            finish_color_bucket(green_channel, blue_channel);
        }
        prepare_color_bucket();
        if (occupied_bucket_byte() & current_bucket_bit())
            *(long *)((unsigned char *)palette_bucket_next + current_bucket_link_slot()) = current_bucket_head();
        else
            mark_palette_bucket_end();
        advance_palette_bucket();
check_bucket:;
    } while (palette_color_index() >= 0);

    /* A change of one bucket contributes 64 for R, 8 for G, or 1 for B. */
    set_red_neighbor(-64);
    set_neighbor_slot(0);
    goto check_red;
    do {
        set_green_neighbor(-8);
        goto check_green;
        do {
            set_blue_neighbor(-1);
            set_red_green_sum(red_neighbor() + green_neighbor());
            goto check_blue;
            do {
                set_neighbor_slot(neighbor_slot() + 1);
                slot = neighbor_slot();
                /* Keep the sum in ECX across the blue-counter increment. */
                neighbor_sum(red_green_sum(), blue_neighbor());
                set_blue_neighbor(blue_neighbor() + 1);
                palette_neighbor_offsets[slot] = neighbor_offset();
check_blue:;
            } while (blue_neighbor() <= 1);
            set_green_neighbor(green_neighbor() + 8);
check_green:;
        } while (green_neighbor() <= 8);
        set_red_neighbor(red_neighbor() + 64);
check_red:;
    } while (red_neighbor() <= 64);
    keep_last_neighbor_offset(palette_neighbor_offsets[27]);
    keep_center_neighbor_offset(palette_neighbor_offsets[14]);
    palette_neighbor_offsets[14] = last_neighbor_offset();
    palette_neighbor_offsets[27] = center_neighbor_offset();
    finish_palette_lookup();
}