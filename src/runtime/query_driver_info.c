/* Query the DPMI free memory info and the Windows driver version. */
void query_dpmi_memory(void);
#pragma aux query_dpmi_memory aborts;
void query_windows_version(void);
#pragma aux query_windows_version aborts;

extern void save_registers(void);
#pragma aux save_registers = "push ebp" "db 8bh, 0ech" "push esi" "push edi" "push ebx" \
    "push ecx" "push fs" "push gs" "push es" modify exact [eax ebx ecx edx esi edi];

extern void restore_registers(void);
#pragma aux restore_registers = "pop es" "pop gs" "pop fs" "pop ecx" "pop ebx" \
    "pop edi" "pop esi" "pop ebp" "ret" modify exact [];

extern void int_2f(void);
#pragma aux int_2f = "mov ax,1600h" "int 2fh" modify exact [eax];

extern void dpmi_500(void);
#pragma aux dpmi_500 = "mov ax,500h" "int 31h" modify exact [eax];

extern void push_ds_pop_es(void);
#pragma aux push_ds_pop_es = "push ds" "pop es" modify exact [];

extern unsigned long dpmi_memory_info;

extern void mov_edi_dpmi(void);
#pragma aux mov_edi_dpmi = "mov edi,offset dpmi_memory_info" modify exact [edi];

extern void int_31(void);
#pragma aux int_31 = "int 31h" modify exact [];

extern void load_dpmi(void);
#pragma aux load_dpmi = "mov eax,dword ptr dpmi_memory_info" modify exact [eax];

void query_dpmi_memory(void)
{
    save_registers();
    dpmi_500();
    push_ds_pop_es();
    mov_edi_dpmi();
    int_31();
    load_dpmi();
    restore_registers();
}

void query_windows_version(void)
{
    save_registers();
    int_2f();
    restore_registers();
}
