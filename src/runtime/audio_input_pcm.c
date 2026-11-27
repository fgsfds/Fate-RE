extern short read_left_byte(const unsigned char *);
#pragma aux read_left_byte = "mov ah,[esi]" parm [esi] value [ax] modify exact [eax];
extern short read_right_byte(const unsigned char *);
#pragma aux read_right_byte = "mov bh,[esi+1]" parm [esi] value [bx] modify exact [ebx];
extern short read_swapped_left_byte(const unsigned char *);
#pragma aux read_swapped_left_byte = "mov ah,[esi+1]" parm [esi] value [ax] modify exact [eax];
extern short read_swapped_right_byte(const unsigned char *);
#pragma aux read_swapped_right_byte = "mov bh,[esi]" parm [esi] value [bx] modify exact [ebx];
/* Pinned Watcom/x86 ABI: little-endian, 16-bit two's-complement short with
   no trapping representation. Snapshot the complete incoming AX/BX on every
   invocation, then replace only its high representation byte; AL/BL survive.
   Union reinterpretation is target-specific, not portable sample arithmetic.
   Keep the assembly readers for shapes whose live registers allocate differently. */
union pcm_word_representation { short word; unsigned char byte[2]; };
extern short incoming_left_word(void);
#pragma aux incoming_left_word = "" value [ax] modify exact [eax];
extern short incoming_right_word(void);
#pragma aux incoming_right_word = "" value [bx] modify exact [ebx];
extern short constrain_left_word(short);
#pragma aux constrain_left_word = "" parm [ax] value [ax] modify exact [];
extern short constrain_right_word(short);
#pragma aux constrain_right_word = "" parm [bx] value [bx] modify exact [];
#define load_left_byte(p) (left_bits.word=incoming_left_word(),left_bits.byte[1]=*(p),constrain_left_word(left_bits.word))
#define load_right_byte(p) (right_bits.word=incoming_right_word(),right_bits.byte[1]=*(p),constrain_right_word(right_bits.word))
#define read_left_byte_c(p) load_left_byte(p)
#define read_right_byte_c(p) load_right_byte((p)+1)
#define read_swapped_left_byte_c(p) load_left_byte((p)+1)
#define read_swapped_right_byte_c(p) load_right_byte(p)
/*
 * Add PCM input to the mixer accumulators, with optional channel swapping,
 * gain scaling and fractional source stepping. The source end is exclusive.
 * The output end is the last permitted frame start and is tested after each
 * frame, as in the original mixer ABI.
 *
 * The byte loads replace AH or BH and preserve the incoming low byte.
 * Keep the source cursor in ESI and the accumulator cursor in EDI.
 */
extern const unsigned char * volatile pcm_sample_end;
extern unsigned long * volatile pcm_mix_end;
extern short read_left_word(const unsigned char *);
#pragma aux read_left_word = "mov ax,[esi]" parm [esi] value [ax] modify exact [eax];
extern long extend_left(short);
#pragma aux extend_left = 0x0f 0xbf 0xc0 parm [ax] value [eax] modify exact [eax];
#define advance_word_src(p) ((p) + 2)
#define advance_dst(p) ((p) + 1)
extern short flip_left_bias(short);
#pragma aux flip_left_bias = "xor eax,8000h" parm [ax] value [ax] modify exact [eax];

extern const unsigned char *mix_source(void);
#pragma aux mix_source = "" value [esi] modify exact [];
extern unsigned long *mix_destination(void);
#pragma aux mix_destination = "" value [edi] modify exact [];
extern void set_mix_source(const unsigned char *);
#pragma aux set_mix_source = parm [esi] modify exact [];
extern void set_mix_destination(unsigned long *);
#pragma aux set_mix_destination = parm [edi] modify exact [];
extern const unsigned char *advance_byte_src(const unsigned char *);
#pragma aux advance_byte_src = "add esi,1" parm [esi] value [esi] modify exact [esi];

extern short read_right_word(const unsigned char *);
#pragma aux read_right_word = "mov bx,[esi+2]" parm [esi] value [bx] modify exact [ebx];
extern short read_swapped_right_word(const unsigned char *);
#pragma aux read_swapped_right_word = "mov bx,[esi]" parm [esi] value [bx] modify exact [ebx];
extern short read_swapped_left_word(const unsigned char *);
#pragma aux read_swapped_left_word = "mov ax,[esi+2]" parm [esi] value [ax] modify exact [eax];

