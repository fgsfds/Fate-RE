extern int save_palette_upload_inputs(const unsigned long *colors, int count);
#pragma aux save_palette_upload_inputs = "mov ecx,eax" "mov esi,edx" "movsx eax,dx" parm [eax] [edx] value [eax] modify exact [eax ecx esi];
extern short saved_palette_upload_count(void);
#pragma aux saved_palette_upload_count = value [si] modify exact [];
extern unsigned long next_palette_blue(void);
#pragma aux next_palette_blue = "mov edx,[ecx]" "mov eax,edx" "and eax,0ff0000h" "shr eax,10h" value [eax] modify exact [eax edx];
extern unsigned char next_palette_red(void);
#pragma aux next_palette_red = value [dl] modify exact [];
extern unsigned long next_palette_green(void);
#pragma aux next_palette_green = "mov ebx,edx" "xor bl,dl" "movzx ebx,bx" "sar ebx,8" "add ecx,4" value [ebx] modify exact [ebx ecx];
extern short palette_upload_first_index(void);
#pragma aux palette_upload_first_index = value [di] modify exact [];
#pragma pack(push,1)
struct graphics_dos_buffer {
    short segment;
    unsigned char __far *pixels;
};
#pragma pack(pop)
extern int allocate_graphics_dos_buffer(int bytes, struct graphics_dos_buffer *buffer);
#pragma aux allocate_graphics_dos_buffer modify exact [eax edx];
extern void free_graphics_dos_buffer(const struct graphics_dos_buffer *buffer);
#pragma aux free_graphics_dos_buffer modify exact [eax edx];
extern int call_graphics_real_mode_interrupt(int interrupt_number, short ax, short bx,
                                             short cx, short dx, int es, short di);
#pragma aux call_graphics_real_mode_interrupt modify exact [eax edx ebx ecx];

extern unsigned long upload_buffer_offset(unsigned char __far *buffer);
#pragma aux upload_buffer_offset = "xor edi,edi" parm [fs eax] value [eax] modify exact [fs edi];
/* The verified Watcom palette frame keeps its buffer base at EBP-4. */
extern unsigned long color_destination(unsigned long offset);
#pragma aux color_destination = "push fs" "pop es" "add eax,dword ptr [ebp-4]" parm [eax] value [eax] modify exact [es];

extern short palette_upload_index_in_di(short index);
#pragma aux palette_upload_index_in_di = "" parm [di] value [di] modify exact [];
extern int palette_upload_success(int success);
#pragma aux palette_upload_success = "" parm [eax] value [eax] modify exact [];
extern void store_palette_blue(unsigned long color, unsigned char blue);
#pragma aux store_palette_blue = "mov byte ptr es:[eax+2],bl" parm [eax] [bl] modify exact [];
extern void store_palette_red(unsigned long color, unsigned char red);
#pragma aux store_palette_red = "mov byte ptr es:[eax],dl" parm [eax] [dl] modify exact [];
extern void store_palette_green(unsigned long color, unsigned char green);
#pragma aux store_palette_green = "mov byte ptr es:[eax+1],dh" parm [eax] [dh] modify exact [];

int upload_bios_palette(const unsigned long *colors, int count)
{
    struct graphics_dos_buffer buffer;
    volatile struct {
        unsigned long component;
        unsigned long base;
    } palette_frame;
    short i;
    unsigned long destination;
    int n;
    int allocated;

    n = save_palette_upload_inputs(colors, count);
    allocated = allocate_graphics_dos_buffer(n * 3, &buffer);
    if (!(short)allocated)
        return allocated;

    palette_frame.base = upload_buffer_offset(buffer.pixels);
    for (i = palette_upload_first_index(); i < saved_palette_upload_count(); i = palette_upload_index_in_di(i + 1)) {
        palette_frame.component = next_palette_blue();
        destination = color_destination(i * 3);
        store_palette_blue(destination, palette_frame.component);
        palette_frame.component = next_palette_green();
        store_palette_red(destination, next_palette_red());
        store_palette_green(destination, palette_frame.component);
    }
    call_graphics_real_mode_interrupt(0x10, 0x1012, 0, saved_palette_upload_count(), 0, buffer.segment, 0);
    free_graphics_dos_buffer(&buffer);
    return palette_upload_success(1);
}

