/*
 * Convert mixer accumulators to mono or stereo PCM. The mixer supplies a
 * positive sample count. Mono dispatch does not depend on channel order.
 *
 * The aux declarations preserve the mixer's register ABI and Watcom's
 * original instruction encodings. Unsigned output flips bit 15 before
 * extracting the high byte (8-bit) or low word (16-bit).
 */
extern unsigned char high_byte(unsigned long sample);
#pragma aux high_byte = parm [eax] value [ah] modify exact [];
extern unsigned short low_word(unsigned long sample);
#pragma aux low_word = parm [eax] value [ax] modify exact [];

extern unsigned char unsigned_high_byte(unsigned long sample);
#pragma aux unsigned_high_byte = "xor eax,8000h" parm [eax] value [ah] modify exact [eax];
extern unsigned short unsigned_low_word(unsigned long sample);
#pragma aux unsigned_low_word = "xor eax,8000h" parm [eax] value [ax] modify exact [eax];

/* Keep the input increment ahead of the unsigned bias and use ADD for output. */
extern const long *advance_input(const long *src);
#pragma aux advance_input = "add esi,4" parm [esi] value [esi] modify exact [esi];
extern unsigned char *advance_byte_output(unsigned char *dst);
#pragma aux advance_byte_output = "add edi,1" parm [edi] value [edi] modify exact [edi];
extern unsigned short *advance_word_output(unsigned short *dst);
#pragma aux advance_word_output = "add edi,2" parm [edi] value [edi] modify exact [edi];


extern const long *advance_frame(const long *);
#pragma aux advance_frame = "add esi,8" parm [esi] value [esi] modify exact [esi];
extern unsigned short *advance_stereo16(unsigned short *);
#pragma aux advance_stereo16 = "add edi,4" parm [edi] value [edi] modify exact [edi];

extern unsigned long bias_left(unsigned long);
#pragma aux bias_left = "xor eax,8000h" parm [eax] value [eax] modify exact [eax];
extern unsigned long bias_right(unsigned long);
#pragma aux bias_right = "xor ebx,8000h" parm [ebx] value [ebx] modify exact [ebx];

extern unsigned short right_word(unsigned long);
#pragma aux right_word = parm [ebx] value [bx] modify exact [];

/* The register-destination MOV forms pack the two high bytes into one word. */
extern unsigned short pack_left_first(unsigned long, unsigned long);
#pragma aux pack_left_first = 0x8a 0xdc parm [eax] [ebx] value [bx] modify exact [ebx];
extern unsigned short pack_right_first(unsigned long, unsigned long);
#pragma aux pack_right_first = 0x8a 0xc7 parm [eax] [ebx] value [ax] modify exact [eax];

#define SIGNED_SAMPLE(sample) (sample)

#define STORE_BYTES_LR(dst, left, right) (*(dst) = pack_left_first(left, right))
#define STORE_BYTES_RL(dst, left, right) (*(dst) = pack_right_first(left, right))
#define STORE_WORDS_LR(dst, left, right) ((dst)[0] = low_word(left), (dst)[1] = right_word(right))
#define STORE_WORDS_RL(dst, left, right) ((dst)[0] = right_word(right), (dst)[1] = low_word(left))

/* Keep the saturation branches out of the mixing loop, after its return. */
#define MONO_OUTPUT(name, type, convert, advance, clipped) \
    void name(const long *src, type *dst, unsigned count) \
    { \
        long sample; \
        do { \
            sample = *src; \
            src = advance_input(src); \
            if (clipped && sample > 32767) \
                goto clip_high; \
            if (clipped && sample < -32768) \
                goto clip_low; \
        store: \
            *dst = convert(sample); \
            dst = advance(dst); \
        } while (--count); \
        return; \
    clip_high: \
        sample = 32767; \
        goto store; \
    clip_low: \
        sample = -32768; \
        goto store; \
    }

#define STEREO_OUTPUT(name, convert_left, convert_right, store_frame, advance, clipped) \
    void name(const long *src, unsigned short *dst, unsigned count) \
    { \
        long left, right; \
        do { \
            left = src[0]; \
            right = src[1]; \
            src = advance_frame(src); \
            if (clipped && left > 32767) \
                goto clip_left_high; \
            if (clipped && left < -32768) \
                goto clip_left_low; \
        check_right: \
            if (clipped && right > 32767) \
                goto clip_right_high; \
            if (clipped && right < -32768) \
                goto clip_right_low; \
        store: \
            left = convert_left(left); \
            right = convert_right(right); \
            store_frame(dst, left, right); \
            dst = advance(dst); \
        } while (--count); \
        return; \
    clip_left_high: \
        left = 32767; \
        goto check_right; \
    clip_left_low: \
        left = -32768; \
        goto check_right; \
    clip_right_high: \
        right = 32767; \
        goto store; \
    clip_right_low: \
        right = -32768; \
        goto store; \
    }

