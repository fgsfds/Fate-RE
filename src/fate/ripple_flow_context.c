/* Complete algorithm context for the outer register saves and control
 * transfers. The production build places those matching instructions;
 * its other phases already come from exact C leaves. The verifier guards
 * this complete private context and its fixups before remapping the
 * selected instruction-aligned branches into the final 855-byte routine. */
#define RIPPLE_SIDE 128
#define RIPPLE_STRIDE (RIPPLE_SIDE + 4)
#define RIPPLE_BOTTOM ((RIPPLE_SIDE + 1) * RIPPLE_STRIDE)
#define RIPPLE_RIGHT (RIPPLE_SIDE + 1)
#define RIPPLE_ROW_WORDS (RIPPLE_SIDE / 4)
#define RIPPLE_MAX_COUNT 32

/* The DOS tile is byte-addressable. A packed word permits the original
 * four-pixel accesses even at the unaligned start of a bordered row. */
#pragma pack(push, 1)
typedef struct {
    unsigned long value;
} RippleWord;

typedef struct {
    RippleWord words[RIPPLE_SIDE * RIPPLE_ROW_WORDS];
} RippleTexture;

typedef struct {
    unsigned char left;
    RippleWord word[RIPPLE_ROW_WORDS];
    unsigned char tail[3];
} RippleRow;

typedef struct {
    RippleRow row[RIPPLE_SIDE + 2];
} RippleBuffer;
#pragma pack(pop)

extern int radial_sample_count[], ripple_speed[];
extern unsigned int radial_x_offsets[32 * RIPPLE_SIDE], radial_y_offsets[32 * RIPPLE_SIDE];
extern int ripple_radius[], ripple_origin_x[], ripple_origin_y[];
extern int ripple_count, ripple_frame;
extern RippleBuffer ripple_buffer;

#define RIPPLE_PLANE ((unsigned char *)&ripple_buffer)

typedef struct {
    int index;
    unsigned char *end;
    unsigned int amplitude, origin_x;
    unsigned char last_column;
} RippleScratch;
extern unsigned int ripple_random(void);
#pragma aux ripple_random "random_value_" value [eax] modify exact [eax];

extern unsigned char *hold_pixels(unsigned char *);
#pragma aux hold_pixels = "" parm [edx] value [edx] modify exact [];
extern int hold_spawn_count(int);
#pragma aux hold_spawn_count = "" parm [ecx] value [ecx] modify exact [];
extern int hold_ring_count(int);
#pragma aux hold_ring_count = "" parm [eax] value [eax] modify exact [];
extern int hold_one(int);
#pragma aux hold_one = "" parm [esi] value [esi] modify exact [];
extern unsigned int hold_random(unsigned int);
#pragma aux hold_random = "" parm [ebx] value [ebx] modify exact [];
extern int hold_sample(int);
#pragma aux hold_sample = "" parm [esi] value [esi] modify exact [];
extern int hold_radius(int);
#pragma aux hold_radius = "" parm [edi] value [edi] modify exact [];
extern const RippleWord *hold_input(const RippleWord *);
#pragma aux hold_input = "" parm [esi] value [esi] modify exact [];
extern RippleWord *hold_output(RippleWord *);
#pragma aux hold_output = "" parm [esi] value [esi] modify exact [];
extern unsigned char *hold_mask_destination(unsigned char *);
#pragma aux hold_mask_destination = "" parm [eax] value [eax] modify exact [];
extern unsigned char *hold_stencil_column(unsigned char *);
#pragma aux hold_stencil_column = "" parm [ecx] value [ecx] modify exact [];

/* The stencil omits the lower-right sample. Keep the byte sums and the
 * four-pixel assembly order of the original packed output word. */
#define RIPPLE_SUM(center, total, partial) \
    do { \
        (total) = (center)[-RIPPLE_STRIDE - 1]; \
        (partial) = (center)[-1]; \
        (total) += (center)[-RIPPLE_STRIDE]; \
        (partial) += (center)[RIPPLE_STRIDE - 1]; \
        (total) += (center)[-RIPPLE_STRIDE + 1]; \
        (partial) += (center)[RIPPLE_STRIDE]; \
        (total) += (center)[1]; \
        (total) += (partial); \
    } while (0)

void ripple_flow_context(RippleTexture *);
#pragma aux ripple_flow_context parm routine [eax] modify exact [eax];

