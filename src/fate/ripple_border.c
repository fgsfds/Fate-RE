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