void output_signed_8(const long *, unsigned char *, unsigned);
#pragma aux output_signed_8 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_signed_8, unsigned char, high_byte, advance_byte_output, 0)

void output_signed_16(const long *, unsigned short *, unsigned);
#pragma aux output_signed_16 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_signed_16, unsigned short, low_word, advance_word_output, 0)

void output_unsigned_8(const long *, unsigned char *, unsigned);
#pragma aux output_unsigned_8 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_unsigned_8, unsigned char, unsigned_high_byte, advance_byte_output, 0)

void output_unsigned_16(const long *, unsigned short *, unsigned);
#pragma aux output_unsigned_16 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_unsigned_16, unsigned short, unsigned_low_word, advance_word_output, 0)

void output_stereo_signed_8(const long *, unsigned short *, unsigned);
#pragma aux output_stereo_signed_8 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_stereo_signed_8, SIGNED_SAMPLE, SIGNED_SAMPLE,
              STORE_BYTES_LR, advance_word_output, 0)

void output_stereo_signed_16(const long *, unsigned short *, unsigned);
#pragma aux output_stereo_signed_16 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_stereo_signed_16, SIGNED_SAMPLE, SIGNED_SAMPLE,
              STORE_WORDS_LR, advance_stereo16, 0)

void output_stereo_unsigned_8(const long *, unsigned short *, unsigned);
#pragma aux output_stereo_unsigned_8 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_stereo_unsigned_8, bias_left, bias_right,
              STORE_BYTES_LR, advance_word_output, 0)

void output_stereo_unsigned_16(const long *, unsigned short *, unsigned);
#pragma aux output_stereo_unsigned_16 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_stereo_unsigned_16, bias_left, bias_right,
              STORE_WORDS_LR, advance_stereo16, 0)

void output_swapped_mono_signed_8(const long *, unsigned char *, unsigned);
#pragma aux output_swapped_mono_signed_8 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_swapped_mono_signed_8, unsigned char, high_byte, advance_byte_output, 0)

void output_swapped_mono_signed_16(const long *, unsigned short *, unsigned);
#pragma aux output_swapped_mono_signed_16 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_swapped_mono_signed_16, unsigned short, low_word, advance_word_output, 0)

void output_swapped_mono_unsigned_8(const long *, unsigned char *, unsigned);
#pragma aux output_swapped_mono_unsigned_8 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_swapped_mono_unsigned_8, unsigned char, unsigned_high_byte, advance_byte_output, 0)

void output_swapped_mono_unsigned_16(const long *, unsigned short *, unsigned);
#pragma aux output_swapped_mono_unsigned_16 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_swapped_mono_unsigned_16, unsigned short, unsigned_low_word, advance_word_output, 0)

void output_swapped_stereo_signed_8(const long *, unsigned short *, unsigned);
#pragma aux output_swapped_stereo_signed_8 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_swapped_stereo_signed_8, SIGNED_SAMPLE, SIGNED_SAMPLE,
              STORE_BYTES_RL, advance_word_output, 0)

void output_swapped_stereo_signed_16(const long *, unsigned short *, unsigned);
#pragma aux output_swapped_stereo_signed_16 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_swapped_stereo_signed_16, SIGNED_SAMPLE, SIGNED_SAMPLE,
              STORE_WORDS_RL, advance_stereo16, 0)

void output_swapped_stereo_unsigned_8(const long *, unsigned short *, unsigned);
#pragma aux output_swapped_stereo_unsigned_8 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_swapped_stereo_unsigned_8, bias_left, bias_right,
              STORE_BYTES_RL, advance_word_output, 0)

void output_swapped_stereo_unsigned_16(const long *, unsigned short *, unsigned);
#pragma aux output_swapped_stereo_unsigned_16 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_swapped_stereo_unsigned_16, bias_left, bias_right,
              STORE_WORDS_RL, advance_stereo16, 0)

void output_clipped_mono_signed_8(const long *, unsigned char *, unsigned);
#pragma aux output_clipped_mono_signed_8 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_clipped_mono_signed_8, unsigned char, high_byte, advance_byte_output, 1)

