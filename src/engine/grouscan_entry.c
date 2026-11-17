/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern unsigned char sector[], picanm[], walock[], gotpic[], pow2char[];
extern short globalpicnum, tilesizx[], tilesizy[];
extern long camera_x, camera_y, camera_z, globalorientation, globalshade, globalpal;
extern long waloff[];
extern void getceilzofslope(void), getflorzofslope(void), grouscan_restore_stack(void);
extern void animateoffs(void), loadtile(void);

extern long from_ax(void);
#pragma aux from_ax = value [eax] modify exact [];
extern void in_ax(long value);
#pragma aux in_ax = "" parm [eax] modify exact [];
extern long from_bx(void);
#pragma aux from_bx = value [ebx] modify exact [];
extern void in_bx(long value);
#pragma aux in_bx = "" parm [ebx] modify exact [];
extern long from_cx(void);
#pragma aux from_cx = value [ecx] modify exact [];
extern long from_bp(void);
#pragma aux from_bp = value [ebp] modify exact [];
extern void in_dx(long value);
#pragma aux in_dx = "" parm [edx] modify exact [];

extern void save_slope_scan_frame(void);
#pragma aux save_slope_scan_frame = "push esi" "push edi" "push ebp" "sub esp, 0x60" "push eax" "push edx" \
    "mov esi, ebx" "mov byte ptr [esp + 0x64], cl" "movsx ecx, bx" modify exact [eax ecx esi];

extern void read_sector_table(void);
#pragma aux read_sector_table = "mov ebp, offset sector" modify exact [];

extern void select_floor_plane(void);
#pragma aux select_floor_plane = "add ebp, eax" "cmp byte ptr [esp + 0x64], 0" "db 75h, 52h" /* marker-rel8 +5,+6 */ modify exact [];

extern void require_visible_ceiling(void);
#pragma aux require_visible_ceiling = "call getceilzofslope" "cmp eax, dword ptr [camera_z]" "jge near grouscan_restore_stack" \
    modify exact [eax ebx ecx edx esi edi];

extern void require_visible_floor(void);
#pragma aux require_visible_floor = "call getflorzofslope" "cmp eax, dword ptr [camera_z]" "jle near grouscan_restore_stack" \
    modify exact [eax ebx ecx edx esi edi];

extern void read_ceiling_tile(void);
#pragma aux read_ceiling_tile = "mov ax, word ptr [ebp + 0x10]" "mov word ptr [globalpicnum], ax" modify exact [eax];

extern void read_floor_tile(void);
#pragma aux read_floor_tile = "mov ax, word ptr [ebp + 0x18]" "mov word ptr [globalpicnum], ax" modify exact [eax];

extern void read_ceiling_palette(void);
#pragma aux read_ceiling_palette = "xor eax, eax" "mov al, byte ptr [ebp + 0x15]" modify exact [eax];

extern void read_floor_palette(void);
#pragma aux read_floor_palette = "xor eax, eax" "mov al, byte ptr [ebp + 0x1d]" modify exact [eax];

extern void save_plane_slope(void);
#pragma aux save_plane_slope = "mov dword ptr [esp + 0x1c], eax" modify exact [];

extern void use_ceiling_tile(void);
#pragma aux use_ceiling_tile = "db 0ebh, 50h" /* marker-rel8 +4,+5 */ aborts modify exact [];

void grouscan(void);
#pragma aux grouscan aborts;

void grouscan(void)
{
    /* Save the shared raster frame and choose ceiling or floor. */
    save_slope_scan_frame();
    in_ax(from_cx());
    in_ax(from_ax() << 2);
    in_ax(from_ax() + from_cx());
    read_sector_table();
    in_ax(from_ax() << 3);
    select_floor_plane();

    in_bx(camera_y);
    in_dx(camera_x);
    in_ax(from_cx());
    require_visible_ceiling();
    in_ax(*(short *)(from_bp() + 0xc));
    globalorientation = from_ax();
    read_ceiling_tile();
    in_ax(*(signed char *)(from_bp() + 0x14));
    globalshade = from_ax();
    read_ceiling_palette();
    globalpal = from_ax();
    in_ax(*(short *)(from_bp() + 0x12));
    save_plane_slope();
    in_ax(*(long *)(from_bp() + 4));
    use_ceiling_tile();
}