extern short flip_right_bias(short);
#pragma aux flip_right_bias = "xor ebx,8000h" parm [bx] value [bx] modify exact [ebx];
extern long constrain_extended_right(long);
#pragma aux constrain_extended_right = "" parm [ebx] value [ebx] modify exact [];
#define extend_right(value) constrain_extended_right((long)(value))
extern short duplicate_left(short);
#pragma aux duplicate_left = 0x8b 0xd8 parm [ax] value [bx] modify exact [ebx];

/* Twice the signed product high word, truncated and sign-extended. */
extern volatile short pcm_left_gain, pcm_right_gain;
extern long scale_left(short);
#pragma aux scale_left = "movzx eax,ax" "imul word ptr pcm_left_gain" 0x03 0xd2 "movsx edx,dx" parm [ax] value [edx] modify exact [eax edx];
extern long scale_right(short);
#pragma aux scale_right = "movzx eax,bx" "imul word ptr pcm_right_gain" 0x03 0xd2 "movsx edx,dx" parm [bx] value [edx] modify exact [eax edx];

/* ECX holds the fractional cursor. Its carry selects the source step. */
extern unsigned long pcm_fractional_step, pcm_source_step[2];
extern const unsigned char *step_mono_byte(const unsigned char *);
#pragma aux step_mono_byte = "add ecx,pcm_fractional_step" "adc esi,pcm_source_step" parm [esi] value [esi] modify exact [ecx esi];
/* EBP is carry scratch in this frame-free ABI. Watcom reserves it. */
extern const unsigned char *step_frame(const unsigned char *);
#pragma aux step_frame = 0x33 0xed "add ecx,pcm_fractional_step" 0x13 0xed "add esi,pcm_source_step[ebp*4]" parm [esi] value [esi] modify exact [ecx esi];

#define advance_double_word_src(p) ((p) + 4)
#define advance_stereo_dst(p) ((p) + 2)

#define MIX_PCM(name, read_left, read_right, step, advance_output, \
                unsigned_pcm, stereo_in, stereo_out, scaled, swapped) \
    void name(const unsigned char *src, unsigned long *dst) \
    { \
        short left, right = 0; \
        union pcm_word_representation left_bits, right_bits; \
        long sample; \
        set_mix_source(src); \
        set_mix_destination(dst); \
        do { \
            if (mix_source() >= pcm_sample_end) \
                return; \
            if (stereo_in && swapped) \
                right = read_right(mix_source()); \
            left = read_left(mix_source()); \
            if (stereo_in && !swapped) \
                right = read_right(mix_source()); \
            if (unsigned_pcm) { \
                left = flip_left_bias(left); \
                if (stereo_in) \
                    right = flip_right_bias(right); \
            } \
 \
            if (scaled) { \
                if (stereo_out && !stereo_in) \
                    right = duplicate_left(left); \
                mix_destination()[0] += scale_left(left); \
                if (stereo_out) \
                    mix_destination()[1] += scale_right(right); \
            } else { \
                sample = extend_left(left); \
                mix_destination()[0] += sample; \
                if (stereo_out) \
                    mix_destination()[1] += stereo_in ? extend_right(right) : sample; \
            } \
 \
            set_mix_destination(advance_output(mix_destination())); \
            set_mix_source(step(mix_source())); \
        } while (mix_destination() <= pcm_mix_end); \
    }

void mix_mono_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_mono_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_mono_to_mono_signed_8, read_left_byte_c, read_right_byte_c,
        advance_byte_src, advance_dst, 0, 0, 0, 0, 0)

void mix_mono_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_mono_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_mono_to_mono_unsigned_8, read_left_byte, read_right_byte,
        advance_byte_src, advance_dst, 1, 0, 0, 0, 0)

void mix_mono_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_mono_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_mono_to_mono_signed_16, read_left_word, read_right_word,
        advance_word_src, advance_dst, 0, 0, 0, 0, 0)

void mix_mono_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_mono_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_mono_to_mono_unsigned_16, read_left_word, read_right_word,
        advance_word_src, advance_dst, 1, 0, 0, 0, 0)

void mix_mono_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_mono_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_mono_to_stereo_signed_8, read_left_byte, read_right_byte,
        advance_byte_src, advance_stereo_dst, 0, 0, 1, 0, 0)

void mix_mono_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_mono_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_mono_to_stereo_unsigned_8, read_left_byte, read_right_byte,
        advance_byte_src, advance_stereo_dst, 1, 0, 1, 0, 0)

void mix_mono_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_mono_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_mono_to_stereo_signed_16, read_left_word, read_right_word,
        advance_word_src, advance_stereo_dst, 0, 0, 1, 0, 0)

