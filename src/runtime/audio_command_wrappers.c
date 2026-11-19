/* HMI driver command wrappers that call the mapped driver far entry. */
void driver_command_5(void);
#pragma aux driver_command_5 aborts;
void driver_command_0(void);
#pragma aux driver_command_0 aborts;

extern void save_registers(void);
#pragma aux save_registers = "push ebp" "db 8bh, 0ech" "push esi" "push edi" "push ebx" \
    "push ecx" "push fs" "push gs" "push es" modify exact [eax ebx ecx edx esi edi];

extern void command_5(void);
#pragma aux command_5 = "mov eax,5" modify exact [eax];

extern void command_0(void);
#pragma aux command_0 = "mov eax,0" modify exact [eax];

/* The driver record is the third stack argument; its entry is the first. */
extern void load_far_pointer(void);
#pragma aux load_far_pointer = "lfs edi,[ebp+10h]" modify exact [edi];

extern void call_driver(void);
#pragma aux call_driver = "call far [ebp+8]" modify exact [];

extern void restore_registers(void);
#pragma aux restore_registers = "pop es" "pop gs" "pop fs" "pop ecx" "pop ebx" \
    "pop edi" "pop esi" "pop ebp" "ret" modify exact [];

void driver_command_5(void)
{
    save_registers();
    command_5();
    load_far_pointer();
    call_driver();
    restore_registers();
}

void driver_command_0(void)
{
    save_registers();
    command_0();
    load_far_pointer();
    call_driver();
    restore_registers();
}