void grouscan_select_floor(void);
#pragma aux grouscan_select_floor aborts;

void grouscan_select_floor(void)
{
    in_bx(camera_y);
    in_dx(camera_x);
    in_ax(from_cx());
    require_visible_floor();
    in_ax(*(short *)(from_bp() + 0xe));
    globalorientation = from_ax();
    read_floor_tile();
    in_ax(*(signed char *)(from_bp() + 0x1c));
    globalshade = from_ax();
    read_floor_palette();
    globalpal = from_ax();
    in_ax(*(short *)(from_bp() + 0x1a));
    save_plane_slope();
    in_ax(*(long *)(from_bp() + 8));
}

extern void save_plane_height(void);
#pragma aux save_plane_height = "mov dword ptr [esp + 0x28], eax" modify exact [];

extern void check_tile_animation(void);
#pragma aux check_tile_animation = "test byte ptr [eax*4 + picanm], 0xc0" "db 74h, 0fh" /* marker-rel8 +1,+2 */ modify exact [eax edx];

extern void read_animation_offset(void);
#pragma aux read_animation_offset = "movsx edx, si" "call animateoffs" modify exact [eax ebx ecx edx];

void grouscan_select_tile(void);
#pragma aux grouscan_select_tile aborts;

void grouscan_select_tile(void)
{
    save_plane_height();
    in_ax(globalpicnum);
    check_tile_animation();
    read_animation_offset();
    globalpicnum += (short)from_ax();
}

extern void require_tile_dimensions(void);
#pragma aux require_tile_dimensions = "lea eax, [edx + edx]" "cmp word ptr [eax + tilesizx], 0" "jle near grouscan_restore_stack" \
    "cmp word ptr [eax + tilesizy], 0" "jle near grouscan_restore_stack" modify exact [eax];

extern void load_tile_if_uncached(void);
#pragma aux load_tile_if_uncached = "cmp dword ptr [edx*4 + waloff], 0" "db 75h, 07h" /* marker-rel8 0,+1 */ \
    "mov eax, edx" "call loadtile" modify exact [eax ebx ecx edx esi edi];

void grouscan_require_tile(void);
#pragma aux grouscan_require_tile aborts;

void grouscan_require_tile(void)
{
    in_dx(globalpicnum);
    require_tile_dimensions();
    load_tile_if_uncached();
}

extern void in_low_word(short value);
#pragma aux in_low_word = "" parm [ax] modify exact [];

/* Keep the original immediate-byte store encoding. */
extern void warm_slope_tile(void);
#pragma aux warm_slope_tile = "mov byte ptr [eax + walock], 199" modify exact [];

extern unsigned char from_dl(void);
#pragma aux from_dl = value [dl] modify exact [];

extern void in_dl(unsigned char value);
#pragma aux in_dl = "" parm [dl] modify exact [];

extern unsigned char from_bl(void);
#pragma aux from_bl = value [bl] modify exact [];

extern void in_bl(unsigned char value);
#pragma aux in_bl = "" parm [bl] modify exact [];

void grouscan_touch_tile(void);
#pragma aux grouscan_touch_tile aborts;

void grouscan_touch_tile(void)
{
    /* Warm unlocked tiles and set this tile's bit in the usage bitmap. */
    in_low_word(globalpicnum);
    in_ax((short)from_ax());
    in_bx(from_ax());
    if (walock[from_ax()] < 200)
        warm_slope_tile();
    in_ax((unsigned long)from_ax() >> 3);
    in_bx(from_bx() & 7);
    in_dl(gotpic[from_ax()]);
    in_bl(pow2char[from_bx()]);
    in_dl(from_dl() | from_bl());
    gotpic[from_ax()] = from_dl();
}
