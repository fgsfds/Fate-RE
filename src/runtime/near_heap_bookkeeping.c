typedef struct NearHeap NearHeap;
struct NearHeap {
    unsigned size;
    NearHeap *previous;
    NearHeap *next;
    unsigned reserved[6];
    unsigned long *last_free_block;
};
extern NearHeap *near_heap_head, *near_heap_rover;

extern NearHeap *heap_in_eax(NearHeap *);
#pragma aux heap_in_eax = parm [eax] value [eax] modify exact [];
extern NearHeap *heap_in_edx(NearHeap *);
#pragma aux heap_in_edx = parm [edx] value [edx] modify exact [];
extern NearHeap *heap_in_ebx(NearHeap *);
#pragma aux heap_in_ebx = parm [ebx] value [ebx] modify exact [];

/* Retain both neighbors in the original registers across the first link update. */
extern NearHeap *current_previous(void);
#pragma aux current_previous = value [edx] modify exact [];
extern NearHeap *current_next(void);
#pragma aux current_next = value [eax] modify exact [];
void unlink_near_heap(NearHeap *);
#pragma aux unlink_near_heap modify exact [eax];
void unlink_near_heap(NearHeap *heap)
{
    NearHeap *rover = heap_in_edx(near_heap_rover);
    NearHeap *head;
    NearHeap *previous, *next;

    if (heap == rover)
        near_heap_rover = heap_in_edx(rover->next);
    head = heap_in_ebx(near_heap_head);
    if (heap == head)
        near_heap_head = heap_in_edx(head->next);
    previous = heap_in_edx(heap->previous);
    next = heap_in_eax(heap->next);
    if (previous)
        previous->next = next;
    if (current_next())
        current_next()->previous = current_previous();
}

extern volatile unsigned long memory_limit;
extern const unsigned char dos_extender_type, extender_flags;

extern unsigned long *block_in_edx(unsigned long *);
#pragma aux block_in_edx = parm [edx] value [edx] modify exact [];
extern unsigned long end_in_ebx(unsigned long);
#pragma aux end_in_ebx = parm [ebx] value [ebx] modify exact [];
extern unsigned char extender_in_ah(unsigned char);
#pragma aux extender_in_ah = parm [ah] value [ah] modify exact [];
extern unsigned long data_segment_limit(void);
/* Read the original 32-bit data selector and query its segment limit. */
#pragma aux data_segment_limit = "xor eax,eax" 0x8c 0xd8 "lsl eax,eax" value [eax] modify exact [eax];

extern unsigned long *current_block(void);
#pragma aux current_block = value [edx] modify exact [];

unsigned long free_space_at_break(void)
{
    NearHeap *head = heap_in_edx(near_heap_head);
    if (head) {
        unsigned long *block = block_in_edx(head->last_free_block);
        unsigned long end = end_in_ebx(*block);
        unsigned char extender;
        end = end_in_ebx(end + (unsigned long)block);
        extender = extender_in_ah(dos_extender_type);
        end = end_in_ebx(end + 4);
        if (extender >= 2 && extender <= 8 && extender_flags == 0)
            memory_limit = data_segment_limit() + 1;
        if (end == memory_limit)
            return *current_block();
    }
    return 0;
}

extern unsigned long size_in_eax(unsigned long);
#pragma aux size_in_eax = parm [eax] value [eax] modify exact [];
extern unsigned long *payload_in_edx(unsigned long *);
#pragma aux payload_in_edx = parm [edx] value [edx] modify exact [];
extern unsigned long *sentinel_in_ebx(unsigned long *);
#pragma aux sentinel_in_ebx = parm [ebx] value [ebx] modify exact [];

unsigned long *link_and_initialize_heap(NearHeap *);
#pragma aux link_and_initialize_heap modify exact [eax];
unsigned long *link_and_initialize_heap(NearHeap *heap)
{
    NearHeap *node = heap_in_edx(heap);
    NearHeap *next = heap_in_eax(near_heap_head);
    NearHeap *previous = heap_in_ebx(0);
    unsigned long *sentinel, *payload;
    unsigned long bytes;

    /* Keep the region list sorted by its flat DOS address. */
    goto check_node;
    do {
        if ((unsigned long)node < (unsigned long)next)
            break;
        previous = heap_in_ebx(next);
        next = heap_in_eax(next->next);
check_node:
        ;
    } while (next);

    node->previous = previous;
    node->next = next;
    if (previous)
        previous->next = node;
    else
        near_heap_head = node;
    if (current_next())
        current_next()->previous = current_previous();

    /* Initialize the free-list header and mark the end of the region. */
    sentinel = sentinel_in_ebx((unsigned long *)((char *)current_previous() + 32));
    bytes = size_in_eax(current_previous()->size);
    payload = payload_in_edx((unsigned long *)((char *)current_previous() + 44));
    ((volatile unsigned long *)payload)[-3] = 0;
    ((volatile unsigned long *)payload)[-7] = 0;
    ((volatile unsigned long *)payload)[-5] = 0;
    ((volatile unsigned long *)payload)[-4] = 0;
    ((unsigned long *volatile *)payload)[-2] = sentinel;
    ((unsigned long *volatile *)payload)[-1] = sentinel;
    bytes = size_in_eax(bytes - 44);
    ((unsigned long *volatile *)payload)[-8] = sentinel;
    payload[0] = bytes;
    *(unsigned long *)((char *)payload + bytes) = ~0UL;
    return payload;
}
