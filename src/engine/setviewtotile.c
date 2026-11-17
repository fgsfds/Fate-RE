/* Build Engine & Tools copyright (c) 1993-1997 Ken Silverman. See BUILDLIC.TXT. */

extern short tilesizx[], tilesizy[];
extern long view_stack_depth, window_left, window_top, window_right, window_bottom;
extern long saved_window_left[], saved_window_top[], saved_window_right[], saved_window_bottom[];
extern long restored_stereo_mode, saved_stereo_mode[], saved_chainstat[], saved_video_backend[];
extern long saved_tile_width[], saved_tile_height[], frameplace, saved_frameplace[], ylookup[], waloff[];
extern unsigned char startumost[], startdmost[], saved_startumost[], saved_startdmost[];
extern unsigned char chainstat, video_backend;

extern void setview(long left, long top, long right, long bottom);
#pragma aux setview parm [eax] [edx] [ebx] [ecx] modify exact [eax ebx ecx edx];
extern void setaspect(long aspect);
#pragma aux setaspect parm [eax] modify exact [eax ebx ecx edx];
extern void setvlinebpl(long stride);
#pragma aux setvlinebpl parm [eax] modify exact [eax];
extern void finish_tile_view(void);
#pragma aux finish_tile_view aborts modify exact [];

/* Keep the register frame and stacked dimensions consumed by the shared return. */
extern void begin_tile_view(short tile, long width, long height);
#pragma aux begin_tile_view = "push ecx" "push esi" "push edi" "push ebp" "push edx" "push ebx" \
    "movsx edx,ax" parm [ax] [edx] [ebx] modify exact [edx];
extern long view_tile_index(void);
#pragma aux view_tile_index = value [edx] modify exact [];
extern long view_tile_width(void);
#pragma aux view_tile_width = "mov ebx,[esp+4]" value [ebx] modify exact [ebx];
extern long view_tile_height(void);
#pragma aux view_tile_height = "mov ebx,[esp]" value [ebx] modify exact [ebx];
extern void preserve_tile_stack_index(long depth);
#pragma aux preserve_tile_stack_index = "" parm [eax] modify exact [];
extern long current_tile_stack_index(void);
#pragma aux current_tile_stack_index = value [eax] modify exact [];

extern void save_tile_modes(void);
#pragma aux save_tile_modes = "mov ebx,restored_stereo_mode" "mov [eax*4+saved_stereo_mode],ebx" \
    "xor ebx,ebx" "mov restored_stereo_mode,ebx" "mov bl,chainstat" "mov [eax*4+saved_chainstat],ebx" \
    "xor bl,bl" "mov chainstat,bl" modify exact [ebx];
extern void redirect_tile_framebuffer(void);
#pragma aux redirect_tile_framebuffer = "xor ebx,ebx" "mov bl,video_backend" \
    "mov [eax*4+saved_video_backend],ebx" "mov bh,2" "mov edx,[edx*4+waloff]" "mov video_backend,bh" \
    "mov ebx,frameplace" "mov frameplace,edx" modify exact [ebx edx];
extern void save_window_bounds(void);
#pragma aux save_window_bounds = "mov edx,window_left" "mov edi,offset saved_startumost" \
    "mov [eax*4+saved_window_left],edx" "mov edx,window_top" "mov ecx,window_left" \
    "mov [eax*4+saved_window_top],edx" modify exact [ecx edx edi];
extern void save_end_of_window(void);
#pragma aux save_end_of_window = "mov edx,window_right" "mov esi,window_left" \
    "mov [eax*4+saved_window_right],edx" "mov edx,window_bottom" "mov [eax*4+saved_frameplace],ebx" \
    "mov [eax*4+saved_window_bottom],edx" modify exact [ecx edx esi edi];
