extern unsigned char dos_extender_type;
/* The DOS call uses an internal ABI with live registers across the transfer. */
extern void save_dta_registers(void);
#pragma aux save_dta_registers = "push eax" "push ebx" "push ecx" "push esi" "push edi" modify exact [];
extern unsigned restore_dta_registers(void);
#pragma aux restore_dta_registers = "pop edi" "pop esi" "pop ecx" "pop ebx" "pop eax" value [eax] modify exact [eax ebx ecx esi edi];
extern void get_dos_dta(void);
#pragma aux get_dos_dta = "mov ah,2fh" "int 21h" modify exact [eax ebx ecx esi edi];
enum { DOS4G_EXTENDER = 9, DOS_DTA_SIZE = 43 };

extern void copy_dta_bytes(void);
#pragma aux copy_dta_bytes = "rep movsb" modify exact [ecx esi edi];
extern unsigned get_ebx(void);
#pragma aux get_ebx = value [ebx] modify exact [];
extern unsigned put_ecx(unsigned);
#pragma aux put_ecx = parm [ecx] value [ecx] modify exact [];
extern unsigned get_esi(void);
#pragma aux get_esi = value [esi] modify exact [];
extern unsigned put_esi(unsigned);
#pragma aux put_esi = parm [esi] value [esi] modify exact [];
extern unsigned get_edi(void);
#pragma aux get_edi = value [edi] modify exact [];
extern unsigned put_edi(unsigned);
#pragma aux put_edi = parm [edi] value [edi] modify exact [];

/* Keep the pointer moves ahead of the size load in Watcom 10.5. */
extern void keep_copy_pointers(unsigned, unsigned);
#pragma aux keep_copy_pointers = parm [esi] [edi] modify exact [ecx];

unsigned copy_dta_to_caller(unsigned status, void *record);
#pragma aux copy_dta_to_caller modify exact [eax ebx ecx edx esi edi];
unsigned copy_dta_to_caller(unsigned status, void *record)
{
    if (dos_extender_type == DOS4G_EXTENDER) {
        save_dta_registers();
        get_dos_dta();
        put_esi(get_ebx());
        put_edi((unsigned)record);
        keep_copy_pointers(get_esi(), get_edi());
        put_ecx(DOS_DTA_SIZE);
        copy_dta_bytes();
        return restore_dta_registers();
    }
    return status;
}

unsigned copy_caller_to_dta(unsigned status, void *record);
#pragma aux copy_caller_to_dta modify exact [eax ebx ecx edx esi edi];
unsigned copy_caller_to_dta(unsigned status, void *record)
{
    if (dos_extender_type == DOS4G_EXTENDER) {
        save_dta_registers();
        get_dos_dta();
        put_edi(get_ebx());
        put_esi((unsigned)record);
        keep_copy_pointers(get_esi(), get_edi());
        put_ecx(DOS_DTA_SIZE);
        copy_dta_bytes();
        return restore_dta_registers();
    }
    return status;
}
