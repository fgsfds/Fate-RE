/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern long rx1[], rx2[], view_x1[], view_x2[], xb1[], xb2[], lwall[], swall[];
extern long xdimen, half_view_width, viewingrange_reciprocal_scaled;

/* The shared frame keeps several column indexes as byte offsets. */
#define COLUMN_AT_BYTE_OFFSET(columns, offset) (*(long *)((char *)(columns) + (offset)))

/* Follow the original internal entry points within the same stack frame.
 * The renderer's shared return removes this frame and restores registers.
 */
extern void prepwall_more_columns(void);
extern void prepwall_last_pair(void);
extern void prepwall_last_column(void);
extern void wallfront_return(void);
#pragma aux wallfront_return aborts modify exact [];

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

extern void in_cx(long value);
#pragma aux in_cx = "" parm [ecx] modify exact [];

extern long from_dx(void);
#pragma aux from_dx = value [edx] modify exact [];

extern void in_dx(long value);
#pragma aux in_dx = "" parm [edx] modify exact [];

extern long from_di(void);
#pragma aux from_di = value [edi] modify exact [];

extern void in_di(long value);
#pragma aux in_di = "" parm [edi] modify exact [];

extern long from_si(void);
#pragma aux from_si = value [esi] modify exact [];

extern void in_si(long value);
#pragma aux in_si = "" parm [esi] modify exact [];

extern long from_bp(void);
#pragma aux from_bp = value [ebp] modify exact [];

extern void save_scan_frame(void);
#pragma aux save_scan_frame = "push ebx" "push ecx" "push esi" "push edi" "push ebp" "sub esp, 0x20" "push eax" "push edx" \
    "xor eax, eax" "mov al, byte ptr [edx + 0x16]" "mov ecx, dword ptr [esp + 4]"  modify exact [eax ecx];

extern void read_scan_endpoints(void);
#pragma aux read_scan_endpoints = "mov dword ptr [esp + 0x1c], eax" \
    "mov eax, dword ptr [ecx*4 + view_x2]" "mov ebp, dword ptr [ecx*4 + view_x2]"  modify exact [eax];

extern void save_step_numerator(void);
#pragma aux save_step_numerator = "mov dword ptr [esp + 0x14], eax" "mov ebx, eax"  modify exact [ebx];

extern void save_projection_step(void);
#pragma aux save_projection_step = "mov dword ptr [esp + 0x14], ebx" "sar eax, 8" "mov ebx, dword ptr [xdimen]" \
    "mov dword ptr [esp + 0x18], eax"  modify exact [eax ebx];

extern void scale_start_numerator(void);
#pragma aux scale_start_numerator = "imul ebx" "shrd eax, edx, 5" "mov ebp, eax" "mov ebx, esi" "mov eax, dword ptr [esp + 0x14]" \
    "imul ebx" "shrd eax, edx, 2" "mov edx, dword ptr [ecx*4 + rx2]" "add ebp, eax"  modify exact [eax ebx edx];

extern void scale_start_denominator(void);
#pragma aux scale_start_denominator = "mov dword ptr [esp + 0x24], ebp" "imul ebx" "shrd eax, edx, 0xb" "mov ebp, eax" \
    "mov ebx, esi" "mov eax, dword ptr [esp + 0x18]" "imul ebx" "shrd eax, edx, 2" \
    "mov ebx, dword ptr [viewingrange_reciprocal_scaled]" "lea esi, [eax + ebp]" \
    "mov eax, dword ptr [ecx*4 + view_x2]" "imul ebx" "shrd eax, edx, 0x13" \
    "mov dword ptr [esp + 8], eax" "mov dword ptr [esp + 0x10], eax"  modify exact [eax ebx edx esi];

extern void load_view_x2_for_scale(void);
#pragma aux load_view_x2_for_scale = "mov ebp, dword ptr [ecx*4 + view_x2]"  modify exact [];

extern void begin_projection_samples(void);
#pragma aux begin_projection_samples = "imul ebx" "shrd eax, edx, 0x10" "mov ebp, eax" "mov dword ptr [esp + 0xc], eax" \
    "mov ecx, dword ptr [ecx*4 + xb1]" "test esi, esi" "db 74h, 3ah" /* marker-rel8 +2,+3 */  modify exact [eax ecx edx];