void mix_mono_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_mono_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_mono_to_stereo_unsigned_16, read_left_word, read_right_word,
        advance_word_src, advance_stereo_dst, 1, 0, 1, 0, 0)

void mix_stereo_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_stereo_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_stereo_to_mono_signed_8, read_left_byte, read_right_byte,
        advance_word_src, advance_dst, 0, 1, 0, 0, 0)

void mix_stereo_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_stereo_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_stereo_to_mono_unsigned_8, read_left_byte_c, read_right_byte_c,
        advance_word_src, advance_dst, 1, 1, 0, 0, 0)

void mix_stereo_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_stereo_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_stereo_to_mono_signed_16, read_left_word, read_right_word,
        advance_double_word_src, advance_dst, 0, 1, 0, 0, 0)

void mix_stereo_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_stereo_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_stereo_to_mono_unsigned_16, read_left_word, read_right_word,
        advance_double_word_src, advance_dst, 1, 1, 0, 0, 0)

void mix_stereo_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_stereo_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_stereo_to_stereo_signed_8, read_left_byte, read_right_byte,
        advance_word_src, advance_stereo_dst, 0, 1, 1, 0, 0)

void mix_stereo_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_stereo_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_stereo_to_stereo_unsigned_8, read_left_byte_c, read_right_byte_c,
        advance_word_src, advance_stereo_dst, 1, 1, 1, 0, 0)

void mix_stereo_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_stereo_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_stereo_to_stereo_signed_16, read_left_word, read_right_word,
        advance_double_word_src, advance_stereo_dst, 0, 1, 1, 0, 0)

void mix_stereo_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_stereo_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_stereo_to_stereo_unsigned_16, read_left_word, read_right_word,
        advance_double_word_src, advance_stereo_dst, 1, 1, 1, 0, 0)

void resample_mono_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_mono_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_mono_to_mono_signed_8, read_left_byte_c, read_right_byte_c,
        step_mono_byte, advance_dst, 0, 0, 0, 0, 0)

void resample_mono_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_mono_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_mono_to_mono_unsigned_8, read_left_byte, read_right_byte,
        step_mono_byte, advance_dst, 1, 0, 0, 0, 0)

void resample_mono_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_mono_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_mono_to_mono_signed_16, read_left_word, read_right_word,
        step_frame, advance_dst, 0, 0, 0, 0, 0)

void resample_mono_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_mono_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_mono_to_mono_unsigned_16, read_left_word, read_right_word,
        step_frame, advance_dst, 1, 0, 0, 0, 0)

void resample_mono_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_mono_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_mono_to_stereo_signed_8, read_left_byte, read_right_byte,
        step_mono_byte, advance_stereo_dst, 0, 0, 1, 0, 0)

void resample_mono_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_mono_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_mono_to_stereo_unsigned_8, read_left_byte, read_right_byte,
        step_mono_byte, advance_stereo_dst, 1, 0, 1, 0, 0)

void resample_mono_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_mono_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_mono_to_stereo_signed_16, read_left_word, read_right_word,
        step_frame, advance_stereo_dst, 0, 0, 1, 0, 0)

void resample_mono_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_mono_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_mono_to_stereo_unsigned_16, read_left_word, read_right_word,
        step_frame, advance_stereo_dst, 1, 0, 1, 0, 0)

void resample_stereo_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_stereo_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_stereo_to_mono_signed_8, read_left_byte, read_right_byte,
        step_frame, advance_dst, 0, 1, 0, 0, 0)

void resample_stereo_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_stereo_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_stereo_to_mono_unsigned_8, read_left_byte_c, read_right_byte_c,
        step_frame, advance_dst, 1, 1, 0, 0, 0)

void resample_stereo_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_stereo_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_stereo_to_mono_signed_16, read_left_word, read_right_word,
        step_frame, advance_dst, 0, 1, 0, 0, 0)

void resample_stereo_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_stereo_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_stereo_to_mono_unsigned_16, read_left_word, read_right_word,
        step_frame, advance_dst, 1, 1, 0, 0, 0)

void resample_stereo_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_stereo_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_stereo_to_stereo_signed_8, read_left_byte, read_right_byte,
        step_frame, advance_stereo_dst, 0, 1, 1, 0, 0)

void resample_stereo_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_stereo_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_stereo_to_stereo_unsigned_8, read_left_byte_c, read_right_byte_c,
        step_frame, advance_stereo_dst, 1, 1, 1, 0, 0)

void resample_stereo_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_stereo_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_stereo_to_stereo_signed_16, read_left_word, read_right_word,
        step_frame, advance_stereo_dst, 0, 1, 1, 0, 0)

