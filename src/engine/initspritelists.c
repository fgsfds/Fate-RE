// Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT.
typedef struct {
    char reserved_position[24];
    short sectnum, statnum;
    char reserved_tail[16];
} Sprite;

#define MAXSECTORS 1024
#define MAXSTATUS 1024
#define MAXSPRITES 4096

extern Sprite sprite[];
extern short headspritesect[], prevspritesect[], nextspritesect[];
extern short headspritestat[], prevspritestat[], nextspritestat[];

/* Restore the saved registers through the existing rasterizer tail. */
extern void shared_graphics_epilogue(void);
#pragma aux shared_graphics_epilogue aborts modify exact [];

void initspritelists(void)
{
    long i;

    /* The extra sector and status head entries own the unused slots. */
    for (i = 0; i < MAXSECTORS; i++)
        headspritesect[i] = -1;
    headspritesect[MAXSECTORS] = 0;
    for (i = 0; i < MAXSPRITES; i++) {
        prevspritesect[i] = i - 1;
        nextspritesect[i] = i + 1;
        sprite[i].sectnum = MAXSECTORS;
    }
    prevspritesect[0] = -1;
    nextspritesect[MAXSPRITES - 1] = -1;

    for (i = 0; i < MAXSTATUS; i++)
        headspritestat[i] = -1;
    headspritestat[MAXSTATUS] = 0;
    for (i = 0; i < MAXSPRITES; i++) {
        prevspritestat[i] = i - 1;
        nextspritestat[i] = i + 1;
        sprite[i].statnum = MAXSTATUS;
    }
    prevspritestat[0] = -1;
    nextspritestat[MAXSPRITES - 1] = -1;
    shared_graphics_epilogue();
}