extern void project_first_column(void);
#pragma aux project_first_column = "mov eax, dword ptr [esp + 0x24]" "mov ebx, esi" "mov edx, eax" "sar edx, 0x14" \
    "shl eax, 0xc" "idiv ebx" "mov ebx, ebp" "mov edi, eax" "imul ebx" "shrd eax, edx, 0x15" \
    "mov edx, dword ptr [esp + 8]"  modify exact [eax ebx edx edi];

extern void load_horizontal_repeat(void);
#pragma aux load_horizontal_repeat = "mov edx, dword ptr [esp + 0x1c]"  modify exact [edx];

void prepwall(void);
#pragma aux prepwall aborts;

void prepwall(void)
{
    /* Set up the fixed-point texture-coordinate numerator, denominator and scale. */
    save_scan_frame();
    in_ax(from_ax() << 3);
    in_si(xb1[from_cx()]);
    read_scan_endpoints();
    in_ax(from_ax() >> 2);
    in_dx(half_view_width);
    save_step_numerator();
    in_ax(view_x1[from_cx()]);
    in_bx(-from_bx());
    in_ax(from_ax() - from_bp());
    save_projection_step();
    in_ax(rx1[from_cx()]);
    in_si(from_si() - from_dx());
    scale_start_numerator();
    in_ax(rx1[from_cx()]);
    in_bx(xdimen);
    in_ax(from_ax() - from_dx());
    scale_start_denominator();
    load_view_x2_for_scale();
    in_ax(view_x1[from_cx()]);
    in_bx(viewingrange_reciprocal_scaled);
    in_ax(from_ax() - from_bp());
    begin_projection_samples();
    project_first_column();
    in_dx(from_dx() + from_ax());
    swall[from_cx()] = from_dx();
    load_horizontal_repeat();
    in_di(from_di() * from_dx());
    in_dx(from_di() >> 18);
    lwall[from_cx()] = from_dx();
}

extern void check_for_four_columns(void);
#pragma aux check_for_four_columns = "mov eax, dword ptr [esp + 4]" "lea edx, [ecx + 4]" "shl eax, 2" "mov ebp, ecx" \
    "mov ebx, dword ptr [eax + xb2]" "shl ebp, 2" "cmp edx, ebx" "jg prepwall_last_pair" \
    "mov eax, dword ptr [esp + 0x14]" "mov edx, dword ptr [esp + 0x24]"  modify exact [eax ebx edx];

extern void read_four_column_step(void);
#pragma aux read_four_column_step = "mov ebx, dword ptr [esp + 0x18]" "mov dword ptr [esp + 0x24], edx"  modify exact [ebx];

extern void project_fourth_column(void);
#pragma aux project_fourth_column = "add esi, ebx" "db 74h, 3ah" /* marker-rel8 +1 */ "mov ebx, esi" "mov eax, edx" "mov dword ptr [esp + 0x20], edi" \
    "mov edx, eax" "sar edx, 0x14" "shl eax, 0xc" "idiv ebx" "mov ebx, dword ptr [esp + 0xc]" \
    "mov edi, eax" "imul ebx" "shrd eax, edx, 0x15" "imul edi, dword ptr [esp + 0x1c]" \
    "mov edx, dword ptr [esp + 0x10]"  modify exact [eax ebx edx esi edi];

extern void get_previous_texture4(void);
#pragma aux get_previous_texture4 = "mov eax, dword ptr [esp + 0x20]" modify exact [eax];

extern void initialize_texture_midpoint(void);
#pragma aux initialize_texture_midpoint = "mov ebp, eax"  modify exact [];

extern void read_texture_midpoint(void);
#pragma aux read_texture_midpoint = "sar ebp, 1"  modify exact [];

extern void average_texture_right(void);
#pragma aux average_texture_right = "add ebp, edi"  modify exact [];

extern void compute_right_texture(void);
#pragma aux compute_right_texture = "sar ebp, 0x13"  modify exact [];

extern void read_center_scale(void);
#pragma aux read_center_scale = "mov ebp, dword ptr [ecx*4 + swall]" "add ebp, edx" "sar ebp, 1" modify exact [];

extern void load_right_midpoint_scale(void);
#pragma aux load_right_midpoint_scale = "mov ebp, dword ptr [ecx*4 + swall+16]" "add ebp, dword ptr [ecx*4 + swall+8]" "add ecx, 4"  modify exact [ecx];