void resample_stereo_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_stereo_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_stereo_to_stereo_unsigned_16, read_left_word, read_right_word,
        step_frame, advance_stereo_dst, 1, 1, 1, 0, 0)

void mix_scaled_mono_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_mono_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi edx];
MIX_PCM(mix_scaled_mono_to_mono_signed_8, read_left_byte_c, read_right_byte_c,
        advance_byte_src, advance_dst, 0, 0, 0, 1, 0)

void mix_scaled_mono_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_mono_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi edx];
MIX_PCM(mix_scaled_mono_to_mono_unsigned_8, read_left_byte_c, read_right_byte_c,
        advance_byte_src, advance_dst, 1, 0, 0, 1, 0)

void mix_scaled_mono_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_mono_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi edx];
MIX_PCM(mix_scaled_mono_to_mono_signed_16, read_left_word, read_right_word,
        advance_word_src, advance_dst, 0, 0, 0, 1, 0)

void mix_scaled_mono_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_mono_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi edx];
MIX_PCM(mix_scaled_mono_to_mono_unsigned_16, read_left_word, read_right_word,
        advance_word_src, advance_dst, 1, 0, 0, 1, 0)

void mix_scaled_mono_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_mono_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_mono_to_stereo_signed_8, read_left_byte_c, read_right_byte_c,
        advance_byte_src, advance_stereo_dst, 0, 0, 1, 1, 0)

void mix_scaled_mono_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_mono_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_mono_to_stereo_unsigned_8, read_left_byte_c, read_right_byte_c,
        advance_byte_src, advance_stereo_dst, 1, 0, 1, 1, 0)

void mix_scaled_mono_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_mono_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_mono_to_stereo_signed_16, read_left_word, read_right_word,
        advance_word_src, advance_stereo_dst, 0, 0, 1, 1, 0)

void mix_scaled_mono_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_mono_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_mono_to_stereo_unsigned_16, read_left_word, read_right_word,
        advance_word_src, advance_stereo_dst, 1, 0, 1, 1, 0)

void mix_scaled_stereo_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_stereo_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_stereo_to_mono_signed_8, read_left_byte_c, read_right_byte_c,
        advance_word_src, advance_dst, 0, 1, 0, 1, 0)

void mix_scaled_stereo_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_stereo_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_stereo_to_mono_unsigned_8, read_left_byte_c, read_right_byte_c,
        advance_word_src, advance_dst, 1, 1, 0, 1, 0)

void mix_scaled_stereo_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_stereo_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_stereo_to_mono_signed_16, read_left_word, read_right_word,
        advance_double_word_src, advance_dst, 0, 1, 0, 1, 0)

void mix_scaled_stereo_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_stereo_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_stereo_to_mono_unsigned_16, read_left_word, read_right_word,
        advance_double_word_src, advance_dst, 1, 1, 0, 1, 0)

void mix_scaled_stereo_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_stereo_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_stereo_to_stereo_signed_8, read_left_byte, read_right_byte,
        advance_word_src, advance_stereo_dst, 0, 1, 1, 1, 0)

void mix_scaled_stereo_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_stereo_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_stereo_to_stereo_unsigned_8, read_left_byte_c, read_right_byte_c,
        advance_word_src, advance_stereo_dst, 1, 1, 1, 1, 0)

void mix_scaled_stereo_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_stereo_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_stereo_to_stereo_signed_16, read_left_word, read_right_word,
        advance_double_word_src, advance_stereo_dst, 0, 1, 1, 1, 0)

void mix_scaled_stereo_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_stereo_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_stereo_to_stereo_unsigned_16, read_left_word, read_right_word,
        advance_double_word_src, advance_stereo_dst, 1, 1, 1, 1, 0)

void resample_scaled_mono_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_mono_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi edx ecx];
MIX_PCM(resample_scaled_mono_to_mono_signed_8, read_left_byte_c, read_right_byte_c,
        step_mono_byte, advance_dst, 0, 0, 0, 1, 0)

void resample_scaled_mono_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_mono_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi edx ecx];
MIX_PCM(resample_scaled_mono_to_mono_unsigned_8, read_left_byte_c, read_right_byte_c,
        step_mono_byte, advance_dst, 1, 0, 0, 1, 0)

void resample_scaled_mono_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_mono_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi edx ecx];
MIX_PCM(resample_scaled_mono_to_mono_signed_16, read_left_word, read_right_word,
        step_frame, advance_dst, 0, 0, 0, 1, 0)

void resample_scaled_mono_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_mono_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi edx ecx];
MIX_PCM(resample_scaled_mono_to_mono_unsigned_16, read_left_word, read_right_word,
        step_frame, advance_dst, 1, 0, 0, 1, 0)

