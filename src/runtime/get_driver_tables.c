/* Read the driver record/callback tables and selectors after the far call. */
void get_driver_tables(void);
#pragma aux get_driver_tables aborts;

extern void save_registers(void);
#pragma aux save_registers = "push ebp" "db 8bh, 0ech" "push esi" "push edi" "push ebx" \
    "push ecx" "push fs" "push gs" "push es" modify exact [eax ebx ecx edx esi edi];

extern void restore_registers(void);
#pragma aux restore_registers = "pop es" "pop gs" "pop fs" "pop ecx" "pop ebx" \
    "pop edi" "pop esi" "pop ebp" "ret" modify exact [];

extern void call_driver(void);
#pragma aux call_driver = "call far [ebp+8]" modify exact [];

extern void lfs_edi_10(void);
#pragma aux lfs_edi_10 = "lfs edi,[ebp+10h]" modify exact [edi];

extern void cmd4(void);
#pragma aux cmd4 = "mov eax,4" modify exact [eax];

extern unsigned long driver_records;
extern unsigned long driver_callbacks;
extern unsigned short driver_records_selector;
extern unsigned short driver_callbacks_selector;

extern void store_records(void);
#pragma aux store_records = "mov dword ptr driver_records, esi" modify exact [];
extern void store_callbacks(void);
#pragma aux store_callbacks = "mov dword ptr driver_callbacks, edi" modify exact [];
extern void load_ax(void);
#pragma aux load_ax = "mov ax,word ptr [ebp+14h]" modify exact [eax];
extern void store_records_selector(void);
#pragma aux store_records_selector = "mov word ptr driver_records_selector, ax" modify exact [];
extern void store_callbacks_selector(void);
#pragma aux store_callbacks_selector = "mov word ptr driver_callbacks_selector, ax" modify exact [];

void get_driver_tables(void)
{
    save_registers();
    lfs_edi_10();
    cmd4();
    call_driver();
    store_records();
    store_callbacks();
    load_ax();
    store_records_selector();
    store_callbacks_selector();
    restore_registers();
}
