/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern long view_stack_depth, window_left, window_right, restored_stereo_mode;
extern long saved_window_left[], saved_window_top[], saved_window_right[], saved_window_bottom[];
extern long saved_stereo_mode[], saved_chainstat[], saved_video_backend[], saved_frameplace[];
extern long saved_tile_width[], bytesperline, frameplace, ylookup[];
extern unsigned char startumost[], startdmost[], saved_startumost[], saved_startdmost[];
extern unsigned char chainstat, video_backend;

extern void setview(long left, long top, long right, long bottom);
#pragma aux setview parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void setvlinebpl(long stride);
#pragma aux setvlinebpl parm [eax] modify exact [eax];
extern void finish_restored_view(void);
#pragma aux finish_restored_view aborts modify exact [];

/* Preserve the registers expected by the shared graphics return. */
extern void begin_view_restore(void);
#pragma aux begin_view_restore = "push ebx" "push ecx" "push edx" "push esi" "push edi" "push ebp" modify exact [];
extern void require_saved_view(long depth);
#pragma aux require_saved_view = "test edx,edx" "jle finish_restored_view" parm [edx] modify exact [];
extern long saved_view_depth(void);
#pragma aux saved_view_depth = "lea ebx,[edx-1]" value [ebx] modify exact [ebx];
extern void restore_window_bounds(void);
#pragma aux restore_window_bounds = "mov eax,ebx" "mov ecx,[ebx*4+saved_window_bottom]" \
    "mov ebx,[ebx*4+saved_window_right]" "mov edx,[eax*4+saved_window_top]" "mov eax,[eax*4+saved_window_left]" \
    modify exact [eax ebx ecx edx];
extern long view_left_arg(void);
#pragma aux view_left_arg = value [eax] modify exact [];
extern long view_top_arg(void);
#pragma aux view_top_arg = value [edx] modify exact [];
extern long view_right_arg(void);
#pragma aux view_right_arg = value [ebx] modify exact [];
extern long view_bottom_arg(void);
#pragma aux view_bottom_arg = value [ecx] modify exact [];
/* Restore the saved clip bounds over the inclusive window X range. */
extern void prepare_upper_clip_copy(void);
#pragma aux prepare_upper_clip_copy = "mov eax,window_right" "sub eax,window_left" "add eax,eax" \
    "lea ecx,[eax+2]" "mov eax,window_left" "mov edi,offset startumost" "add eax,eax" \
    "mov esi,offset saved_startumost" "add edi,eax" "add esi,eax" modify exact [eax ecx esi edi];
extern void prepare_lower_clip_copy(void);
#pragma aux prepare_lower_clip_copy = "mov ecx,window_right" "mov esi,window_left" \
    "mov edi,offset startdmost" "sub ecx,esi" "lea eax,[esi+esi]" "add ecx,ecx" \
    "mov esi,offset saved_startdmost" "add ecx,2" "add edi,eax" "add esi,eax" modify exact [eax ecx esi edi];
extern void copy_clip_span(void);
#pragma aux copy_clip_span = "test cl,1" "je align_word" "movsb" "align_word:" \
    "shr ecx,2" "jae copy_dwords" "movsw" "copy_dwords:" "rep movsd" modify exact [ecx esi edi];
extern void restore_saved_modes(void);
#pragma aux restore_saved_modes = "mov eax,view_stack_depth" "mov edx,[eax*4+saved_stereo_mode]" \
    "mov restored_stereo_mode,edx" "mov dl,byte ptr [eax*4+saved_chainstat]" \
    "mov edi,view_stack_depth" "mov chainstat,dl" "mov dl,byte ptr [eax*4+saved_video_backend]" \
    "mov eax,[eax*4+saved_frameplace]" "mov video_backend,dl" "mov frameplace,eax" modify exact [eax edx edi];
extern long remaining_view_depth(void);
#pragma aux remaining_view_depth = value [edi] modify exact [];
extern void load_nested_widths(void);
#pragma aux load_nested_widths = "mov eax,edi" "shl eax,2" "mov edx,[eax+saved_tile_width-4]" \
    "mov ebp,[eax+saved_tile_width]" modify exact [eax edx];
extern long preceding_tile_width(void);
#pragma aux preceding_tile_width = value [edx] modify exact [];
extern long current_tile_width(void);
#pragma aux current_tile_width = value [ebp] modify exact [];
extern void row_bound_in_ecx(long rows);
#pragma aux row_bound_in_ecx = "" parm [ecx] modify exact [];
extern long row_bound(void);
#pragma aux row_bound = value [ecx] modify exact [];
extern void begin_restored_rows(long stride);
#pragma aux begin_restored_rows = "xor edx,edx" "xor eax,eax" parm [ebx] modify exact [edx eax];
extern long restored_row(void);
#pragma aux restored_row = value [eax] modify exact [];
extern long row_offset(void);
#pragma aux row_offset = value [edx] modify exact [];
extern void advance_row(void);
#pragma aux advance_row = "inc eax" "add edx,ebx" modify exact [eax edx];
#pragma aux setviewback modify exact [eax ebx ecx edx esi edi];

void setviewback(void)
{
    begin_view_restore();
    require_saved_view(view_stack_depth);
    view_stack_depth = saved_view_depth();
    restore_window_bounds();
    setview(view_left_arg(), view_top_arg(), view_right_arg(), view_bottom_arg());
    prepare_upper_clip_copy();
    copy_clip_span();
    prepare_lower_clip_copy();
    copy_clip_span();
    restore_saved_modes();

    /* A nested view keeps the row lookup large enough for both tiles. */
    if (!remaining_view_depth())
        row_bound_in_ecx(saved_tile_width[0]);
    else {
        load_nested_widths();
        if (preceding_tile_width() > current_tile_width())
            row_bound_in_ecx(preceding_tile_width());
        else
            row_bound_in_ecx(current_tile_width());
    }

    begin_restored_rows(bytesperline);
    goto check_row;
    do {
        ylookup[restored_row()] = row_offset();
        advance_row();
check_row:;
    } while (restored_row() <= row_bound());
    setvlinebpl(bytesperline);
    finish_restored_view();
}