void ripple_flow_context(RippleTexture *texture)
{
    volatile RippleScratch frame;
    unsigned char *pixels;
    int remaining;
    int one;
    int row, column;

    pixels = hold_pixels((unsigned char *)texture);
    remaining = hold_ring_count(RIPPLE_MAX_COUNT);
    remaining -= ripple_count;
    --remaining;
    if (remaining >= 3)
        remaining = 3;
    one = hold_one(1);
    frame.index = remaining;
    goto test_spawn;
    do {
        unsigned int x = hold_random(ripple_random());
        int slot = ripple_count;
        unsigned int y;

        remaining -= one;
        ripple_origin_x[slot] = x & 127U;
        y = ripple_random();
        frame.index = remaining;
        y = hold_random(y);
        slot = ripple_count;
        ripple_origin_y[slot] = y & 127U;
        ripple_radius[slot] = one;
        ripple_count = slot + one;
    test_spawn:
        remaining = hold_spawn_count(frame.index);
    } while (remaining >= 0);

    frame.index = ripple_count - 1;
    goto test_ring;
    do {
        int slot = remaining;
        unsigned int amplitude;
        int amplitude_radius, radius, sample;
        unsigned int origin_x, origin_y;
        int next_radius;

        /* The amplitude and sample lookup each read the current radius. */
        amplitude_radius = *(const volatile int *)&ripple_radius[slot];
        amplitude = (unsigned int)ripple_speed[amplitude_radius] *
                    (unsigned int)((slot & 1) * 2 - 1);
        radius = hold_radius(*(const volatile int *)&ripple_radius[slot]);
        sample = hold_sample(radial_sample_count[radius]);
        frame.amplitude = amplitude;
        origin_x = ripple_origin_x[slot];
        --sample;
        frame.origin_x = origin_x;
        origin_y = ripple_origin_y[slot];
        goto test_sample;
        do {
            unsigned int offset = radius * 512U + sample * 4U;
            unsigned int x, y;
            unsigned char *pixel;

            origin_x = frame.origin_x;
            x = *(const unsigned int *)((const unsigned char *)&radial_x_offsets + offset);
            x += origin_x;
            y = *(const unsigned int *)((const unsigned char *)&radial_y_offsets + offset);
            x &= 127U;
            y += origin_y;
            x *= RIPPLE_SIDE;
            y &= 127U;
            pixel = pixels + (x + y);
            *pixel += (unsigned char)frame.amplitude;
            if (*(const volatile unsigned char *)pixel < 192U)
                *pixel = 192;
            --sample;
        test_sample:
            ;
        } while (sample >= 0);

        slot = frame.index;
        next_radius = ripple_radius[slot] + 1;
        ripple_radius[slot] = next_radius;
        if (next_radius > 10) {
            int last = ripple_count - 1;
            int last_x = ripple_origin_x[last];
            int last_radius = ripple_radius[last];
            int last_y;

            ripple_count = last;
            ripple_origin_x[slot] = last_x;
            last_y = ripple_origin_y[last];
            ripple_radius[slot] = last_radius;
            ripple_origin_y[slot] = last_y;
        }
        --frame.index;
    test_ring:
        remaining = hold_ring_count(frame.index);
    } while (remaining >= 0);

    {
        unsigned char *destination = hold_mask_destination(RIPPLE_PLANE + RIPPLE_STRIDE + 1);
        const RippleWord *input = hold_input(((RippleTexture *)pixels)->words);

        row = 0;
        goto test_mask_row;
        do {
            int words = RIPPLE_ROW_WORDS;
            unsigned char *next;

            goto test_mask_word;
            do {
                unsigned int masked = input->value;
                --words;
                masked &= 0x1f1f1f1fU;
                ++input;
                ((RippleWord *)destination)->value = masked;
                destination = next;
            test_mask_word:
                next = destination + sizeof(RippleWord);
            } while (words > 0);
            destination = next;
            ++row;
        test_mask_row:
            ;
        } while (row < RIPPLE_SIDE);
    }

    column = 0;
    goto test_border_column;
    do {
        unsigned char first_row;
        RIPPLE_PLANE[1 + column] = pixels[(RIPPLE_SIDE - 1) * RIPPLE_SIDE + column] & 31;
        first_row = pixels[column];
        ++column;
        RIPPLE_PLANE[RIPPLE_BOTTOM + column] = first_row & 31;
    test_border_column:
        ;
    } while (column < RIPPLE_SIDE);

    row = 0;
    goto test_border_row;
    do {
        int source = row * RIPPLE_SIDE;
        unsigned char last_column = pixels[source + RIPPLE_SIDE - 1] & 31;
        int dest;

        ++row;
        frame.last_column = last_column;
        dest = row * RIPPLE_STRIDE;
        RIPPLE_PLANE[dest] = frame.last_column;
        RIPPLE_PLANE[dest + RIPPLE_RIGHT] = pixels[source] & 31;
    test_border_row:
        ;
    } while (row < RIPPLE_SIDE);

    RIPPLE_PLANE[0] = pixels[RIPPLE_SIDE * RIPPLE_SIDE - 1] & 31;
    RIPPLE_PLANE[RIPPLE_RIGHT] = pixels[(RIPPLE_SIDE - 1) * RIPPLE_SIDE] & 31;
    RIPPLE_PLANE[RIPPLE_BOTTOM] = pixels[RIPPLE_SIDE - 1] & 31;
    RIPPLE_PLANE[RIPPLE_BOTTOM + RIPPLE_RIGHT + 2] = pixels[0] & 31;

    {
        RippleWord *output = hold_output(((RippleTexture *)pixels)->words);

        row = 0;
        goto test_output_row;
        do {
            unsigned char *center = RIPPLE_PLANE + (row + 1) * RIPPLE_STRIDE + 1;
            unsigned char sum, partial;
            unsigned int packed;

            frame.end = center + RIPPLE_SIDE;
            center = hold_stencil_column(center);
            goto test_output_word;
            do {
                RIPPLE_SUM(center, sum, partial);
                packed = ((unsigned int)sum & 0xf8U) >> 3;
                RIPPLE_SUM(center + 1, sum, partial);
                packed += ((unsigned int)sum & 0xf8U) << 5;
                RIPPLE_SUM(center + 2, sum, partial);
                packed += ((unsigned int)sum & 0xf8U) << 13;
                RIPPLE_SUM(center + 3, sum, partial);
                packed += ((unsigned int)sum & 0xf8U) << 21;
                center += sizeof(RippleWord);
                output->value = packed - 0x3d3d3d3eU;
                ++output;
            test_output_word:
                ;
            } while (center < frame.end);
            ++row;
        test_output_row:
            ;
        } while (row < RIPPLE_SIDE);
    }

    /* The original frame counter increments modulo 2^32. */
    ++*(unsigned int *)&ripple_frame;
}
