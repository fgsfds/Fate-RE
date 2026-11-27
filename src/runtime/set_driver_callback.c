/* Store the driver callback offset and selector into the callback table. */
void set_driver_callback(void);
#pragma aux set_driver_callback aborts;

extern void save_registers(void);
#pragma aux save_registers = "push ebp" "db 8bh, 0ech" "push esi" "push edi" "push ebx" \
    "push ecx" "push fs" "push gs" "push es" modify exact [eax ebx ecx edx esi edi];

extern void restore_registers(void);
#pragma aux restore_registers = "pop es" "pop gs" "pop fs" "pop ecx" "pop ebx" \
    "pop edi" "pop esi" "pop ebp" "ret" modify exact [];

extern unsigned long driver_callbacks;

extern void les_esi(void);
#pragma aux les_esi = "les esi,driver_callbacks" modify exact [esi];

extern void load_eax8(void);
#pragma aux load_eax8 = "mov eax,[ebp+8]" modify exact [eax];

extern void mov_ebx_eax(void);
#pragma aux mov_ebx_eax = "db 8bh, 0d8h" modify exact [ebx];

extern void shl_eax1(void);
#pragma aux shl_eax1 = "shl eax,1" modify exact [eax];

extern void shl_ebx2(void);
#pragma aux shl_ebx2 = "shl ebx,2" modify exact [ebx];

extern void add_ebx_eax(void);
#pragma aux add_ebx_eax = "db 03h, 0d8h" modify exact [ebx];

extern void load_eaxc(void);
#pragma aux load_eaxc = "mov eax,[ebp+0ch]" modify exact [eax];

extern void store_offset(void);
#pragma aux store_offset = "db 26h" "mov [esi+ebx],eax" modify exact [];

extern void store_selector(void);
#pragma aux store_selector = "db 66h,26h,8ch,5ch,1eh,04h" modify exact [];

void set_driver_callback(void)
{
    save_registers();
    les_esi();
    load_eax8();
    mov_ebx_eax();
    shl_eax1();
    shl_ebx2();
    add_ebx_eax();
    load_eaxc();
    store_offset();
    store_selector();
    restore_registers();
}
