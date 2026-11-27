/* Allocate a DPMI or DOS backing block for a new near-heap region. */
typedef struct {
    unsigned short handle[2];
    unsigned long dos_selector;
    unsigned long heap_size;
} HeapBacking;
extern unsigned long dos_reserve_bytes;
extern unsigned short dos_reserve_high_word;
extern void release_empty_heaps(void);
#pragma aux release_empty_heaps modify exact [eax];
#define BACKING(addr) ((HeapBacking *)(addr))
#define HEAP_SIZE(addr) (*(unsigned long *)(addr))

/* These entries share the caller's frame. EAX enters with the requested size,
 * and both success paths return the new tag address (base + 8) in EAX. The
 * final stage is also the shared return used by release_empty_heaps. */
void allocate_dpmi_heap(void);
#pragma aux allocate_dpmi_heap aborts;
void allocate_dpmi_result(void);
#pragma aux allocate_dpmi_result aborts;
void allocate_dos_fallback(void);
#pragma aux allocate_dos_fallback aborts;
void allocate_dos_heap(void);
#pragma aux allocate_dos_heap aborts;
void allocate_heap_failure(void);
#pragma aux allocate_heap_failure aborts;
void discard_heap_request(void);
#pragma aux discard_heap_request aborts;
void heap_release_restore(void);
#pragma aux heap_release_restore aborts;

extern void save_heap_request(void);
#pragma aux save_heap_request = "push ebx" "push ecx" "push edx" "push esi" "push edi" "push eax" modify exact [];

extern void request_in_ax(void);
#pragma aux request_in_ax = "mov eax,[esp]" modify exact [eax];

extern void request_in_bx(void);
#pragma aux request_in_bx = "mov ebx,[esp]" modify exact [ebx];

extern void request_in_cx(void);
#pragma aux request_in_cx = "mov ecx,[esp]" modify exact [ecx];

extern void request_in_dx(void);
#pragma aux request_in_dx = "mov edx,[esp]" modify exact [edx];

/* DPMI 0501h allocates BX:CX bytes and returns BX:CX address and SI:DI handle. */
extern void dpmi_allocate(void);
#pragma aux dpmi_allocate = "mov ah,5" "mov al,1" "int 31h" "sbb eax,eax" "inc eax" "db 74h, 10h" /* marker-rel8 0,+1 */ modify exact [eax ebx ecx esi edi];

extern void require_dpmi_address(void);
#pragma aux require_dpmi_address = "test eax,eax" "db 74h, 19h" /* marker-rel8 +2,+3 */ modify exact [];

extern void finish_dpmi_allocation(void);
#pragma aux finish_dpmi_allocation = "jmp discard_heap_request" modify exact [];

extern void require_dos_size(void);
#pragma aux require_dos_size = "cmp dword ptr [esp],10000h" "db 77h, 5ch" /* marker-rel8 +9,+10 */ modify exact [];

extern void dos_allocate(void);
#pragma aux dos_allocate = "mov ah,48h" "int 21h" "rcl eax,1" "ror eax,1" modify exact [eax];

extern void check_reserve_selector(void);
#pragma aux check_reserve_selector = "test eax,eax" "db 7ch, 42h" /* marker-rel8 +7,+8 */ modify exact [];

extern void release_reserve_selector(void);
#pragma aux release_reserve_selector = "push es" "mov es,ax" "mov ah,49h" "int 21h" "rcl eax,1" "ror eax,1" "pop es" modify exact [eax];

extern void check_heap_selector(void);
#pragma aux check_heap_selector = "test esi,esi" "db 7ch, 1eh" /* marker-rel8 +3,+4 */ modify exact [];

/* DPMI 0006h returns the base of the DOS heap selector in CX:DX. */
extern void segment_base(void);
#pragma aux segment_base = "mov ah,0" "mov al,6" "int 31h" modify exact [eax ecx edx];

extern void finish_dos_allocation(void);
#pragma aux finish_dos_allocation = "db 0ebh, 02h" /* marker-rel8 0,+1 */ modify exact [];

extern void pop_heap_request(void);
#pragma aux pop_heap_request = "add esp,4" modify exact [];

