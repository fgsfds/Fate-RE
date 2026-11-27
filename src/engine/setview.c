/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */
extern unsigned char chainstat;
extern long xdimen, xdim, ydim;
extern long view_left_scaled, view_right_scaled, view_top_scaled, view_bottom_scaled;
extern long window_left, window_top, window_right, window_bottom;
extern long half_view_width, view_height, view_width_reciprocal, bytesperline, viewoffset;
extern short startumost[], startdmost[];

extern void rebuild_view_angle_table(long);
#pragma aux rebuild_view_angle_table modify exact [eax];
extern void setaspect(long);
#pragma aux setaspect modify exact [eax];

extern long divscale16(long, long);
#pragma aux divscale16 = "mov edx, eax" "sar edx, 16" "shl eax, 16" "idiv ebx" parm [eax] [ebx] value [eax] modify exact [eax edx];

/* The planar offset path uses EBP. Both exits restore the incoming value. */
extern void restore_view_frame(void);
#pragma aux restore_view_frame = "pop ebp" modify exact [];
extern long chain_offset(void);
#pragma aux chain_offset = "mov eax,[bytesperline]" "mov ebp,[window_top]" "shl eax,2" "imul eax,ebp" "mov edx,[window_left]" "add eax,edx" value [eax] modify exact [eax edx];

extern long enter_setview(long);
#pragma aux enter_setview = "push ebp" "mov esi, edx" parm [edx] value [esi] modify exact [esi];

/* Publish the derived dimensions using the original 2^32/width division.
 * Refresh the per-column angle table only when the inclusive width changes.
 */
extern void set_view_dimensions(long width_minus_one, long bottom, long top, long old_width);
#pragma aux set_view_dimensions = \
    "inc ebx" \
    "lea edx,[ecx+1]" \
    "mov [xdimen],ebx" \
    "mov eax,ebx" \
    "shl edx,12" \
    "sar eax,1" \
    "sub ecx,esi" \
    "mov [view_bottom_scaled],edx" \
    "mov [half_view_width],eax" \
    "mov edx,1" \
    "inc ecx" \
    "xor eax,eax" \
    "idiv ebx" \
    "mov edx,[xdimen]" \
    "mov [view_width_reciprocal],eax" \
    "mov [view_height],ecx" \
    "cmp edi,edx" \
    "je short exact_width" \
    "mov eax,edx" \
    "call rebuild_view_angle_table" \
    "exact_width:" \
    parm [ebx] [ecx] [esi] [edi] modify exact [eax ebx ecx edx];

extern long keep_left(long);
#pragma aux keep_left = parm [ebx] value [ebx] modify exact [];
extern long keep_right(long);
#pragma aux keep_right = parm [ecx] value [ecx] modify exact [];
extern short right_clip_top(void);
#pragma aux right_clip_top = "mov esi, 1" "xor edi, edi" parm [] value [si] modify exact [esi edi];
extern short right_clip_bottom(void);
#pragma aux right_clip_bottom = parm [] value [di] modify exact [];

void setview(long x1, long y1, long x2, long y2)
{
    long i, previous_width, right, left;

    y1 = enter_setview(y1);
    previous_width = xdimen;
    window_left = x1;
    view_left_scaled = x1 << 12;
    window_top = y1;
    window_right = x2;
    view_top_scaled = y1 << 12;
    window_bottom = y2;
    view_right_scaled = (x2 + 1) << 12;
    set_view_dimensions(x2 - x1, y2, y1, previous_width);
    setaspect(divscale16(ydim * 320, xdim * 200));

    /* Close columns outside the viewport and apply its vertical clip inside. */
    for (i = 0; i < (left = keep_left(window_left)); ) {
        ++i;
        startumost[i - 1] = 1;
        startdmost[i - 1] = 0;
    }
    right = keep_right(window_right);
    for (i = left; i <= right; ) {
        startumost[i] = (short)window_top;
        ++i;
        startdmost[i - 1] = (short)window_bottom + 1;
    }
    for (i = right + 1; i < xdim; ) {
        startumost[i++] = right_clip_top();
        startdmost[i - 1] = right_clip_bottom();
    }
    if (chainstat) {
        viewoffset = chain_offset();
        restore_view_frame();
        return;
    }
    viewoffset = window_top * bytesperline + window_left;
    restore_view_frame();
}

extern void seed_aspect_division(long width, int upper_word);
#pragma aux seed_aspect_division = "" parm [ecx] [edx] modify exact [];
extern void preserve_previous_range(long old);
#pragma aux preserve_previous_range = "" parm [esi] modify exact [];
extern long viewingrange, viewingrange_reciprocal;
extern long viewingrange_scaled, viewingrange_reciprocal_scaled;
extern long horizycent;
extern long *horizon_reciprocals, *horizon_aspect;
/* Both exits use the renderer's existing saved-register cleanup. */
extern void finish_engine_aspect(void);
#pragma aux finish_engine_aspect "shared_graphics_epilogue_" aborts modify exact [eax];

extern long aspect_old_range(void);
#pragma aux aspect_old_range = value [esi] modify exact [];
extern long aspect_range_in_edx(long reciprocal);
#pragma aux aspect_range_in_edx = "" parm [edx] value [edx] modify exact [];

