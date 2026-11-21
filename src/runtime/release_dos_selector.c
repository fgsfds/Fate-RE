/* Release the DOS selector after loading the segment registers from DS. */
void release_dos_selector(void);
#pragma aux release_dos_selector aborts;

extern void set_segments(void);
#pragma aux set_segments = "mov ax,ds" "mov gs,ax" "mov fs,ax" "mov es,ax" modify exact [eax];

extern void save_registers(void);
#pragma aux save_registers = "push ebp" "db 8bh, 0ech" "push esi" "push edi" "push ebx" \
    "push ecx" "push fs" "push gs" "push es" modify exact [eax ebx ecx edx esi edi];

extern void dpmi_101(void);
#pragma aux dpmi_101 = "mov ax,101h" "mov dx,word ptr [ebp+8]" "int 31h" modify exact [eax edx];

extern void mov_ax_0(void);
#pragma aux mov_ax_0 = "mov ax,0" modify exact [eax];

extern void restore_registers(void);
#pragma aux restore_registers = "pop es" "pop gs" "pop fs" "pop ecx" "pop ebx" \
    "pop edi" "pop esi" "pop ebp" "ret" modify exact [];

void release_dos_selector(void)
{
    set_segments();
    save_registers();
    dpmi_101();
    mov_ax_0();
    restore_registers();
}