extern unsigned char dos_extender_type;

#pragma pack(push,1)
struct dpmi_registers {
    unsigned long edi, esi, ebp, reserved, ebx, edx, ecx, eax;
    unsigned short flags, es, ds, fs, gs, ip, cs, sp, ss;
};
struct dos_interrupt_registers {
    short interrupt_number, reserved1, es, ds, reserved2;
    int eax, edx;
};
#pragma pack(pop)

extern void clear_interrupt_frame(int value, unsigned bytes, void *buffer);
#pragma aux clear_interrupt_frame "memset_" parm [edx] [ebx] [eax] modify exact [eax edx ebx];
extern void point_es_at_data(void);
#pragma aux point_es_at_data = "push ds" "pop es" modify exact [es];
extern void point_fs_at_data(void);
#pragma aux point_fs_at_data = "push ds" "pop fs" modify exact [fs];
extern void simulate_dpmi_interrupt(struct dpmi_registers *registers);
#pragma aux simulate_dpmi_interrupt = "mov ax,300h" "int 31h" parm [edi] modify exact [eax ebx ecx edx];
extern int simulate_dos_interrupt(struct dos_interrupt_registers *registers, int bx, int cx, int di);
#pragma aux simulate_dos_interrupt = "push ds" "push fs" "pop ds" "mov ax,2511h" "int 21h" "pop ds" parm [edx] [ebx] [ecx] [edi] value [eax] modify exact [eax ebx ecx edx];

/* DPMI function 0300h reads the interrupt number in BL and flags in BH. */
extern void load_dpmi_vector(unsigned char vector);
#pragma aux load_dpmi_vector = "" parm [bl] modify exact [];
extern void prepare_dpmi_flags(void);
#pragma aux prepare_dpmi_flags = "xor bh,bh" modify exact [ebx];
extern void no_dpmi_stack_copy(void);
#pragma aux no_dpmi_stack_copy = "xor ecx,ecx" modify exact [ecx];
extern int interrupt_result_in_eax(int result);
#pragma aux interrupt_result_in_eax = "" parm [eax] value [eax] modify exact [];

extern struct dpmi_registers *dpmi_frame_and_segment(struct dpmi_registers *frame, int segment);
#pragma aux dpmi_frame_and_segment = "" parm [edi] [eax] value [edi] modify exact [];
extern unsigned short dpmi_segment_in_ax(void);
#pragma aux dpmi_segment_in_ax = value [ax] modify exact [];
extern int retain_dpmi_base(int base);
#pragma aux retain_dpmi_base = "" parm [eax] value [eax] modify exact [];
int call_graphics_real_mode_interrupt(int interrupt_number, short ax, short bx,
                                      short cx, short dx, int es, short di)
{
    struct dpmi_registers dpmi;
    struct dos_interrupt_registers dos;
    struct dpmi_registers *frame;
    int destination, data_register, base_register;
    int result;

    if (dos_extender_type == 1) {
        clear_interrupt_frame(0, sizeof(dpmi), &dpmi);
        /* Keep the frame writes ordered around the interrupt register loads. */
        *(volatile unsigned long *)&dpmi.eax = ax;
        base_register = retain_dpmi_base(bx);
        load_dpmi_vector(interrupt_number);
        dpmi.ebx = base_register;
        point_es_at_data();
        dpmi.ecx = cx;
        data_register = dx;
        prepare_dpmi_flags();
        dpmi.edx = data_register;
        frame = dpmi_frame_and_segment(&dpmi, es);
        *(volatile unsigned short *)&dpmi.es = dpmi_segment_in_ax();
        destination = di;
        no_dpmi_stack_copy();
        dpmi.edi = destination;
        simulate_dpmi_interrupt(frame);
        return interrupt_result_in_eax(dpmi.eax);
    }
    clear_interrupt_frame(0, sizeof(dos), &dos);
    dos.interrupt_number = interrupt_number;
    point_fs_at_data();
    dos.eax = ax;
    dos.edx = dx;
    dos.es = es;
    result = simulate_dos_interrupt(&dos, bx, cx, di);
    return interrupt_result_in_eax(result);
}