void resample_scaled_mono_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_mono_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_mono_to_stereo_signed_8, read_left_byte_c, read_right_byte_c,
        step_mono_byte, advance_stereo_dst, 0, 0, 1, 1, 0)

void resample_scaled_mono_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_mono_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_mono_to_stereo_unsigned_8, read_left_byte_c, read_right_byte_c,
        step_mono_byte, advance_stereo_dst, 1, 0, 1, 1, 0)

void resample_scaled_mono_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_mono_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_mono_to_stereo_signed_16, read_left_word, read_right_word,
        step_frame, advance_stereo_dst, 0, 0, 1, 1, 0)

void resample_scaled_mono_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_mono_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_mono_to_stereo_unsigned_16, read_left_word, read_right_word,
        step_frame, advance_stereo_dst, 1, 0, 1, 1, 0)

void resample_scaled_stereo_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_stereo_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_stereo_to_mono_signed_8, read_left_byte, read_right_byte_c,
        step_frame, advance_dst, 0, 1, 0, 1, 0)

void resample_scaled_stereo_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_stereo_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_stereo_to_mono_unsigned_8, read_left_byte_c, read_right_byte_c,
        step_frame, advance_dst, 1, 1, 0, 1, 0)

void resample_scaled_stereo_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_stereo_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_stereo_to_mono_signed_16, read_left_word, read_right_word,
        step_frame, advance_dst, 0, 1, 0, 1, 0)

void resample_scaled_stereo_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_stereo_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_stereo_to_mono_unsigned_16, read_left_word, read_right_word,
        step_frame, advance_dst, 1, 1, 0, 1, 0)

void resample_scaled_stereo_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_stereo_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_stereo_to_stereo_signed_8, read_left_byte, read_right_byte,
        step_frame, advance_stereo_dst, 0, 1, 1, 1, 0)

void resample_scaled_stereo_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_stereo_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_stereo_to_stereo_unsigned_8, read_left_byte_c, read_right_byte_c,
        step_frame, advance_stereo_dst, 1, 1, 1, 1, 0)

void resample_scaled_stereo_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_stereo_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_stereo_to_stereo_signed_16, read_left_word, read_right_word,
        step_frame, advance_stereo_dst, 0, 1, 1, 1, 0)

void resample_scaled_stereo_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_stereo_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_stereo_to_stereo_unsigned_16, read_left_word, read_right_word,
        step_frame, advance_stereo_dst, 1, 1, 1, 1, 0)

void mix_swapped_mono_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_mono_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_swapped_mono_to_mono_signed_8, read_left_byte_c, read_right_byte_c,
        advance_byte_src, advance_dst, 0, 0, 0, 0, 1)

void mix_swapped_mono_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_mono_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_swapped_mono_to_mono_unsigned_8, read_left_byte, read_right_byte,
        advance_byte_src, advance_dst, 1, 0, 0, 0, 1)

void mix_swapped_mono_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_mono_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_swapped_mono_to_mono_signed_16, read_left_word, read_right_word,
        advance_word_src, advance_dst, 0, 0, 0, 0, 1)

void mix_swapped_mono_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_mono_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_swapped_mono_to_mono_unsigned_16, read_left_word, read_right_word,
        advance_word_src, advance_dst, 1, 0, 0, 0, 1)

void mix_swapped_mono_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_mono_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_swapped_mono_to_stereo_signed_8, read_left_byte, read_right_byte,
        advance_byte_src, advance_stereo_dst, 0, 0, 1, 0, 1)

void mix_swapped_mono_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_mono_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_swapped_mono_to_stereo_unsigned_8, read_left_byte, read_right_byte,
        advance_byte_src, advance_stereo_dst, 1, 0, 1, 0, 1)

void mix_swapped_mono_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_mono_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_swapped_mono_to_stereo_signed_16, read_left_word, read_right_word,
        advance_word_src, advance_stereo_dst, 0, 0, 1, 0, 1)

void mix_swapped_mono_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_mono_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi];
MIX_PCM(mix_swapped_mono_to_stereo_unsigned_16, read_left_word, read_right_word,
        advance_word_src, advance_stereo_dst, 1, 0, 1, 0, 1)

void mix_swapped_stereo_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_stereo_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_swapped_stereo_to_mono_signed_8, read_swapped_left_byte, read_swapped_right_byte,
        advance_word_src, advance_dst, 0, 1, 0, 0, 1)