extern void restore_heap_registers(void);
#pragma aux restore_heap_registers = "pop edi" "pop esi" "pop edx" "pop ecx" "pop ebx" "ret" modify exact [];

extern unsigned long from_ax(void);
#pragma aux from_ax = value [eax] modify exact [];
extern void in_ax(unsigned long);
#pragma aux in_ax = parm [eax] modify exact [];
extern unsigned long from_bx(void);
#pragma aux from_bx = value [ebx] modify exact [];
extern void in_bx(unsigned long);
#pragma aux in_bx = parm [ebx] modify exact [];
extern unsigned long from_cx(void);
#pragma aux from_cx = value [ecx] modify exact [];
extern void in_cx(unsigned long);
#pragma aux in_cx = parm [ecx] modify exact [];
extern unsigned long from_dx(void);
#pragma aux from_dx = value [edx] modify exact [];
extern void in_dx(unsigned long);
#pragma aux in_dx = parm [edx] modify exact [];
extern unsigned long from_si(void);
#pragma aux from_si = value [esi] modify exact [];
extern void in_si(unsigned long);
#pragma aux in_si = parm [esi] modify exact [];
extern unsigned char from_bl(void);
#pragma aux from_bl = value [bl] modify exact [];
extern void in_bl(unsigned char);
#pragma aux in_bl = parm [bl] modify exact [];
extern unsigned short from_bx_word(void);
#pragma aux from_bx_word = value [bx] modify exact [];
extern void in_ax_word(unsigned short);
#pragma aux in_ax_word = parm [ax] modify exact [];
extern unsigned short from_cx_word(void);
#pragma aux from_cx_word = value [cx] modify exact [];
extern unsigned short from_dx_word(void);
#pragma aux from_dx_word = value [dx] modify exact [];
extern unsigned short from_di_word(void);
#pragma aux from_di_word = value [di] modify exact [];
extern unsigned short from_si_word(void);
#pragma aux from_si_word = value [si] modify exact [];

void allocate_dpmi_heap(void)
{
    save_heap_request();
    release_empty_heaps();
    request_in_ax();
    in_ax(from_ax() >> 16);
    request_in_cx();
    in_bx(from_ax());
    dpmi_allocate();
    in_ax_word(from_bx_word());
    in_ax(from_ax() << 16);
    in_ax_word(from_cx_word());
    BACKING(from_ax())->handle[0] = from_di_word();
    BACKING(from_ax())->handle[1] = from_si_word();
}

void allocate_dpmi_result(void)
{
    require_dpmi_address();
    request_in_bx();
    in_dx(from_ax() + 8UL);
    in_bx(from_bx() - 8UL);
    HEAP_SIZE(from_dx()) = from_bx();
    BACKING(from_ax())->dos_selector = 0;
    in_ax(from_dx());
    finish_dpmi_allocation();
}

void allocate_dos_fallback(void)
{
    if (dos_reserve_high_word & 0xfff0)
        dos_reserve_bytes = 0xfffffUL;
}

void allocate_dos_heap(void)
{
    require_dos_size();
    in_bx(dos_reserve_bytes);
    in_bx(from_bx() >> 4);
    in_bl(from_bl() | 1U);
    dos_allocate();
    in_dx(from_ax());
    check_reserve_selector();
    request_in_bx();
    in_bx(from_bx() >> 4);
    dos_allocate();
    in_si(from_ax());
    in_bx(from_ax());
    in_ax(from_dx());
    release_reserve_selector();
    check_heap_selector();
    segment_base();
    in_ax(from_cx());
    in_ax(from_ax() << 16);
    in_ax_word(from_dx_word());
    in_ax(from_ax() + 8UL);
    request_in_dx();
    *(volatile unsigned long *)(from_ax() - 4UL) = from_si();
    in_dx(from_dx() - 8UL);
    HEAP_SIZE(from_ax()) = from_dx();
    finish_dos_allocation();
}

void allocate_heap_failure(void)
{
    in_ax(0);
}

void discard_heap_request(void)
{
    pop_heap_request();
}

void heap_release_restore(void)
{
    restore_heap_registers();
}
