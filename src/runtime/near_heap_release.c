typedef struct NearHeap NearHeap;
struct NearHeap {
    unsigned size;
    NearHeap *previous;
    NearHeap *next;
    unsigned reserved[6];
    unsigned long *last_free_block;
};
/* DOS and DPMI allocators reserve this eight-byte header before NearHeap. */
typedef struct {
    union { unsigned long packed; unsigned short words[2]; } handle;
    unsigned long dos_selector;
} HeapBacking;
extern NearHeap *near_heap_head;
/* The allocator shares this five-register pop/return sequence. */
extern void heap_release_restore(void);
#pragma aux heap_release_restore aborts modify exact [];
extern void unlink_near_heap(NearHeap *);
#pragma aux unlink_near_heap parm [eax] modify exact [eax];

extern void save_heap_registers(void);
#pragma aux save_heap_registers = "push ebx" "push ecx" "push edx" "push esi" "push edi" modify exact [];
extern void return_if_no_heap(void);
#pragma aux return_if_no_heap = "test edx,edx" "je heap_release_restore" modify exact [];
extern void skip_nonempty_heap(void);
#pragma aux skip_nonempty_heap = "cmp eax,ebx" "db 75h, 38h" /* marker-rel8 +4,+5 */ modify exact [];
extern void select_backing_kind(void);
#pragma aux select_backing_kind = "test ecx,ecx" "db 75h, 12h" /* marker-rel8 +1,+2 */ modify exact [];

/* Keep the interrupt and hardware carry/selector handling at the ABI boundary. */
extern void dpmi_release(void);
#pragma aux dpmi_release = "mov ah,5" "mov al,2" "int 31h" "db 0ebh, 0c2h" /* marker-rel8 -4,-4 */ modify exact [eax];
extern void dos_release(void);
#pragma aux dos_release = "push es" "mov es,ax" "mov ah,49h" "int 21h" \
    "rcl eax,1" "ror eax,1" "pop es" "db 0ebh, 0b2h" /* marker-rel8 -5,-5 */ modify exact [eax];
extern void next_heap_iteration(void);
#pragma aux next_heap_iteration = "db 0ebh, 0adh" /* marker-rel8 -6,-6 */ modify exact [];
extern void in_heap_edx(NearHeap *);
#pragma aux in_heap_edx = parm [edx] modify exact [];
extern NearHeap *heap_edx(void);
#pragma aux heap_edx = value [edx] modify exact [];
extern void in_heap_eax(NearHeap *);
#pragma aux in_heap_eax = parm [eax] modify exact [];
extern NearHeap *heap_eax(void);
#pragma aux heap_eax = value [eax] modify exact [];
extern void in_heap_ecx(NearHeap *);
#pragma aux in_heap_ecx = parm [ecx] modify exact [];
extern NearHeap *heap_ecx(void);
#pragma aux heap_ecx = value [ecx] modify exact [];
extern void in_eax(unsigned long);
#pragma aux in_eax = parm [eax] modify exact [];
extern unsigned long from_eax(void);
#pragma aux from_eax = value [eax] modify exact [];
extern void in_ecx(unsigned long);
#pragma aux in_ecx = parm [ecx] modify exact [];
extern unsigned long from_ecx(void);
#pragma aux from_ecx = value [ecx] modify exact [];
extern void in_ebx(unsigned long);
#pragma aux in_ebx = parm [ebx] modify exact [];
extern void select_heap_backing(void);
#pragma aux select_heap_backing = "lea ebx,[edx-8]" modify exact [ebx];
extern const HeapBacking *heap_backing(void);
#pragma aux heap_backing = value [ebx] modify exact [];
extern void in_tag_ptr(const unsigned long *);
#pragma aux in_tag_ptr = parm [eax] modify exact [];
extern const unsigned long *tag_ptr(void);
#pragma aux tag_ptr = value [eax] modify exact [];
extern void in_di_word(unsigned short);
#pragma aux in_di_word = parm [di] modify exact [];
extern void in_esi(unsigned long);
#pragma aux in_esi = parm [esi] modify exact [];

void release_empty_heaps(void);
#pragma aux release_empty_heaps aborts modify exact [eax];
void release_empty_heaps(void)
{
    save_heap_registers();
    in_heap_edx(near_heap_head);
    return_if_no_heap();
    /* A single free block plus the heap header accounts for the region. */
    in_tag_ptr(heap_edx()->last_free_block);
    in_eax(*tag_ptr());
    in_ebx(heap_edx()->size);
    in_eax(from_eax() + 44UL);
    skip_nonempty_heap();
    select_heap_backing();
    in_heap_eax(heap_edx());
    in_heap_ecx(heap_edx()->next);
    unlink_near_heap(heap_eax());
    in_heap_edx(heap_ecx());
    in_ecx(heap_backing()->dos_selector);
    select_backing_kind();
    in_eax(heap_backing()->handle.packed);
    in_eax(from_eax() >> 16);
    in_di_word(heap_backing()->handle.words[0]);
    in_esi(from_eax());
    dpmi_release();
    in_eax(from_ecx());
    dos_release();
    in_heap_edx(heap_edx()->next);
    next_heap_iteration();
}
