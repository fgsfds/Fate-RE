typedef struct NearHeap NearHeap;
struct NearHeap {
    unsigned size;
    NearHeap *previous;
    NearHeap *next;
    unsigned reserved[6];
    unsigned long *last_free_block;
};
/* These NearHeap bookkeeping slots count allocations and cache the largest free block. */
enum { LargestFree = 2, Allocations = 3 };
typedef struct {
    unsigned short handle[2];
    unsigned long dos_selector;
} HeapBacking;
extern NearHeap *near_heap_head;
extern void release_empty_heaps(void);
#pragma aux release_empty_heaps modify exact [eax];
extern void unlink_near_heap(NearHeap *);
#pragma aux unlink_near_heap parm [eax] modify exact [eax];
extern unsigned long *link_and_initialize_heap(NearHeap *);
#pragma aux link_and_initialize_heap parm [eax] value [eax] modify exact [eax];
extern void free(void *);
#pragma aux free parm [eax] modify exact [eax];
#define HEAP(addr) ((NearHeap *)(addr))
#define TAG(addr) (*(unsigned long *)(addr))
#define BYTE(addr) (*(unsigned char *)(addr))
#define BACKING(addr) ((HeapBacking *)(addr))
/* These entries share the original frame. EAX enters with the old block
 * tag address and EDX with the requested size; the final stage restores
 * the frame and returns the new tag address (or zero) in EAX. */
void resize_dpmi_heap(void);
#pragma aux resize_dpmi_heap aborts;
void resize_heap_target(void);
#pragma aux resize_heap_target aborts;
void resize_heap_result(void);
#pragma aux resize_heap_result aborts;
void resize_use_whole_block(void);
#pragma aux resize_use_whole_block aborts;
void resize_return_block(void);
#pragma aux resize_return_block aborts;
void resize_next_heap(void);
#pragma aux resize_next_heap aborts;
void resize_check_heap(void);
#pragma aux resize_check_heap aborts;
void resize_return_zero(void);
#pragma aux resize_return_zero aborts;
void resize_restore(void);
#pragma aux resize_restore aborts;

/* The saved request lives in EBP. Watcom reserves EBP and rejects it
 * in clobber lists, so its writes stay in fixed-frame auxiliaries. */
extern void save_resize_registers(void);
#pragma aux save_resize_registers = "push ebx" "push ecx" "push esi" "push edi" "push ebp" "mov ebx,eax" "mov ebp,edx" modify exact [ebx];

extern void begin_heap_search(void);
#pragma aux begin_heap_search = "jmp resize_check_heap" modify exact [];

extern void check_block_address(void);
#pragma aux check_block_address = "cmp edx,ebx" "ja resize_return_zero" modify exact [];

extern void check_block_start(void);
#pragma aux check_block_start = "cmp eax,ebx" "jne resize_next_heap" modify exact [];

extern void check_single_allocation(void);
#pragma aux check_single_allocation = "cmp dword ptr [edx+18h],1" "jne resize_next_heap" modify exact [];

extern void backing_in_eax(void);
#pragma aux backing_in_eax = "lea eax,[edx-8]" modify exact [eax];

/* Do not move the request into ECX before the backing-kind guard. */
extern void require_dpmi_backing(void);
#pragma aux require_dpmi_backing = "cmp dword ptr [eax+4],0" "jne resize_return_zero" modify exact [ecx];

extern void round_down_to_page(void);
#pragma aux round_down_to_page = "and dh,0f0h" "xor dl,dl" modify exact [edx];

/* DPMI 0503h returns a new address in BX:CX and a handle in SI:DI. */
extern void dpmi_resize(void);
#pragma aux dpmi_resize = "mov ah,5" "mov al,3" "int 31h" "sbb eax,eax" "inc eax" "db 74h, 10h" /* marker-rel8 0,+1 */ modify exact [eax ebx ecx esi edi];

extern void require_resize_result(void);
#pragma aux require_resize_result = "test eax,eax" "db 74h, 6bh" /* marker-rel8 +6,+7 */ modify exact [];

extern void round_requested_size(void);
#pragma aux round_requested_size = "and ebp,0fffffffeh" modify exact [];

extern void advance_requested_size(void);
#pragma aux advance_requested_size = "inc ebp" modify exact [];

extern void check_free_remainder(void);
#pragma aux check_free_remainder = "cmp edx,0ch" "db 72h, 25h" /* marker-rel8 +1,+2 */ modify exact [];

extern void finish_split_block(void);
#pragma aux finish_split_block = "db 0ebh, 07h" /* marker-rel8 0,+1 */ modify exact [];

extern void finish_resize(void);
#pragma aux finish_resize = "db 0ebh, 0dh" /* marker-rel8 +1,+2 */ modify exact [];

extern void loop_heap_search(void);
#pragma aux loop_heap_search = "test edx,edx" "jne resize_heap_target" modify exact [];

extern void restore_resize_registers(void);
#pragma aux restore_resize_registers = "pop ebp" "pop edi" "pop esi" "pop ecx" "pop ebx" "ret" modify exact [];

extern unsigned long from_ax(void);
#pragma aux from_ax =  value [eax] modify exact [];

extern void in_ax(unsigned long);
#pragma aux in_ax =  parm [eax] modify exact [];

extern unsigned long from_bx(void);
#pragma aux from_bx =  value [ebx] modify exact [];

extern void in_bx(unsigned long);
#pragma aux in_bx =  parm [ebx] modify exact [];

extern unsigned long from_cx(void);
#pragma aux from_cx =  value [ecx] modify exact [];

extern void in_cx(unsigned long);
#pragma aux in_cx =  parm [ecx] modify exact [];

