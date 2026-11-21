/* Grow the Watcom near heap with a separate DPMI or DOS allocation. */
typedef struct NearHeap NearHeap;
struct NearHeap {
    unsigned size;
    NearHeap *previous;
    NearHeap *next;
    unsigned reserved[6];
    unsigned long *last_free_block;
};
enum { LargestFree = 2, Allocations = 3 };
extern long runtime_hook;
extern long memory_limit;
extern unsigned char dos_extender_type;

/* These stages share the caller's frame. The request is passed on the stack;
 * success returns 1 (or 0) via the shared discard/restore epilogue in
 * near_heap_allocate.c. */
void expand_separate_heap(void);
#pragma aux expand_separate_heap aborts;
void expand_return_zero(void);
#pragma aux expand_return_zero aborts;
void expand_check_limit(void);
#pragma aux expand_check_limit aborts;
void expand_allocate_dos(void);
#pragma aux expand_allocate_dos aborts;
void expand_check_block(void);
#pragma aux expand_check_block aborts;

extern void discard_heap_request(void);
#pragma aux discard_heap_request aborts modify exact [];
extern unsigned long round_heap_request(unsigned long *);
#pragma aux round_heap_request parm [eax] value [eax] modify exact [eax];
extern unsigned long *allocate_dpmi_heap(unsigned long);
#pragma aux allocate_dpmi_heap parm [eax] value [eax] modify exact [eax];
extern unsigned long *link_and_initialize_heap(NearHeap *);
#pragma aux link_and_initialize_heap parm [eax] value [eax] modify exact [eax];
extern void free(void *);
#pragma aux free parm [eax] modify exact [eax];
#define HEAP(addr) ((NearHeap *)(addr))
#define TAG(addr) (*(unsigned long *)(addr))

extern void save_expand_registers(void);
#pragma aux save_expand_registers = "push ebx" "push ecx" "push edx" "push esi" "push edi" "push eax" modify exact [];

extern void check_runtime_hook(void);
#pragma aux check_runtime_hook = "cmp dword ptr [runtime_hook],0" "db 75h, 04h" /* marker-rel8 +2,+2 */ modify exact [];

extern void finish_expand_short(void);
#pragma aux finish_expand_short = "db 0ebh, 0e4h" /* marker-rel8 -3,-2 */ modify exact [];

extern void check_memory_limit(void);
#pragma aux check_memory_limit = "cmp dword ptr [memory_limit],0fffffffeh" "db 74h, 0f3h" /* marker-rel8 -4,-3 */ modify exact [];

extern unsigned long stack_in_eax(void);
#pragma aux stack_in_eax = "mov eax,esp" value [eax] modify exact [eax];

extern void require_round_result(void);
#pragma aux require_round_result = "test eax,eax" "db 74h, 0d0h" /* marker-rel8 -6,-5 */ modify exact [];

extern void check_extender_type(void);
#pragma aux check_extender_type = "cmp byte ptr [dos_extender_type],1" "db 75h, 17h" /* marker-rel8 +5,+5 */ modify exact [];

extern void request_in_ax(void);
#pragma aux request_in_ax = "mov eax,[esp]" modify exact [eax];

extern void require_allocation(void);
#pragma aux require_allocation = "test eax,eax" "db 74h, 22h" /* marker-rel8 +4,+4 */ modify exact [];

extern void request_out_ax(void);
#pragma aux request_out_ax = "mov [esp],eax" modify exact [];

extern void go_check_block(void);
#pragma aux go_check_block = "db 0ebh, 1bh" /* marker-rel8 +2,+2 */ modify exact [];

extern void dos_allocate_block(void);
#pragma aux dos_allocate_block = "mov ebx,[esp]" "mov eax,80004800h" "int 21h" "sbb ebx,ebx" "not ebx" "and eax,ebx" \
    "mov ecx,[esp]" "sub ecx,4" "mov edx,eax" "mov [esp],ecx" modify exact [eax ebx ecx edx];

extern void check_block_result(void);
#pragma aux check_block_result = "test edx,edx" "db 74h, 0a9h" /* marker-rel8 -13,-12 */ modify exact [];

extern void request_in_si(void);
#pragma aux request_in_si = "mov esi,[esp]" modify exact [esi];

extern void require_block_bounds(void);
#pragma aux require_block_bounds = "sub eax,4" "cmp eax,esi" "db 77h, 9ch" /* marker-rel8 -16,-15 */ modify exact [];

extern void require_min_size(void);
#pragma aux require_min_size = "cmp eax,38h" "db 72h, 94h" /* marker-rel8 -18,-17 */ modify exact [];

extern void mark_initial_allocated(void);
#pragma aux mark_initial_allocated = "or al,1" modify exact [];

extern void store_block_size(void);
#pragma aux store_block_size = "mov [edx],eax" modify exact [];

extern void store_marked_size(void);
#pragma aux store_marked_size = "mov [ebx],eax" modify exact [];

extern void finish_expand_block(void);
#pragma aux finish_expand_block = "mov eax,1" "jmp discard_heap_request" modify exact [];

extern unsigned long from_ax(void);
#pragma aux from_ax = value [eax] modify exact [];
extern void in_ax(unsigned long);
#pragma aux in_ax = parm [eax] modify exact [];
extern unsigned long from_bx(void);
#pragma aux from_bx = value [ebx] modify exact [];
extern void in_bx(unsigned long);
#pragma aux in_bx = parm [ebx] modify exact [];
extern unsigned long from_dx(void);
#pragma aux from_dx = value [edx] modify exact [];
extern void in_dx(unsigned long);
#pragma aux in_dx = parm [edx] modify exact [];
extern unsigned long from_di(void);
#pragma aux from_di = value [edi] modify exact [];
extern void in_di(unsigned long);
#pragma aux in_di = parm [edi] modify exact [];
extern unsigned char from_al(void);
#pragma aux from_al = value [al] modify exact [];
extern void in_al(unsigned char);
#pragma aux in_al = parm [al] modify exact [];

void expand_separate_heap(void)
{
    save_expand_registers();
    check_runtime_hook();
}

void expand_return_zero(void)
{
    in_ax(0);
    finish_expand_short();
}

void expand_check_limit(void)
{
    check_memory_limit();
    in_ax(stack_in_eax());
    round_heap_request((unsigned long *)from_ax());
    require_round_result();
    check_extender_type();
    request_in_ax();
    allocate_dpmi_heap(from_ax());
    in_bx(from_ax());
    in_dx(from_ax());
    require_allocation();
    in_ax(TAG(from_ax()));
    request_out_ax();
    go_check_block();
}

void expand_allocate_dos(void)
{
    dos_allocate_block();
}

void expand_check_block(void)
{
    check_block_result();
    request_in_ax();
    request_in_si();
    require_block_bounds();
    request_out_ax();
    require_min_size();
    store_block_size();
    in_ax(from_dx());
    link_and_initialize_heap(HEAP(from_ax()));
    in_bx(from_ax());
    in_ax(TAG(from_ax()));
    request_out_ax();
    mark_initial_allocated();
    store_marked_size();
    in_di(HEAP(from_dx())->reserved[Allocations]);
    *(volatile unsigned *)&HEAP(from_dx())->reserved[LargestFree] = ~0U;
    in_di(from_di() + 1UL);
    in_ax(from_bx() + 4UL);
    HEAP(from_dx())->reserved[Allocations] = from_di();
    free((void *)from_ax());
    finish_expand_block();
}