void mix_swapped_stereo_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_stereo_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_swapped_stereo_to_mono_unsigned_8, read_swapped_left_byte_c, read_swapped_right_byte_c,
        advance_word_src, advance_dst, 1, 1, 0, 0, 1)

void mix_swapped_stereo_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_stereo_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_swapped_stereo_to_mono_signed_16, read_swapped_left_word, read_swapped_right_word,
        advance_double_word_src, advance_dst, 0, 1, 0, 0, 1)

void mix_swapped_stereo_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_stereo_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_swapped_stereo_to_mono_unsigned_16, read_swapped_left_word, read_swapped_right_word,
        advance_double_word_src, advance_dst, 1, 1, 0, 0, 1)

void mix_swapped_stereo_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_stereo_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_swapped_stereo_to_stereo_signed_8, read_swapped_left_byte, read_swapped_right_byte,
        advance_word_src, advance_stereo_dst, 0, 1, 1, 0, 1)

void mix_swapped_stereo_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_stereo_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_swapped_stereo_to_stereo_unsigned_8, read_swapped_left_byte_c, read_swapped_right_byte_c,
        advance_word_src, advance_stereo_dst, 1, 1, 1, 0, 1)

void mix_swapped_stereo_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_stereo_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_swapped_stereo_to_stereo_signed_16, read_swapped_left_word, read_swapped_right_word,
        advance_double_word_src, advance_stereo_dst, 0, 1, 1, 0, 1)

void mix_swapped_stereo_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_swapped_stereo_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx];
MIX_PCM(mix_swapped_stereo_to_stereo_unsigned_16, read_swapped_left_word, read_swapped_right_word,
        advance_double_word_src, advance_stereo_dst, 1, 1, 1, 0, 1)

void resample_swapped_mono_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_mono_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_swapped_mono_to_mono_signed_8, read_left_byte_c, read_right_byte_c,
        step_mono_byte, advance_dst, 0, 0, 0, 0, 1)

void resample_swapped_mono_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_mono_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_swapped_mono_to_mono_unsigned_8, read_left_byte, read_right_byte,
        step_mono_byte, advance_dst, 1, 0, 0, 0, 1)

void resample_swapped_mono_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_mono_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_swapped_mono_to_mono_signed_16, read_left_word, read_right_word,
        step_frame, advance_dst, 0, 0, 0, 0, 1)

void resample_swapped_mono_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_mono_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_swapped_mono_to_mono_unsigned_16, read_left_word, read_right_word,
        step_frame, advance_dst, 1, 0, 0, 0, 1)

void resample_swapped_mono_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_mono_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_swapped_mono_to_stereo_signed_8, read_left_byte, read_right_byte,
        step_mono_byte, advance_stereo_dst, 0, 0, 1, 0, 1)

void resample_swapped_mono_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_mono_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_swapped_mono_to_stereo_unsigned_8, read_left_byte, read_right_byte,
        step_mono_byte, advance_stereo_dst, 1, 0, 1, 0, 1)

void resample_swapped_mono_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_mono_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_swapped_mono_to_stereo_signed_16, read_left_word, read_right_word,
        step_frame, advance_stereo_dst, 0, 0, 1, 0, 1)

void resample_swapped_mono_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_mono_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ecx];
MIX_PCM(resample_swapped_mono_to_stereo_unsigned_16, read_left_word, read_right_word,
        step_frame, advance_stereo_dst, 1, 0, 1, 0, 1)

void resample_swapped_stereo_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_stereo_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_swapped_stereo_to_mono_signed_8, read_swapped_left_byte, read_swapped_right_byte,
        step_frame, advance_dst, 0, 1, 0, 0, 1)

void resample_swapped_stereo_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_stereo_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_swapped_stereo_to_mono_unsigned_8, read_swapped_left_byte_c, read_swapped_right_byte_c,
        step_frame, advance_dst, 1, 1, 0, 0, 1)

void resample_swapped_stereo_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_stereo_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_swapped_stereo_to_mono_signed_16, read_swapped_left_word, read_swapped_right_word,
        step_frame, advance_dst, 0, 1, 0, 0, 1)

void resample_swapped_stereo_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_stereo_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_swapped_stereo_to_mono_unsigned_16, read_swapped_left_word, read_swapped_right_word,
        step_frame, advance_dst, 1, 1, 0, 0, 1)

void resample_swapped_stereo_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_stereo_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_swapped_stereo_to_stereo_signed_8, read_swapped_left_byte, read_swapped_right_byte,
        step_frame, advance_stereo_dst, 0, 1, 1, 0, 1)

