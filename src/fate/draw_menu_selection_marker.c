#define MENU_MARKER_TILE 0x824

#pragma pack(push, 1)
typedef struct {
    unsigned char flags;
    short type;
    char reserved_before_tile[4];
    long tile;
    long zoom;
    char reserved_before_y[2];
    short y;
    short marker_scale;
} MenuMarkerEntry;
#pragma pack(pop)

extern short menu_tile_frame, tilesizy[];
extern long menu_marker_scale[];
extern long presentation_width, presentation_height;
extern void rotatesprite(long, long, long, short, short, signed char, unsigned char,
                         unsigned char, long, long, long, long);
#pragma aux rotatesprite modify exact [eax edx ebx ecx];
extern long hold_marker_y(long);
#pragma aux hold_marker_y = parm [edi] value [edi] modify exact [];

extern short hold_entry_type(short);
#pragma aux hold_entry_type = parm [cx] value [cx] modify exact [];
extern long height_in_ebx(long);
#pragma aux height_in_ebx = parm [ebx] value [ebx] modify exact [];
extern long value_in_edx(long);
#pragma aux value_in_edx = parm [edx] value [edx] modify exact [];

/* Watcom's first marker uses EDI for the projected row and pushes the
 * remaining rotate-sprite arguments while finishing the fixed-point setup. */
extern long draw_left_marker(MenuMarkerEntry *, long, long, long);
#pragma aux draw_left_marker = \
    "push edx" "push ebx" "push 0" "push 0" \
    "shl edi,10h" "mov dx,word ptr [menu_tile_frame]" "push 2" \
    "xor ecx,ecx" "add edx,824h" "push 0" "movsx ebx,word ptr [eax+13h]" \
    "push 0" "movsx edx,dx" "mov eax,200000h" "push edx" \
    "mov ebx,dword ptr menu_marker_scale[ebx*4]" "mov edx,edi" "call rotatesprite" \
    parm [eax] [edi] [ebx] [edx] value [edi] modify exact [eax ebx ecx edx edi];

extern long index_in_esi(long);
#pragma aux index_in_esi = parm [esi] value [esi] modify exact [];
extern MenuMarkerEntry **hold_marker_row(MenuMarkerEntry **);
#pragma aux hold_marker_row = parm [esi] value [esi] modify exact [];

void draw_menu_selection_marker(int selected, int ignored, MenuMarkerEntry **items);
#pragma aux draw_menu_selection_marker parm routine [eax] [edx] [ebx] modify exact [eax edx ebx];
void draw_menu_selection_marker(int selected, int ignored, MenuMarkerEntry **items)
{
    long index = index_in_esi((short)selected);
    long offset = index_in_esi(index * 4L);
    MenuMarkerEntry **row = hold_marker_row((MenuMarkerEntry **)((char *)items + offset));
    MenuMarkerEntry *entry = *row;
    long y, height, right, bottom, half;
    short type;
    if (!entry->marker_scale)
        return;

    height = height_in_ebx(tilesizy[MENU_MARKER_TILE]);
    y = hold_marker_y(entry->y);
    half = value_in_edx(height);
    type = hold_entry_type(entry->type);
    half >>= 1;
    height >>= 2;
    y += half;
    bottom = presentation_height;
    y -= height;
    right = presentation_width;
    --bottom;
    --right;

    if (type == 6) {
        if (!entry->tile)
            return;
        rotatesprite(90 * 65536L, 100 * 65536L, entry->zoom, 512, entry->tile, 0, 0, 0x44,
                     0, 0, right, bottom);
    } else {
        y = draw_left_marker(entry, y, right, bottom);
        rotatesprite(288 * 65536L, y, menu_marker_scale[(*row)->marker_scale],
                     0, MENU_MARKER_TILE + menu_tile_frame, 0, 0, 2, 0, 0,
                     presentation_width - 1, presentation_height - 1);
    }
}