extern void store_right_midpoint_scale(void);
#pragma aux store_right_midpoint_scale = "sar ebp, 1" "mov dword ptr [ecx*4 + swall-4], ebp" "jmp prepwall_more_columns" aborts modify exact [];

void prepwall_more_columns(void);
#pragma aux prepwall_more_columns aborts;

void prepwall_more_columns(void)
{
    /* Project every fourth column and interpolate the three intervening columns. */
    check_for_four_columns();
    in_dx(from_dx() + from_ax());
    read_four_column_step();
    project_fourth_column();
    in_ax(from_ax() + from_dx());
    COLUMN_AT_BYTE_OFFSET(swall, from_bp() + 16) = from_ax();
    in_ax(from_di());
    in_ax(from_ax() >> 18);
    COLUMN_AT_BYTE_OFFSET(lwall, from_bp() + 16) = from_ax();
    get_previous_texture4();
    in_ax(from_ax() + from_di());
    in_dx(from_ax());
    initialize_texture_midpoint();
    in_dx(from_dx() >> 19);
    read_texture_midpoint();
    lwall[from_cx() + 2] = from_dx();
    load_previous_texture();
    in_dx(from_dx() + from_bp());
    average_texture_right();
    in_dx(from_dx() >> 19);
    compute_right_texture();
    lwall[from_cx() + 1] = from_dx();
    in_dx(swall[from_cx() + 4]);
    lwall[from_cx() + 3] = from_bp();
    read_center_scale();
    in_dx(swall[from_cx()]);
    in_dx(from_dx() + from_bp());
    swall[from_cx() + 2] = from_bp();
    swall[from_cx() + 1] = from_dx() >> 1;
    load_right_midpoint_scale();
    store_right_midpoint_scale();
}

extern void check_for_two_columns(void);
#pragma aux check_for_two_columns = "lea edx, [ecx + 2]" "cmp edx, ebx" "jg prepwall_last_column" \
    "mov eax, dword ptr [esp + 0x14]" "mov edx, dword ptr [esp + 0x24]"  modify exact [eax edx];

extern void read_two_column_step(void);
#pragma aux read_two_column_step = "mov eax, dword ptr [esp + 0x18]"  modify exact [eax];

extern void project_second_column(void);
#pragma aux project_second_column = "mov dword ptr [esp + 0x24], edx" "add esi, eax" "db 74h, 3ch" /* marker-rel8 +2 */ "mov ebx, esi" "mov eax, edx" \
    "mov dword ptr [esp + 0x20], edi" "mov edx, eax" "sar edx, 0x14" "shl eax, 0xc" "idiv ebx" \
    "mov ebx, dword ptr [esp + 0xc]" "mov edi, eax" "imul ebx" "shrd eax, edx, 0x15" \
    "mov ebx, dword ptr [esp + 0x10]"  modify exact [eax ebx edx edi esi];

extern void get_projected_texture2(void);
#pragma aux get_projected_texture2 = "mov eax, dword ptr [esp + 0x1c]" modify exact [eax];

extern void load_previous_texture(void);
#pragma aux load_previous_texture = "mov edx, dword ptr [esp + 0x20]" modify exact [edx];

extern void advance_two_columns(void);
#pragma aux advance_two_columns = "add ecx, 2" modify exact [ecx];

void prepwall_last_pair(void);
#pragma aux prepwall_last_pair aborts;

void prepwall_last_pair(void)
{
    /* Use the same interpolation for a final group of two columns. */
    check_for_two_columns();
    in_ax(from_ax() >> 1);
    in_dx(from_dx() + from_ax());
    read_two_column_step();
    in_ax(from_ax() >> 1);
    project_second_column();
    in_ax(from_ax() + from_bx());
    COLUMN_AT_BYTE_OFFSET(swall, from_bp() + 8) = from_ax();
    get_projected_texture2();
    in_di(from_di() * from_ax());
    in_ax(from_di() >> 18);
    COLUMN_AT_BYTE_OFFSET(lwall, from_bp() + 8) = from_ax();
    load_previous_texture();
    in_bx(swall[from_cx() + 2]);
    in_di(from_di() + from_dx());
    in_dx(swall[from_cx()]);
    advance_two_columns();
    in_dx(from_dx() + from_bx());
    in_di(from_di() >> 19);
    in_dx(from_dx() >> 1);
    lwall[from_cx() - 1] = from_di();
    swall[from_cx() - 1] = from_dx();
}