void output_clipped_mono_signed_16(const long *, unsigned short *, unsigned);
#pragma aux output_clipped_mono_signed_16 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_clipped_mono_signed_16, unsigned short, low_word, advance_word_output, 1)

void output_clipped_mono_unsigned_8(const long *, unsigned char *, unsigned);
#pragma aux output_clipped_mono_unsigned_8 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_clipped_mono_unsigned_8, unsigned char, unsigned_high_byte, advance_byte_output, 1)

void output_clipped_mono_unsigned_16(const long *, unsigned short *, unsigned);
#pragma aux output_clipped_mono_unsigned_16 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_clipped_mono_unsigned_16, unsigned short, unsigned_low_word, advance_word_output, 1)

void output_clipped_stereo_signed_8(const long *, unsigned short *, unsigned);
#pragma aux output_clipped_stereo_signed_8 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_clipped_stereo_signed_8, SIGNED_SAMPLE, SIGNED_SAMPLE,
              STORE_BYTES_LR, advance_word_output, 1)

void output_clipped_stereo_signed_16(const long *, unsigned short *, unsigned);
#pragma aux output_clipped_stereo_signed_16 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_clipped_stereo_signed_16, SIGNED_SAMPLE, SIGNED_SAMPLE,
              STORE_WORDS_LR, advance_stereo16, 1)

void output_clipped_stereo_unsigned_8(const long *, unsigned short *, unsigned);
#pragma aux output_clipped_stereo_unsigned_8 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_clipped_stereo_unsigned_8, bias_left, bias_right,
              STORE_BYTES_LR, advance_word_output, 1)

void output_clipped_stereo_unsigned_16(const long *, unsigned short *, unsigned);
#pragma aux output_clipped_stereo_unsigned_16 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_clipped_stereo_unsigned_16, bias_left, bias_right,
              STORE_WORDS_LR, advance_stereo16, 1)

void output_clipped_swapped_mono_signed_8(const long *, unsigned char *, unsigned);
#pragma aux output_clipped_swapped_mono_signed_8 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_clipped_swapped_mono_signed_8, unsigned char, high_byte, advance_byte_output, 1)

void output_clipped_swapped_mono_signed_16(const long *, unsigned short *, unsigned);
#pragma aux output_clipped_swapped_mono_signed_16 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_clipped_swapped_mono_signed_16, unsigned short, low_word, advance_word_output, 1)

void output_clipped_swapped_mono_unsigned_8(const long *, unsigned char *, unsigned);
#pragma aux output_clipped_swapped_mono_unsigned_8 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_clipped_swapped_mono_unsigned_8, unsigned char, unsigned_high_byte, advance_byte_output, 1)

void output_clipped_swapped_mono_unsigned_16(const long *, unsigned short *, unsigned);
#pragma aux output_clipped_swapped_mono_unsigned_16 parm [esi] [edi] [ecx] modify exact [eax esi edi ecx];
MONO_OUTPUT(output_clipped_swapped_mono_unsigned_16, unsigned short, unsigned_low_word, advance_word_output, 1)

void output_clipped_swapped_stereo_signed_8(const long *, unsigned short *, unsigned);
#pragma aux output_clipped_swapped_stereo_signed_8 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_clipped_swapped_stereo_signed_8, SIGNED_SAMPLE, SIGNED_SAMPLE,
              STORE_BYTES_RL, advance_word_output, 1)

void output_clipped_swapped_stereo_signed_16(const long *, unsigned short *, unsigned);
#pragma aux output_clipped_swapped_stereo_signed_16 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_clipped_swapped_stereo_signed_16, SIGNED_SAMPLE, SIGNED_SAMPLE,
              STORE_WORDS_RL, advance_stereo16, 1)

void output_clipped_swapped_stereo_unsigned_8(const long *, unsigned short *, unsigned);
#pragma aux output_clipped_swapped_stereo_unsigned_8 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_clipped_swapped_stereo_unsigned_8, bias_left, bias_right,
              STORE_BYTES_RL, advance_word_output, 1)

void output_clipped_swapped_stereo_unsigned_16(const long *, unsigned short *, unsigned);
#pragma aux output_clipped_swapped_stereo_unsigned_16 parm [esi] [edi] [ecx] modify exact [eax ebx esi edi ecx];
STEREO_OUTPUT(output_clipped_swapped_stereo_unsigned_16, bias_left, bias_right,
              STORE_WORDS_RL, advance_stereo16, 1)