void resample_swapped_stereo_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_stereo_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_swapped_stereo_to_stereo_unsigned_8, read_swapped_left_byte_c, read_swapped_right_byte_c,
        step_frame, advance_stereo_dst, 1, 1, 1, 0, 1)

void resample_swapped_stereo_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_stereo_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_swapped_stereo_to_stereo_signed_16, read_swapped_left_word, read_swapped_right_word,
        step_frame, advance_stereo_dst, 0, 1, 1, 0, 1)

void resample_swapped_stereo_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_swapped_stereo_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx ecx];
MIX_PCM(resample_swapped_stereo_to_stereo_unsigned_16, read_swapped_left_word, read_swapped_right_word,
        step_frame, advance_stereo_dst, 1, 1, 1, 0, 1)

void mix_scaled_swapped_mono_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_mono_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi edx];
MIX_PCM(mix_scaled_swapped_mono_to_mono_signed_8, read_left_byte_c, read_right_byte_c,
        advance_byte_src, advance_dst, 0, 0, 0, 1, 1)

void mix_scaled_swapped_mono_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_mono_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi edx];
MIX_PCM(mix_scaled_swapped_mono_to_mono_unsigned_8, read_left_byte_c, read_right_byte_c,
        advance_byte_src, advance_dst, 1, 0, 0, 1, 1)

void mix_scaled_swapped_mono_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_mono_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi edx];
MIX_PCM(mix_scaled_swapped_mono_to_mono_signed_16, read_left_word, read_right_word,
        advance_word_src, advance_dst, 0, 0, 0, 1, 1)

void mix_scaled_swapped_mono_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_mono_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi edx];
MIX_PCM(mix_scaled_swapped_mono_to_mono_unsigned_16, read_left_word, read_right_word,
        advance_word_src, advance_dst, 1, 0, 0, 1, 1)

void mix_scaled_swapped_mono_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_mono_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_swapped_mono_to_stereo_signed_8, read_left_byte_c, read_right_byte_c,
        advance_byte_src, advance_stereo_dst, 0, 0, 1, 1, 1)

void mix_scaled_swapped_mono_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_mono_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_swapped_mono_to_stereo_unsigned_8, read_left_byte_c, read_right_byte_c,
        advance_byte_src, advance_stereo_dst, 1, 0, 1, 1, 1)

void mix_scaled_swapped_mono_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_mono_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_swapped_mono_to_stereo_signed_16, read_left_word, read_right_word,
        advance_word_src, advance_stereo_dst, 0, 0, 1, 1, 1)

void mix_scaled_swapped_mono_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_mono_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_swapped_mono_to_stereo_unsigned_16, read_left_word, read_right_word,
        advance_word_src, advance_stereo_dst, 1, 0, 1, 1, 1)

void mix_scaled_swapped_stereo_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_stereo_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_swapped_stereo_to_mono_signed_8, read_swapped_left_byte, read_swapped_right_byte,
        advance_word_src, advance_dst, 0, 1, 0, 1, 1)

void mix_scaled_swapped_stereo_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_stereo_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_swapped_stereo_to_mono_unsigned_8, read_swapped_left_byte_c, read_swapped_right_byte_c,
        advance_word_src, advance_dst, 1, 1, 0, 1, 1)

void mix_scaled_swapped_stereo_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_stereo_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_swapped_stereo_to_mono_signed_16, read_swapped_left_word, read_swapped_right_word,
        advance_double_word_src, advance_dst, 0, 1, 0, 1, 1)

void mix_scaled_swapped_stereo_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_stereo_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_swapped_stereo_to_mono_unsigned_16, read_swapped_left_word, read_swapped_right_word,
        advance_double_word_src, advance_dst, 1, 1, 0, 1, 1)

void mix_scaled_swapped_stereo_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_stereo_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_swapped_stereo_to_stereo_signed_8, read_swapped_left_byte, read_swapped_right_byte,
        advance_word_src, advance_stereo_dst, 0, 1, 1, 1, 1)

void mix_scaled_swapped_stereo_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_stereo_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_swapped_stereo_to_stereo_unsigned_8, read_swapped_left_byte_c, read_swapped_right_byte_c,
        advance_word_src, advance_stereo_dst, 1, 1, 1, 1, 1)

void mix_scaled_swapped_stereo_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_stereo_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_swapped_stereo_to_stereo_signed_16, read_swapped_left_word, read_swapped_right_word,
        advance_double_word_src, advance_stereo_dst, 0, 1, 1, 1, 1)

void mix_scaled_swapped_stereo_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux mix_scaled_swapped_stereo_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx edx];
MIX_PCM(mix_scaled_swapped_stereo_to_stereo_unsigned_16, read_swapped_left_word, read_swapped_right_word,
        advance_double_word_src, advance_stereo_dst, 1, 1, 1, 1, 1)