extern unsigned long from_dx(void);
#pragma aux from_dx =  value [edx] modify exact [];

extern void in_dx(unsigned long);
#pragma aux in_dx =  parm [edx] modify exact [];

extern unsigned long from_bp(void);
#pragma aux from_bp =  value [ebp] modify exact [];

extern unsigned long from_si(void);
#pragma aux from_si =  value [esi] modify exact [];

extern unsigned long from_di(void);
#pragma aux from_di =  value [edi] modify exact [];

extern void in_di(unsigned long);
#pragma aux in_di =  parm [edi] modify exact [];

extern unsigned char from_al(void);
#pragma aux from_al =  value [al] modify exact [];

extern void in_al(unsigned char);
#pragma aux in_al =  parm [al] modify exact [];

extern unsigned char from_ah(void);
#pragma aux from_ah =  value [ah] modify exact [];

extern void in_ah(unsigned char);
#pragma aux in_ah =  parm [ah] modify exact [];

extern unsigned char from_dl(void);
#pragma aux from_dl =  value [dl] modify exact [];

extern void in_dl(unsigned char);
#pragma aux in_dl =  parm [dl] modify exact [];

extern void in_ax_word(unsigned short);
#pragma aux in_ax_word =  parm [ax] modify exact [];

extern unsigned short from_bx_word(void);
#pragma aux from_bx_word =  value [bx] modify exact [];

extern unsigned short from_cx_word(void);
#pragma aux from_cx_word =  value [cx] modify exact [];

extern unsigned short from_si_word(void);
#pragma aux from_si_word =  value [si] modify exact [];

extern void in_si_word(unsigned short);
#pragma aux in_si_word =  parm [si] modify exact [];

extern unsigned short from_di_word(void);
#pragma aux from_di_word =  value [di] modify exact [];

extern void in_di_word(unsigned short);
#pragma aux in_di_word =  parm [di] modify exact [];

void resize_dpmi_heap(void)
{
    save_resize_registers();
    release_empty_heaps();
    in_dx((unsigned long)near_heap_head);
    begin_heap_search();
}

void resize_heap_target(void)
{
    check_block_address();
    in_ax(from_dx() + 44UL);
    check_block_start();
    check_single_allocation();
    unlink_near_heap(HEAP(from_dx()));
    backing_in_eax();
    require_dpmi_backing();
    /* Add the requested growth to the backing size, then round up to a page. */
    in_cx(from_bp());
    in_bx(TAG(from_bx()));
    in_dx(HEAP(from_dx())->size);
    in_bx(from_bx() - 4UL);
    in_dx(from_dx() + 12UL);
    in_cx(from_cx() - from_bx());
    in_dx(from_dx() + from_cx());
    in_dx(from_dx() + 4095UL);
    round_down_to_page();
    in_bx(from_dx());
    in_cx(from_dx());
    in_bx(from_bx() >> 16);
    in_di_word(BACKING(from_ax())->handle[0]);
    in_si_word(BACKING(from_ax())->handle[1]);
    dpmi_resize();
    in_ax_word(from_bx_word());
    in_ax(from_ax() << 16);
    in_ax_word(from_cx_word());
    BACKING(from_ax())->handle[0] = from_di_word();
    BACKING(from_ax())->handle[1] = from_si_word();
}

extern void position_tag_in_cx(unsigned long, unsigned long);
#pragma aux position_tag_in_cx = parm [ecx] [edx] modify exact [];
extern void retain_tag_in_si(unsigned long, unsigned long);
#pragma aux retain_tag_in_si = parm [esi] [edx] modify exact [];
extern void free_pointer_in_ax(unsigned long, unsigned long);
#pragma aux free_pointer_in_ax = parm [eax] [edi] modify exact [];

void resize_heap_result(void)
{
    require_resize_result();
    in_bx(from_ax() + 8UL);
    in_dx(from_dx() - 12UL);
    advance_requested_size();
    BACKING(from_ax())->dos_selector = 0;
    in_ax(from_bx());
    HEAP(from_bx())->size = from_dx();
    link_and_initialize_heap(HEAP(from_ax()));
    HEAP(from_bx())->reserved[Allocations] = 1;
    round_requested_size();
    /* Finish loading the free tag before positioning the split pointers. */
    in_dx(*(volatile unsigned long *)from_ax());
    position_tag_in_cx(from_ax(), from_dx());
    in_dx(from_dx() - from_bp());
    retain_tag_in_si(from_ax(), from_dx());
    check_free_remainder();
    /* Mark both tags allocated before releasing the tail through free. */
    in_ax(from_bp());
    in_al(from_al() | 1U);
    TAG(from_cx()) = from_ax();
    in_cx(from_cx() + from_bp());
    in_dl(from_dl() | 1U);
    TAG(from_cx()) = from_dx();
    in_di(HEAP(from_bx())->reserved[Allocations]);
    *(volatile unsigned *)&HEAP(from_bx())->reserved[LargestFree] = ~0U;
    in_di(from_di() + 1UL);
    free_pointer_in_ax(from_cx() + 4UL, from_di());
    HEAP(from_bx())->reserved[Allocations] = from_di();
    free((void *)from_ax());
    finish_split_block();
}

void resize_use_whole_block(void)
{
    in_ah(BYTE(from_ax()));
    in_ah(from_ah() | 1U);
    BYTE(from_cx()) = from_ah();
}

void resize_return_block(void)
{
    in_ax(from_si());
    finish_resize();
}

void resize_next_heap(void)
{
    in_dx((unsigned long)HEAP(from_dx())->next);
}

void resize_check_heap(void)
{
    loop_heap_search();
}

void resize_return_zero(void)
{
    in_ax(0);
}

void resize_restore(void)
{
    restore_resize_registers();
}
