/* Top/bottom toroidal border pass over assembly-owned raw storage.
 * The input points to 16,384 tile bytes. Only the counter initialization and
 * loop body link; the private ESI save/copy/restore and identity EDX copy
 * remain unlinked and guarded. The retained caller already supplies EDX. */
#pragma pack(push,1)
typedef struct { unsigned long value; } RippleWord;
typedef struct { unsigned char left; RippleWord word[32]; unsigned char tail[3]; } RippleRow;
typedef struct { RippleRow row[130]; } RipplePlane;
#pragma pack(pop)
extern RipplePlane ripple_buffer;
#define PLANE ((unsigned char *)&ripple_buffer)
extern unsigned char border_bl(unsigned char);
#pragma aux border_bl = "" parm [bl] value [bl] modify exact [];
extern unsigned char border_al(unsigned char);
#pragma aux border_al = "" parm [al] value [al] modify exact [];
extern int border_ecx(int);
#pragma aux border_ecx = "" parm [ecx] value [ecx] modify exact [];
extern const unsigned char *border_pointer_edx(const unsigned char *);
#pragma aux border_pointer_edx = "" parm [edx] value [edx] modify exact [];
void ripple_border_columns(const unsigned char *);
#pragma aux ripple_border_columns parm [edx] modify exact [eax ebx ecx edx];
void ripple_border_columns(const unsigned char *pixels)
{
    int column = border_ecx(0);
    goto test_column;
    do {
        unsigned char first;
        unsigned char last;
        pixels = border_pointer_edx(pixels);
        last = border_bl(pixels[16256+column]);
        last = border_bl(last & 31);
        PLANE[1 + column] = last;
        first = border_al(pixels[column]);
        column = border_ecx(column + 1);
        first = border_al(first & 31);
        PLANE[17028 + column] = first;
    test_column:
        ;
    } while (column < 128);
}

/* Preserve the original final-padding-byte corner destination. */
void ripple_border_corners(const unsigned char *);
#pragma aux ripple_border_corners parm [edx] modify exact [eax edx];
void ripple_border_corners(const unsigned char *pixels)
{
    pixels = border_pointer_edx(pixels);
    PLANE[0] = border_al(pixels[16383] & 31);
    PLANE[129] = border_al(pixels[16256] & 31);
    PLANE[17028] = border_al(pixels[127] & 31);
    PLANE[17159] = border_al(pixels[0] & 31);
}

/* The retained initial compare reaches the body with EBP in 0..127. */
extern int vertical_row_ebp(void);
#pragma aux vertical_row_ebp = "" parm [] value [ebp] modify exact [];
extern int vertical_offset_ebx(int);
#pragma aux vertical_offset_ebx = "" parm [ebx] value [ebx] modify exact [];
extern int vertical_offset_eax(int);
#pragma aux vertical_offset_eax = "" parm [eax] value [eax] modify exact [];
extern const unsigned char *vertical_pixels_edx(const unsigned char *);
#pragma aux vertical_pixels_edx = "" parm [edx] value [edx] modify exact [];
extern unsigned char vertical_edge_al(unsigned char);
#pragma aux vertical_edge_al = "" parm [al] value [al] modify exact [];
extern unsigned char vertical_edge_bl(unsigned char);
#pragma aux vertical_edge_bl = "" parm [bl] value [bl] modify exact [];
extern unsigned char vertical_edge_cl(unsigned char);
#pragma aux vertical_edge_cl = "" parm [cl] value [cl] modify exact [];

/* The retained INC EBP joins these two bodies. The head hands off the
 * masked last column in AL and the old tile byte offset in EBX. */
extern unsigned char vertical_head_handoff(unsigned char, int);
#pragma aux vertical_head_handoff = "" parm [al] [ebx] value [al] modify exact [];

unsigned char ripple_vertical_head(const unsigned char *);
#pragma aux ripple_vertical_head parm [edx] value [al] modify exact [eax ebx];

unsigned char ripple_vertical_head(const unsigned char *pixels)
{
    int source = vertical_offset_ebx(vertical_row_ebp());
    unsigned char edge;

    source = vertical_offset_ebx(source << 7);
    edge = vertical_edge_al(vertical_pixels_edx(pixels)[source + 127]);
    edge = vertical_edge_al(edge & 31);
    return vertical_head_handoff(edge, source);
}

/* EBP is now 1..128; AL and EBX still contain the head's results.
 * Three ordinary unused slots leave the uchar scratch at ESP+16. */
void ripple_vertical_tail(const unsigned char *, int, unsigned int,
                          unsigned int, unsigned int, unsigned int, unsigned char);
#pragma aux ripple_vertical_tail parm caller [edx] [ebx] [eax] [] \
    modify exact [eax ebx ecx];

void ripple_vertical_tail(const unsigned char *pixels, int source, unsigned int edge_word,
                          unsigned int unused1, unsigned int unused2, unsigned int unused3,
                          volatile unsigned char scratch)
{
    int row;
    int stride_words;
    unsigned char edge;

    scratch = (unsigned char)edge_word;
    row = vertical_row_ebp();
    stride_words = vertical_offset_eax(row);
    stride_words = vertical_offset_eax(stride_words << 5);
    stride_words = vertical_offset_eax(stride_words + row);
    PLANE[stride_words * 4] = vertical_edge_cl(scratch);
    edge = vertical_edge_bl(vertical_pixels_edx(pixels)[source]);
    edge = vertical_edge_bl(edge & 31);
    PLANE[stride_words * 4 + 129] = edge;
}