extern void read_step_denominator(void);
#pragma aux read_step_denominator = "mov eax, dword ptr [esp + 0x18]" modify exact [eax];

extern void check_last_denominator(void);
#pragma aux check_last_denominator = "add esi, eax" "db 74h, 43h" /* marker-rel8 +3 */ "mov eax, dword ptr [esp + 0x14]" \
    "mov ebp, dword ptr [esp + 0x24]"  modify exact [eax esi];

extern void project_last_column(void);
#pragma aux project_last_column = "mov edx, eax" "sar edx, 0x14" "shl eax, 0xc" "idiv ebx" "mov ebx, dword ptr [esp + 0xc]" \
    "mov esi, eax" "imul ebx" "shrd eax, edx, 0x15" "add eax, dword ptr [esp + 0x10]" \
    "mov ebx, dword ptr [esp + 0x1c]"  modify exact [eax ebx edx esi];

extern void scale_last_texture(void);
#pragma aux scale_last_texture = "mov eax, esi" "imul ebx" "shrd eax, edx, 0x12"  modify exact [eax edx];

extern void read_scan(void);
#pragma aux read_scan = "mov eax, dword ptr [esp + 4]" modify exact [eax];

extern void read_repeat(void);
#pragma aux read_repeat = "mov esi, dword ptr [esp + 0x1c]" modify exact [esi];

extern void check_horizontal_flip(void);
#pragma aux check_horizontal_flip = "mov eax, dword ptr [esp]" "mov ax, word ptr [eax + 0xe]" "xor ah, ah" "and al, 8" "cwde" \
    "test eax, eax" "je near wallfront_return" "mov ecx, dword ptr [esp + 4]" \
    "mov ebp, dword ptr [esp + 0x1c]" "mov eax, dword ptr [esp + 4]" "dec ebp" \
    "mov ecx, dword ptr [ecx*4 + xb1]" "mov dword ptr [esp + 0x1c], ebp" "db 0ebh, 15h" /* marker-rel8 +2 */  modify exact [eax ecx];

extern void read_flipped_repeat(void);
#pragma aux read_flipped_repeat = "mov edx, dword ptr [esp + 0x1c]" modify exact [edx];

extern void check_flipped_columns(void);
#pragma aux check_flipped_columns = "cmp ecx, dword ptr [eax*4 + xb2]" "db 7eh, 0e2h" /* marker-rel8 -1 */ "jmp near wallfront_return" aborts modify exact [];

void prepwall_last_column(void);
#pragma aux prepwall_last_column aborts;

void prepwall_last_column(void)
{
    /* Project a final column, clamp the texture endpoints and apply horizontal flip. */
    read_scan();
    in_dx(from_cx() + 1);
    if (from_dx() <= xb2[from_ax()]) {
        read_step_denominator();
        in_ax(from_ax() >> 2);
        check_last_denominator();
        in_ax(from_ax() >> 2);
        in_bx(from_si());
        in_ax(from_ax() + from_bp());
        project_last_column();
        swall[from_cx() + 1] = from_ax();
        scale_last_texture();
        lwall[from_cx() + 1] = from_ax();
    }
    read_scan();
    in_ax(xb1[from_ax()] << 2);
    if (COLUMN_AT_BYTE_OFFSET(lwall, from_ax()) < 0) {
        in_cx(0);
        COLUMN_AT_BYTE_OFFSET(lwall, from_ax()) = from_cx();
    }
    read_scan();
    in_ax(xb2[from_ax()] << 2);
    read_repeat();
    if (COLUMN_AT_BYTE_OFFSET(lwall, from_ax()) >= from_si() && from_si() != 0) {
        in_dx(from_si() - 1);
        COLUMN_AT_BYTE_OFFSET(lwall, from_ax()) = from_dx();
    }
    check_horizontal_flip();
    read_flipped_repeat();
    in_si(lwall[from_cx()]);
    in_cx(from_cx() + 1);
    in_dx(from_dx() - from_si());
    lwall[from_cx() - 1] = from_dx();
    check_flipped_columns();
}