extern void prepare_upper_span(void);
#pragma aux prepare_upper_span = "mov eax,window_right" "add esi,esi" "sub eax,ecx" \
    "add edi,esi" "add eax,eax" "add esi,offset startumost" "lea ecx,[eax+2]" "mov ebx,[esp]" \
    modify exact [eax ebx ecx edx esi edi];
extern void prepare_lower_span(void);
#pragma aux prepare_lower_span = "mov eax,window_right" "mov esi,window_left" "dec ebx" "sub eax,esi" \
    "mov edi,offset saved_startdmost" "add eax,eax" "add esi,esi" "lea ecx,[eax+2]" \
    "add edi,esi" "add esi,offset startdmost" "xor edx,edx" modify exact [eax ebx ecx edx esi edi];
extern void copy_clip_span(void);
#pragma aux copy_clip_span = "test cl,1" "je align_word" "movsb" "align_word:" \
    "shr ecx,2" "jae copy_dwords" "movsw" "copy_dwords:" "rep movsd" modify exact [ecx esi edi];

/* Tile rendering uses transposed screen bounds for column-major pixels. */
extern void prepare_tile_bounds(void);
#pragma aux prepare_tile_bounds = "mov ecx,[esp+4]" "xor eax,eax" "dec ecx" "mov ebp,[esp]" \
    modify exact [eax ecx];
extern long tile_left_arg(void);
#pragma aux tile_left_arg = value [eax] modify exact [];
extern long tile_top_arg(void);
#pragma aux tile_top_arg = value [edx] modify exact [];
extern long tile_right_arg(void);
#pragma aux tile_right_arg = value [ebx] modify exact [];
extern long tile_bottom_arg(void);
#pragma aux tile_bottom_arg = value [ecx] modify exact [];
extern long prepare_tile_aspect(long aspect);
#pragma aux prepare_tile_aspect = "mov edi,[esp+4]" parm [eax] value [eax] modify exact [edi];
extern long tile_stride(void);
#pragma aux tile_stride = "mov eax,[esp]" value [eax] modify exact [eax];
extern void begin_tile_row_offsets(void);
#pragma aux begin_tile_row_offsets = "xor edx,edx" "xor eax,eax" modify exact [eax edx];
extern long tile_row(void);
#pragma aux tile_row = value [eax] modify exact [];
extern long tile_last_row(void);
#pragma aux tile_last_row = value [edi] modify exact [];
extern long tile_row_offset(void);
#pragma aux tile_row_offset = value [edx] modify exact [];
extern void next_tile_row(void);
#pragma aux next_tile_row = "inc eax" "add edx,ebp" modify exact [eax edx];
#pragma aux setviewtotile modify exact [eax ebx ecx edx esi edi];

void setviewtotile(short tile, long width, long height)
{
    long dimension;

    begin_tile_view(tile, width, height);
    dimension = view_tile_width();
    tilesizx[view_tile_index()] = (short)dimension;
    dimension = view_tile_height();
    preserve_tile_stack_index(view_stack_depth);
    tilesizy[view_tile_index()] = (short)dimension;
    saved_tile_width[current_tile_stack_index()] = view_tile_width();
    saved_tile_height[current_tile_stack_index()] = view_tile_height();

    /* Save the old framebuffer and window before redirecting the renderer. */
    save_tile_modes();
    redirect_tile_framebuffer();
    save_window_bounds();
    save_end_of_window();
    prepare_upper_span();
    copy_clip_span();
    prepare_lower_span();
    copy_clip_span();
    prepare_tile_bounds();
    setview(tile_left_arg(), tile_top_arg(), tile_right_arg(), tile_bottom_arg());
    setaspect(prepare_tile_aspect(0x10000L));

    begin_tile_row_offsets();
    goto check_row;
    do {
        ylookup[tile_row()] = tile_row_offset();
        next_tile_row();
check_row:;
    } while (tile_row() <= tile_last_row());
    setvlinebpl(tile_stride());
    ++view_stack_depth;
    finish_tile_view();
}