extern void prepare_screen_range_denominator(long reciprocal);
#pragma aux prepare_screen_range_denominator = "mov edi,edx" "shl edi,2" "add edi,edx" "shl edi,6" parm [edx] modify exact [edi];
extern long *aspect_table_in_ecx(long *table);
#pragma aux aspect_table_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern long aspect_value_in_ebx(long value);
#pragma aux aspect_value_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern long aspect_value_in_eax(long value);
#pragma aux aspect_value_in_eax = "" parm [eax] value [eax] modify exact [];
extern long aspect_row_in_ecx(long value);
#pragma aux aspect_row_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern long aspect_range_in_use(void);
#pragma aux aspect_range_in_use = value [edx] modify exact [];
extern long three_times_ydim(long height);
#pragma aux three_times_ydim = "mov eax,ebx" "shl eax,2" "sub eax,ebx" parm [ebx] value [eax] modify exact [eax];
extern long first_horizon_reciprocal(void);
#pragma aux first_horizon_reciprocal = "mov eax,20000h" "mov ebx,edi" "mov edx,eax" "sar edx,4" "shl eax,28" "idiv ebx" value [eax] modify exact [eax ebx edx];
extern long horizon_row_reciprocal(long row, long offset);
#pragma aux horizon_row_reciprocal = "mov eax,1" "mov esi,ecx" "mov edx,eax" "sar edx,4" "shl eax,28" "idiv ebx" parm [ecx] [ebx] value [eax] modify exact [eax edx esi];
extern long horizon_row_in_esi(void);
#pragma aux horizon_row_in_esi = value [esi] modify exact [];
extern long abs_aspect_numerator(long reciprocal);
#pragma aux abs_aspect_numerator = "mov ebx,edi" "test eax,eax" "jns abs_aspect_done" "neg eax" "abs_aspect_done:" parm [eax] value [eax] modify exact [eax ebx];
extern long aspect_divscale16(long value);
#pragma aux aspect_divscale16 = "mov edx,eax" "sar edx,16" "shl eax,16" "idiv ebx" parm [eax] value [eax] modify exact [eax edx];

extern long aspect_current_row(void);
#pragma aux aspect_current_row = value [ecx] modify exact [];
extern void aspect_next_row(void);
#pragma aux aspect_next_row = "dec ecx" modify exact [ecx];
extern void store_horizon_value(long *table, long row, long value);
#pragma aux store_horizon_value = "mov dword ptr [ebx+esi*4],eax" parm [ebx] [esi] [eax] modify exact [];
extern long load_horizon_value(long *table, long row);
#pragma aux load_horizon_value = "mov eax,dword ptr [eax+esi*4]" parm [eax] [esi] value [eax] modify exact [eax];

extern long divide_reciprocal(void);
#pragma aux divide_reciprocal = "xor eax,eax" "idiv ebx" value [eax] modify exact [eax edx];
extern long factor_in_ebx(long factor);
#pragma aux factor_in_ebx = "" parm [ebx] value [ebx] modify exact [];
extern long width_in_ecx(long width);
#pragma aux width_in_ecx = "" parm [ecx] value [ecx] modify exact [];
extern long scale_aspect_ratio(long width, long factor);
#pragma aux scale_aspect_ratio = "imul ebx" "idiv ecx" parm [eax] [ebx] value [eax] modify exact [eax edx];
extern long scale_aspect_inverse(long width);
#pragma aux scale_aspect_inverse = "imul ebx" "idiv ecx" parm [eax] value [eax] modify exact [eax edx];
void setaspect(long range)
{
    long reciprocal, scaled, inverse, center, value, factor;
    long *table;

    /* The initial quotient uses a 64-bit dividend of 2^32. */
    seed_aspect_division(320, 1);
    preserve_previous_range(viewingrange_reciprocal);
    factor_in_ebx(range);
    viewingrange = range;
    reciprocal = divide_reciprocal();
    factor = factor_in_ebx(viewingrange);
    viewingrange_reciprocal = reciprocal;
    scaled = scale_aspect_ratio(xdimen, factor);
    width_in_ecx(xdimen);
    factor_in_ebx(viewingrange_reciprocal);
    viewingrange_scaled = scaled;
    inverse = scale_aspect_inverse(320);
    reciprocal = aspect_range_in_edx(viewingrange_reciprocal);
    viewingrange_reciprocal_scaled = inverse;
    if (aspect_old_range() == reciprocal)
        finish_engine_aspect();

    /* Rebuild horizon tables when the viewing range reciprocal changes. */
    prepare_screen_range_denominator(aspect_range_in_use());
    value = first_horizon_reciprocal();
    table = aspect_table_in_ecx(horizon_aspect);
    value = aspect_value_in_ebx(value);
    table[aspect_value_in_eax(horizycent) - 1] = value;
    aspect_row_in_ecx(three_times_ydim(ydim) - 1);
    goto check_row;
    do {
        center = aspect_value_in_ebx(horizycent - 1);
        if (aspect_current_row() == center)
            goto next_row;
        value = horizon_row_reciprocal(aspect_current_row(), aspect_current_row() - center);
        store_horizon_value(horizon_reciprocals, horizon_row_in_esi(), value);
        value = abs_aspect_numerator(load_horizon_value(horizon_reciprocals, horizon_row_in_esi()));
        value = aspect_divscale16(value);
        store_horizon_value(horizon_aspect, horizon_row_in_esi(), value);
    next_row:
        aspect_next_row();
    check_row:
        ;
    } while (aspect_current_row() >= 0);
    finish_engine_aspect();
}