void resample_scaled_swapped_mono_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_mono_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi edx ecx];
MIX_PCM(resample_scaled_swapped_mono_to_mono_signed_8, read_left_byte_c, read_right_byte_c,
        step_mono_byte, advance_dst, 0, 0, 0, 1, 1)

void resample_scaled_swapped_mono_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_mono_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi edx ecx];
MIX_PCM(resample_scaled_swapped_mono_to_mono_unsigned_8, read_left_byte_c, read_right_byte_c,
        step_mono_byte, advance_dst, 1, 0, 0, 1, 1)

void resample_scaled_swapped_mono_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_mono_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi edx ecx];
MIX_PCM(resample_scaled_swapped_mono_to_mono_signed_16, read_left_word, read_right_word,
        step_frame, advance_dst, 0, 0, 0, 1, 1)

void resample_scaled_swapped_mono_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_mono_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi edx ecx];
MIX_PCM(resample_scaled_swapped_mono_to_mono_unsigned_16, read_left_word, read_right_word,
        step_frame, advance_dst, 1, 0, 0, 1, 1)

void resample_scaled_swapped_mono_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_mono_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_swapped_mono_to_stereo_signed_8, read_left_byte_c, read_right_byte_c,
        step_mono_byte, advance_stereo_dst, 0, 0, 1, 1, 1)

void resample_scaled_swapped_mono_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_mono_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_swapped_mono_to_stereo_unsigned_8, read_left_byte_c, read_right_byte_c,
        step_mono_byte, advance_stereo_dst, 1, 0, 1, 1, 1)

void resample_scaled_swapped_mono_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_mono_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_swapped_mono_to_stereo_signed_16, read_left_word, read_right_word,
        step_frame, advance_stereo_dst, 0, 0, 1, 1, 1)

void resample_scaled_swapped_mono_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_mono_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_swapped_mono_to_stereo_unsigned_16, read_left_word, read_right_word,
        step_frame, advance_stereo_dst, 1, 0, 1, 1, 1)

void resample_scaled_swapped_stereo_to_mono_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_stereo_to_mono_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_swapped_stereo_to_mono_signed_8, read_swapped_left_byte, read_swapped_right_byte,
        step_frame, advance_dst, 0, 1, 0, 1, 1)

void resample_scaled_swapped_stereo_to_mono_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_stereo_to_mono_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_swapped_stereo_to_mono_unsigned_8, read_swapped_left_byte_c, read_swapped_right_byte_c,
        step_frame, advance_dst, 1, 1, 0, 1, 1)

void resample_scaled_swapped_stereo_to_mono_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_stereo_to_mono_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_swapped_stereo_to_mono_signed_16, read_swapped_left_word, read_swapped_right_word,
        step_frame, advance_dst, 0, 1, 0, 1, 1)

void resample_scaled_swapped_stereo_to_mono_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_stereo_to_mono_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_swapped_stereo_to_mono_unsigned_16, read_swapped_left_word, read_swapped_right_word,
        step_frame, advance_dst, 1, 1, 0, 1, 1)

void resample_scaled_swapped_stereo_to_stereo_signed_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_stereo_to_stereo_signed_8 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_swapped_stereo_to_stereo_signed_8, read_swapped_left_byte, read_swapped_right_byte,
        step_frame, advance_stereo_dst, 0, 1, 1, 1, 1)

void resample_scaled_swapped_stereo_to_stereo_unsigned_8(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_stereo_to_stereo_unsigned_8 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_swapped_stereo_to_stereo_unsigned_8, read_swapped_left_byte_c, read_swapped_right_byte_c,
        step_frame, advance_stereo_dst, 1, 1, 1, 1, 1)

void resample_scaled_swapped_stereo_to_stereo_signed_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_stereo_to_stereo_signed_16 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_swapped_stereo_to_stereo_signed_16, read_swapped_left_word, read_swapped_right_word,
        step_frame, advance_stereo_dst, 0, 1, 1, 1, 1)

void resample_scaled_swapped_stereo_to_stereo_unsigned_16(const unsigned char *, unsigned long *);
#pragma aux resample_scaled_swapped_stereo_to_stereo_unsigned_16 parm [esi] [edi] modify exact [eax esi edi ebx edx ecx];
MIX_PCM(resample_scaled_swapped_stereo_to_stereo_unsigned_16, read_swapped_left_word, read_swapped_right_word,
        step_frame, advance_stereo_dst, 1, 1, 1, 1, 1)
